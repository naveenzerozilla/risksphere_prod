import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/screens/home/dashboard_screen.dart';
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
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_dashboard"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),

                      ),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_dashboard")),
                      onTap: () {
                        //Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DashboardScreen()));
                      },
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountListScreen()));
                      },

                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/listingsIcon.svg',
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_accounts"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_accounts"), style: CustomTypography.Body1,),
                      trailing: SizedBox(),
                    ),
                    ExpansionTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/portfolioIcon.svg',
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_sovs"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_sovs"), style: CustomTypography.Body1,),
                      children: <Widget>[
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_risk_manager_list"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_manage_insurers_list"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
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
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_news_feed"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_news_feed"), style: CustomTypography.Body1,),
                      children: <Widget>[
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_improve_locations"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_cat_modelers_risk_engineer_work"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_vendor_activity"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_weather_activity"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_broker_activity"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_insights"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
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
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_insights"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_insights"), style: CustomTypography.Body1,),
                      children: <Widget>[
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_data_quality"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_hazard_scores"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_vendor_results"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_verndor_recommendations"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_data_improvement_recommendations"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_comparison_data"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
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
                          semanticsLabel: LanguageService.getTranslated(context, "drawer_menu_connections"),
                          colorFilter: ColorFilter.mode( Theme.of(context).colorScheme.onBackground , BlendMode.srcIn),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(left: 40),
                      title: Text(LanguageService.getTranslated(context, "drawer_menu_connections"), style: CustomTypography.Body1,),
                      children: <Widget>[
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_add_vendor"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_add_broker"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(LanguageService.getTranslated(context, "drawer_menu_add_freelancer"), style: CustomTypography.Body1,),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.getTranslated(context, "coming_soon"), style: CustomTypography.Body1,),
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
                  Consumer<AuthNotifier>(
                      builder: (context, authNotifier, child) {
                        return IconButton(
                          icon: Icon(Icons.logout_rounded),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(LanguageService.getTranslated(context, "drawer_menu_logout"), style: CustomTypography.Body1,),
                                  content: Text(LanguageService.getTranslated(context, "drawer_menu_logout_confirmation"), style: CustomTypography.Body1),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(LanguageService.getTranslated(context, "drawer_menu_cancel"), style: CustomTypography.Body1,),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        authNotifier.signOut();
                                        Navigator.pushAndRemoveUntil(
                                            context, MaterialPageRoute(builder: (_) => SplashScreen()), (route) => false);
                                      },
                                      child: Text(LanguageService.getTranslated(context, "drawer_menu_logout"), style: CustomTypography.Body1,),
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
