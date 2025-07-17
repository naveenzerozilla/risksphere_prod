import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/components/theme_switcher.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/listings/account_list.dart';
import 'package:RiskSphere/screens/userManagement/user_management.dart';
import '../../models/my_location_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../providers/my_location_list_provider.dart';
import '../../screens/listings/news_feed_screen.dart';
import '../../screens/listings/widgets/auto_complete_options_locations.dart';
import '../../screens/listings/widgets/message_card.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../screens/payments/pricing_list.dart';
import '../../screens/payments/transaction_summary.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../../utils/debouncer.dart';
import '../primitives/app_colors.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late final ScrollController _scrollController;
  bool showCorporateManagementTab = true;
  bool showNonCorporateManagementTab = true;
  bool showEmployeeManagementTab = true;
  bool showCorporateList = true;
  bool showCorporateUserListDropdown = true;
  bool showCorporateVerificationTab = true;
  bool showCorporateProfile = true;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  bool isLoggingOut = false;

  bool showTotalCorporates = false;
  bool showAllUsers = false;
  bool showConnectionRequests = false;
  bool showCompanyOnboardingStats = false;
  bool showUserOnboardingStats = false;
  bool showVerificationRequests = false;
  String isMaintenance = "";

  final TextEditingController searchController = TextEditingController();
  final Debouncer debouncer = Debouncer(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setClaims();
    _getClaims();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _setClaims(),
    ]);
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

    _getMaintainancePeriod();
    setState(() {});
  }

  Future<void> _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? "false";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _getClaims() async {
    showNonCorporateManagementTab =
        await SharedPreferenceService.getClaimForSubfeature(
                SharedPreferenceService.NCMUL) ??
            false;
    showEmployeeManagementTab =
        await SharedPreferenceService.getClaimForSubfeature(
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

// Add this to your widget's state

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    // Determine the icon color based on the theme
    Color? iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[300] // Light color for dark theme
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
                              SizedBox(height: 10),
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
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      PricingListScreen()));
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
                  Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          if (value.isNotEmpty && value.length > 2) {
                            debouncer.run(() {
                              Provider.of<MyLocationListProvider>(context,
                                      listen: false)
                                  .performGlobalSearch(context, value);
                            });
                          } else {
                            Provider.of<MyLocationListProvider>(context,
                                    listen: false)
                                .searchLocationList = [];
                          }
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: iconColor),
                          hintText: 'Search Locations',
                          hintStyle: typography.Body1,
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      Consumer<MyLocationListProvider>(
                        builder: (context, provider, child) {
                          return AutocompleteOptionsLocation(
                            options: provider.searchLocationList,
                            isLoading: provider.isSearchLoading,
                            onSelected: (MyLocation selectedLocation) {
                              // Handle location selection
                              searchController.text =
                                  selectedLocation.finalAddress?.address ?? '';
                              provider.searchLocationList =
                                  []; // Clear results after selection
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: Consumer<DrawerSelectionProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      controller: _scrollController,
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
                              MaterialPageRoute(
                                  builder: (_) => DashboardScreen()),
                            );
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
                              MaterialPageRoute(
                                  builder: (_) => AccountListScreen()),
                            );
                          },
                          isSelected: provider.selectedItem == "accounts",
                        ),
                        _buildDrawerItem(
                          context,
                          provider,
                          title: "News Feed",
                          icon: Icons.space_dashboard,
                          onTap: () {
                            provider.setSelectedItem("news");
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => NewsFeedScreen()),
                            );
                          },
                          isSelected: provider.selectedItem == "news",
                        ),
                        isPgAdmin.toString() == "true"
                            ? _buildDrawerItem(
                                context,
                                provider,
                                title: "Payment History",
                                icon: Icons.payments_sharp,
                                onTap: () {
                                  provider.setSelectedItem("payment_history");
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentTransactionsPage(),
                                    ),
                                  );
                                },
                                isSelected:
                                    provider.selectedItem == "Payment History",
                              )
                            : Container(),
                        isPgAdmin.toString() == "true" ||
                                (isPgAdmin.toString() == "false" &&
                                    isIndivudual.toString() == "false" &&
                                    isSuperAdmin.toString() == "false")
                            ? Container()
                            : _buildDrawerItem(
                                context,
                                provider,
                                title: "Purchase License",
                                icon: Icons.description,
                                onTap: () {
                                  provider.setSelectedItem("purchase_license");
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PricingListScreen(),
                                    ),
                                  );
                                },
                                isSelected:
                                    provider.selectedItem == "purchase_license",
                              ),
                        isPgAdmin.toString() == "true" ||
                                (isPgAdmin.toString() == "false" &&
                                    isIndivudual.toString() == "false" &&
                                    isSuperAdmin.toString() == "false")
                            ? Container()
                            : _buildDrawerItem(
                                context,
                                provider,
                                title: "Payment History",
                                icon: Icons.payments_sharp,
                                onTap: () {
                                  provider.setSelectedItem("payment_history");
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentTransactionsPage(),
                                    ),
                                  );
                                },
                                isSelected:
                                    provider.selectedItem == "Payment History",
                              ),
                      ],
                    );
                  },
                ),
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
                          // Set the desired border radius
                          image: DecorationImage(
                            image: AssetImage(
                              CountryPickerUtils.getFlagImageAssetPath(
                                  country.isoCode),
                              package: 'country_pickers',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                    itemFilter: (Country country) {
                      return ['US', 'ES', 'FR', 'JP', 'CN']
                          .contains(country.isoCode);
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
                                title: Text(
                                  LanguageService.getTranslated(
                                      context, "drawer_menu_logout"),
                                  style: typography.Body1.copyWith(
                                      color: iconColor),
                                ),
                                content: Text(
                                  LanguageService.getTranslated(context,
                                      "drawer_menu_logout_confirmation"),
                                  style: typography.Body1.copyWith(
                                      color: iconColor),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      LanguageService.getTranslated(
                                          context, "drawer_menu_cancel"),
                                      style: typography.Body1.copyWith(
                                          color: iconColor),
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        // Optional: Show loader here if using a loading state
                                        final GoogleSignIn _googleSignIn =
                                            GoogleSignIn(scopes: ['email']);

                                        // Step 1: If Google user is signed in
                                        if (await _googleSignIn.isSignedIn()) {
                                          try {
                                            // Revoke access (optional)
                                            await _googleSignIn.disconnect();
                                          } catch (e) {
                                            print(
                                                "Google disconnect error (optional): $e");
                                          }

                                          // Sign out from Google
                                          await _googleSignIn.signOut();
                                        }

                                        // Step 2: Sign out from Firebase
                                        await FirebaseAuth.instance.signOut();

                                        // Step 3: Reset state like drawer selection
                                        Provider.of<DrawerSelectionProvider>(
                                                context,
                                                listen: false)
                                            .setSelectedItem("dashboard");

                                        // Step 4: Navigate to splash screen
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => SplashScreen()),
                                          (route) => false,
                                        );
                                      } catch (e) {
                                        print("Logout error: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "Logout failed. Please try again.")),
                                        );
                                      }
                                    },
                                    child: isLoggingOut
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              color: iconColor,
                                            ),
                                          )
                                        : Text(
                                            LanguageService.getTranslated(
                                                context, "drawer_menu_logout"),
                                            style: typography.Body1.copyWith(
                                                color: iconColor),
                                          ),
                                  ),

                                  // TextButton(
                                  //   onPressed: () async {
                                  //     try {
                                  //       final googleSignIn = GoogleSignIn();
                                  //
                                  //       // Sign out from Firebase Auth
                                  //       await FirebaseAuth.instance.signOut();
                                  //
                                  //       // If signed in with Google, sign out and disconnect
                                  //       if (await googleSignIn.isSignedIn()) {
                                  //         await googleSignIn.disconnect();
                                  //         await googleSignIn.signOut();
                                  //       }
                                  //
                                  //       // Reset any state (like drawer)
                                  //       Provider.of<DrawerSelectionProvider>(context, listen: false)
                                  //           .setSelectedItem("dashboard");
                                  //
                                  //       // Navigate to SplashScreen
                                  //       Navigator.pushAndRemoveUntil(
                                  //         context,
                                  //         MaterialPageRoute(builder: (_) => SplashScreen()),
                                  //             (route) => false,
                                  //       );
                                  //     } catch (e) {
                                  //       print("Logout error: $e");
                                  //       ScaffoldMessenger.of(context).showSnackBar(
                                  //         SnackBar(content: Text("Logout failed. Please try again.")),
                                  //       );
                                  //     }
                                  //   },
                                  //   child: Text(
                                  //     LanguageService.getTranslated(context, "drawer_menu_logout"),
                                  //     style: typography.Body1.copyWith(color: iconColor),
                                  //   ),
                                  // ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  // Consumer<AuthNotifier>(
                  //   builder: (context, authNotifier, child) {
                  //     return IconButton(
                  //       icon: Icon(Icons.logout_rounded, color: iconColor),
                  //       onPressed: () {
                  //         showDialog(
                  //           context: context,
                  //           builder: (context) {
                  //             return AlertDialog(
                  //               title: Text(
                  //                   LanguageService.getTranslated(
                  //                       context, "drawer_menu_logout"),
                  //                   style: typography.Body1.copyWith(
                  //                       color: iconColor)),
                  //               content: Text(
                  //                   LanguageService.getTranslated(context,
                  //                       "drawer_menu_logout_confirmation"),
                  //                   style: typography.Body1.copyWith(
                  //                       color: iconColor)),
                  //               actions: <Widget>[
                  //                 TextButton(
                  //                   onPressed: () {
                  //                     Navigator.pop(context);
                  //                   },
                  //                   child: Text(
                  //                       LanguageService.getTranslated(
                  //                           context, "drawer_menu_cancel"),
                  //                       style: typography.Body1.copyWith(
                  //                           color: iconColor)),
                  //                 ),
                  //
                  //                 TextButton(
                  //                   onPressed: () async {
                  //                     try {
                  //                       final googleSignIn = GoogleSignIn();
                  //
                  //                       // Sign out from Firebase Auth
                  //                       await FirebaseAuth.instance.signOut();
                  //
                  //                       // Revoke Google access and sign out
                  //                       if (await googleSignIn.isSignedIn()) {
                  //                         await googleSignIn.disconnect(); // Revokes access so next sign-in prompts account chooser
                  //                         await googleSignIn.signOut();
                  //                       }
                  //
                  //                       // Reset drawer state
                  //                       Provider.of<DrawerSelectionProvider>(context, listen: false)
                  //                           .setSelectedItem("dashboard");
                  //
                  //                       // Navigate to SplashScreen
                  //                       Navigator.pushAndRemoveUntil(
                  //                         context,
                  //                         MaterialPageRoute(builder: (_) => SplashScreen()),
                  //                             (route) => false,
                  //                       );
                  //                     } catch (e) {
                  //                       print("Logout error: $e");
                  //                       ScaffoldMessenger.of(context).showSnackBar(
                  //                         SnackBar(content: Text("Logout failed. Please try again.")),
                  //                       );
                  //                     }
                  //                   },
                  //                   child: Text(
                  //                     LanguageService.getTranslated(context, "drawer_menu_logout"),
                  //                     style: typography.Body1.copyWith(color: iconColor),
                  //                   ),
                  //                 ),
                  //
                  //                 // TextButton(
                  //                 //   onPressed: () async {
                  //                 //     await authNotifier.signOut();
                  //                 //
                  //                 //
                  //                 //     Provider.of<DrawerSelectionProvider>(
                  //                 //             context,
                  //                 //             listen: false)
                  //                 //         .setSelectedItem("dashboard");
                  //                 //     Navigator.pushAndRemoveUntil(
                  //                 //         context,
                  //                 //         MaterialPageRoute(
                  //                 //             builder: (_) => SplashScreen()),
                  //                 //         (route) => false);
                  //                 //   },
                  //                 //   child: Text(
                  //                 //       LanguageService.getTranslated(
                  //                 //           context, "drawer_menu_logout"),
                  //                 //       style: typography.Body1.copyWith(
                  //                 //           color: iconColor)),
                  //                 // ),
                  //               ],
                  //             );
                  //           },
                  //         );
                  //       },
                  //     );
                  //   },
                  // ),
                  if (showCorporateManagementTab ||
                      showNonCorporateManagementTab ||
                      showEmployeeManagementTab)
                    Consumer<DrawerSelectionProvider>(
                      builder: (context, provider, child) {
                        return Consumer<UserProfileProvider>(
                          builder: (context, userProfileProvider, child) {
                            bool isNotIndividual =
                                !(userProfileProvider.userData.isIndividual ??
                                    true); // Defaulting to true if null

                            return userProfileProvider.isLoading
                                ? Center(child: CircularProgressIndicator())
                                : isNotIndividual
                                    ? Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(66),
                                          color: provider.selectedItem ==
                                                  "user_management"
                                              ? AppColors.primaryMain
                                                  .withOpacity(0.4)
                                              : Colors.transparent,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.person,
                                            color: provider.selectedItem ==
                                                    "user_management"
                                                ? AppColors.primaryMain
                                                : iconColor,
                                          ),
                                          onPressed: () {
                                            provider.setSelectedItem(
                                                "user_management");
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      UserManagementScreen()),
                                            );
                                          },
                                        ),
                                      )
                                    : Container();

                            //   bool.parse((!userProfileProvider.userData.isIndividual! ?? true).toString()) ?
                            //   Container(
                            //   decoration: BoxDecoration(
                            //     borderRadius: BorderRadius.circular(66),
                            //     color:
                            //         provider.selectedItem == "user_management"
                            //             ? AppColors.primaryMain.withOpacity(0.4)
                            //             : Colors.transparent,
                            //   ),
                            //   child:
                            //
                            //   IconButton(
                            //     icon:
                            //     Icon(
                            //       Icons.person,
                            //       color:
                            //           provider.selectedItem == "user_management"
                            //               ? AppColors.primaryMain
                            //               : iconColor,
                            //     ),
                            //     onPressed: () {
                            //       provider.setSelectedItem("user_management");
                            //       Navigator.of(context).push(
                            //         MaterialPageRoute(
                            //             builder: (_) => UserManagementScreen()),
                            //       );
                            //     },
                            //   ),
                            // ):Container();
                          },
                        );
                      },
                    )
                  //               if (showCorporateManagementTab || showNonCorporateManagementTab || showEmployeeManagementTab)
                  //                 Consumer<DrawerSelectionProvider>(
                  //                   builder: (context, provider, child) {
                  //                     return
                  //
                  //                       Consumer<UserProfileProvider>(
                  //                         builder: (context, userProfileProvider, child) {
                  //                           builder:
                  //                               (context) {
                  //                             return Container(
                  //
                  //                               decoration: BoxDecoration(
                  //                                 borderRadius: BorderRadius.circular(66),
                  //                                 color: provider.selectedItem ==
                  //                                     "user_management"
                  //                                     ? AppColors.primaryMain.withOpacity(0.4)
                  //                                     : Colors.transparent,
                  //
                  //                               ),
                  //                               child: IconButton(
                  //                                 icon: Icon(Icons.person,
                  //                                     color: provider.selectedItem ==
                  //                                         "user_management"
                  //                                         ? AppColors.primaryMain
                  //                                         : iconColor),
                  //                                 onPressed: () {
                  //                                   provider.setSelectedItem(
                  //                                       "user_management");
                  //                                   Navigator.of(context).push(
                  //                                       MaterialPageRoute(builder: (_) =>
                  //                                           UserManagementScreen()));
                  //                                 },
                  //                               ),
                  //                             );
                  //                           };
                  //                         }
                  //                         );
                  //                         },
                  // ),
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
    // ['US', 'ES', 'FR', 'JP', 'CN']
    if (context.locale == Locale('es')) return 'ES';
    if (context.locale == Locale('fr')) return 'FR';
    if (context.locale == Locale('ja')) return 'JP';
    if (context.locale == Locale('zh')) return 'CN';
    return 'US';
  }
}
