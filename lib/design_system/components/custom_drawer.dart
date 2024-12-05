import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/theme_switcher.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/listings/account_list.dart';
import 'package:green/screens/userManagement/user_management.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../primitives/app_colors.dart'; // Import the provider

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

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    _getClaims();
    super.initState();
  }

  _getClaims() async {
    // These claims are fetched asynchronously; adjust the logic as per your API or service call
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
        ? Colors.grey[300]
        : Colors.grey[800];

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
                  Tooltip(
                    message: 'Enter added locations to search',
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        // Implement your search logic here
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: iconColor),
                        hintText: 'Search Locations',

                        hintStyle: typography.Body1,
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: Consumer<DrawerSelectionProvider>(
                builder: (context, provider, child) {
                  return ListView(
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.only(top: 0),
                    children: <Widget>[
                      _buildDrawerItem(
                        context,
                        provider,
                        title: "Dashboard",
                        icon: Icons.home,
                        onTap: () {
                          provider.setSelectedItem("dashboard");
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DashboardScreen()));
                        },
                        isSelected: provider.selectedItem == "dashboard",
                      ),
                      _buildDrawerItem(
                        context,
                        provider,
                        title: "Accounts",
                        icon: Icons.account_balance_wallet,
                        onTap: () {
                          provider.setSelectedItem("accounts");
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AccountListScreen()));
                        },
                        isSelected: provider.selectedItem == "accounts",
                      ),
                    ],
                  );
                },
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
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
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
                    Consumer<DrawerSelectionProvider>(
                      builder: (context, provider, child) {
                        return Container(

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(66),
                            color: provider.selectedItem == "user_management"
                                ? AppColors.primaryMain.withOpacity(0.4)
                                : Colors.transparent,

                          ),
                          child: IconButton(
                            icon: Icon(Icons.person,
                                color: provider.selectedItem == "user_management"
                                    ? AppColors.primaryMain
                                    : iconColor),
                            onPressed: () {
                              provider.setSelectedItem("user_management");
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => UserManagementScreen()));
                            },
                          ),
                        );
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

  Widget _buildDrawerItem(
      BuildContext context,
      DrawerSelectionProvider provider, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
        required bool isSelected,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),

        color: isSelected
            ? AppColors.primaryMain.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primaryMain : null),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryMain : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _getInitialCountry(BuildContext context) {
    if (context.locale == Locale('es')) return 'ES';
    if (context.locale == Locale('fr')) return 'FR';
    if (context.locale == Locale('ja')) return 'JP';
    if (context.locale == Locale('zh')) return 'CN';
    return 'US';
  }
}
