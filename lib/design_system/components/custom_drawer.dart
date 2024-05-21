import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/settings/settings.dart';
import 'package:green/screens/userManagement/user_management.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    Key? key,
  }) : super(key: key);

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
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationProfile()));
                          },
                        ),
                        ListTile(
                          title: const Text('Location(s) Map'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Manage insurers List'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Add A Location'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Create A Campus'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Cat Modellers And Risk Engineers Work'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Activity'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Real Time Weather Activity'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Broker Activity'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Insights'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('See Hazard Scores'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Results'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('See Vendor Recommendations'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('See Data Improvement Recommendations'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Comparison Data'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Add Broker'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Add Freelancer'),
                          onTap: () {
                            Navigator.pop(context);
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
                            Navigator.pop(context);
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
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Leads Map'),
                          onTap: () {
                            Navigator.pop(context);
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
                  IconButton(
                    icon: Icon(Icons.person),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserManagementScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}