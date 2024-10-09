import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/theme_switcher.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/jobMonitoringSystem/job_monitoring_screen.dart';
import 'package:green/screens/processMonitoringScreen/process_monitoring_system.dart';
import 'package:green/screens/userManagement/user_management.dart';
import 'package:green/service/language_service.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/listings/account_list.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../service/shared_preference_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool showCorporateManagementTab = true;
  bool showNonCorporateManagementTab = true;
  bool showEmployeeManagementTab = true;
  bool showCorporateList = true;
  bool showCorporateUserListDropdown = true;
  bool showCorporateVerificationTab = true;
  bool showCorporateProfile = true;

  @override
  void initState() {
    _getClaims();
    super.initState();
  }

  _getClaims() async {
    showNonCorporateManagementTab =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMUL) ?? false;
    showEmployeeManagementTab =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPUL) ?? false;
    showCorporateList =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMCL) ?? false;
    showCorporateUserListDropdown =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMCUM) ?? false;
    showCorporateVerificationTab =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMLL) ?? false;
    showCorporateProfile =
        await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMCUL) ?? false;

    showCorporateManagementTab = showCorporateList ||
        showCorporateUserListDropdown ||
        showCorporateVerificationTab ||
        showCorporateProfile;
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    // Determine the icon color based on the theme
    Color? iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[300]  // Light color for dark theme
        : Colors.grey[800]; // Dark color for light theme

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/images/fullLogo.svg',
                    semanticsLabel: 'Logo',
                  ),
                  const SizedBox(height: 20),
                  // Search bar added
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: iconColor),
                      hintText: 'Search',
                      hintStyle: typography.Body1,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200], // Use a lighter color for light theme
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.only(top: 0), // Removed top padding
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.home, color: iconColor),
                    title: Text(LanguageService.getTranslated(context, "drawer_menu_dashboard"),
                        style: typography.Body1.copyWith(color: iconColor)),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DashboardScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.account_balance_wallet, color: iconColor),
                    title: Text(LanguageService.getTranslated(context, "drawer_menu_accounts"),
                        style: typography.Body1.copyWith(color: iconColor)),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountListScreen()));
                    },
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.feed, color: iconColor),
                    title: Text(LanguageService.getTranslated(context, "drawer_menu_news_feed"),
                        style: typography.Body1.copyWith(color: iconColor)),
                    children: <Widget>[
                      ListTile(
                        title: Text(LanguageService.getTranslated(context, "drawer_menu_improve_locations"),
                            style: typography.Body1.copyWith(color: iconColor)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LanguageService.getTranslated(context, "coming_soon"),
                                  style: typography.Body1.copyWith(color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white),)),
                          );
                         // Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobMonitoringDashboard()));
                        },
                      ),
                      // Add other ListTile widgets for additional items
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.insights, color: iconColor),
                    title: Text(LanguageService.getTranslated(context, "drawer_menu_insights"),
                        style: typography.Body1.copyWith(color: iconColor)),
                    children: <Widget>[
                      ListTile(
                        title: Text(LanguageService.getTranslated(context, "drawer_menu_data_quality"),
                            style: typography.Body1.copyWith(color: iconColor)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LanguageService.getTranslated(context, "coming_soon"),
                                style: typography.Body1.copyWith(color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white),),
                            ),
                          );
                          //Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProcessMonitoringScreen()));
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.people, color: iconColor),
                    title: Text(LanguageService.getTranslated(context, "drawer_menu_connections"),
                        style: typography.Body1.copyWith(color: iconColor)),
                    children: <Widget>[
                      ListTile(
                        title: Text(LanguageService.getTranslated(context, "drawer_menu_add_vendor"),
                            style: typography.Body1.copyWith(color: iconColor)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LanguageService.getTranslated(context, "coming_soon"),
                          style: typography.Body1.copyWith(color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                              : Colors.white),),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ThemeSwitcher(),
                  CountryPickerDropdown(
                    initialValue: _getInitialCountry(context),
                    itemBuilder: (Country country) {
                      return Container(
                        width: 28.0, // Adjust the width as needed
                        height: 28.0, // Adjust the height as needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0), // Set the desired border radius
                          image: DecorationImage(
                            image: AssetImage(
                              CountryPickerUtils.getFlagImageAssetPath(country.isoCode),
                              package: 'country_pickers',
                            ),
                            fit: BoxFit.cover,
                          ),
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
                  ),
                  Consumer<AuthNotifier>(
                    builder: (context, authNotifier, child) {
                      return IconButton(
                        icon: Icon(Icons.logout_rounded, color: iconColor),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(LanguageService.getTranslated(context, "drawer_menu_logout"),
                                    style: typography.Body1.copyWith(color: iconColor)),
                                content: Text(LanguageService.getTranslated(context, "drawer_menu_logout_confirmation"),
                                    style: typography.Body1.copyWith(color: iconColor)),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(LanguageService.getTranslated(context, "drawer_menu_cancel"),
                                        style: typography.Body1.copyWith(color: iconColor)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      authNotifier.signOut();
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => SplashScreen()),
                                              (route) => false);
                                    },
                                    child: Text(LanguageService.getTranslated(context, "drawer_menu_logout"),
                                        style: typography.Body1.copyWith(color: iconColor)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (showCorporateManagementTab || showNonCorporateManagementTab || showEmployeeManagementTab)
                    IconButton(
                      icon: Icon(Icons.person, color: iconColor),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserManagementScreen()));
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
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
