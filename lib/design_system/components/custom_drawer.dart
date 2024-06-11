import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/settings/settings.dart';
import 'package:green/screens/userManagement/user_management.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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
    showNonCorporateManagementTab = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.NCMUL) ??
        false;
    showEmployeeManagementTab = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPUL) ??
        false;

    showCorporateList = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCL) ??
        false;

    showCorporateUserListDropdown =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CAMCUM) ??
            false;
    showCorporateVerificationTab =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CAMLL) ??
            false;

    showCorporateProfile = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCUL) ??
        false;


    showCorporateManagementTab = showCorporateList ||
        showCorporateUserListDropdown ||
        showCorporateVerificationTab ||
        showCorporateProfile;



  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Theme(
          // New theme specifically for the ExpansionTile widgets
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // Transparent divider color
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                // Using CustomTypography.Body1 text style
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black, // Change color as per your requirement
              ),
            ),
          ),
          child: Column(
            children: [
              DrawerHeader(
                padding: const EdgeInsets.all(0),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      semanticsLabel: 'Logo',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: ClampingScrollPhysics(),
                  padding: EdgeInsets.only(top: 0), // Removed top padding
                  children: <Widget>[
                    ListTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/homeIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),

                      ),
                      title: const Text('Dashboard'),
                      onTap: () {
                        //Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DashboardScreen()));
                      },
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/listingsIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Listings'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Location(s) List'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountListScreen()));
                            //Show coming soon snackbar
                            /*ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );*/
                          },
                        ),
                        ListTile(
                          title: const Text('Location(s) Map'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/portfolioIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Portfolio/SOVs'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Risk Manager List'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Manage insurers List'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/locationIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Locations'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Upload Locations'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Add A Location'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Create A Campus'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/newsfeedIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('News Feed'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Improved Locations'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Cat Modellers And Risk Engineers Work'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Activity'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Real Time Weather Activity'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Broker Activity'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Insights'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/insightsIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Insights'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('See Data Quality'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('See Hazard Scores'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Results'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Recommendations'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('See Data Improvement Recommendations'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Comparison Data'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/connectionsIcon.svg',
                          semanticsLabel: 'Dashboard',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Connections'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Add Vendor'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Add Broker'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Add Freelancer'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/trainingDataIcon.svg',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                          semanticsLabel: 'Dashboard',
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Training Data'),
                      children: <Widget>[

                        ListTile(
                          title: const Text('Get Paid To Create Tags On Phrases'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/trainingDataIcon.svg',
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                          semanticsLabel: 'Dashboard',
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: const Text('Leads'),
                      children: <Widget>[
                        ListTile(
                          title: const Text('Leads List'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Leads Map'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Coming Soon!', style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  /*IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      // Navigate to Settings Screen
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
                    },
                  ),*/
                  /*IconButton(
                    icon: Icon(Icons.brightness_7_rounded),
                    onPressed: () {
                      // Change Theme
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                    },
                  ),*/
                  Consumer<AuthNotifier>(
                      builder: (context, authNotifier, child) {
                      return IconButton(
                        icon: Icon(Icons.logout_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Logout'),
                                content: Text('Are you sure you want to logout?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      authNotifier.signOut();
                                      Navigator.pushAndRemoveUntil(
                                          context, MaterialPageRoute(builder: (_) => SplashScreen()), (route) => false);
                                    },
                                    child: Text('Logout'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    }
                  ),
                  (showCorporateManagementTab || showNonCorporateManagementTab || showEmployeeManagementTab)
                      ? IconButton(
                    icon: Icon(Icons.person),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserManagementScreen()));
                    },
                  )
                      : SizedBox()
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}