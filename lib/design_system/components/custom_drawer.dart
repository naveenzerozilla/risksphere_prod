import 'dart:io';

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
import 'package:RiskSphere/design_system/components/theme_switcher.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/userManagement/user_management.dart';
import '../../constants/enums.dart';
import '../../models/my_location_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../providers/my_location_list_provider.dart';
import '../../screens/listings/location_profile.dart';
import '../../screens/listings/mysov_list.dart';
import '../../screens/listings/news_feed_screen.dart';
import '../../screens/listings/vendor_list.dart';
import '../../screens/listings/widgets/auto_complete_options_locations.dart';
import '../../screens/listings/widgets/message_card.dart';
import '../../screens/onboarding/login_screen.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../screens/onboarding/supportscreen.dart';
import '../../screens/payments/purchase_license.dart';
import '../../screens/payments/transaction_summary.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/global_imports.dart';
import '../primitives/app_colors.dart';
import '../primitives/utilities/custom_spacing.dart';
import 'custom_button.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  // final ScrollController _scrollController = ScrollController();
  bool showCorporateManagementTab = true;
  String selectedSovMenu = "";
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
  bool sovExpanded = false;
  bool adminExpanded = false;
  bool showTotalCorporates = false;
  bool showAllUsers = false;
  bool showConnectionRequests = false;
  bool showCompanyOnboardingStats = false;
  bool showUserOnboardingStats = false;
  bool showVerificationRequests = false;
  String isMaintenance = "";
  String? trialMap;

  final TextEditingController searchController = TextEditingController();
  final Debouncer debouncer = Debouncer(milliseconds: 200);
  bool isHasAnyPlan = false;

  @override
  void initState() {
    super.initState();
    _setClaims();
    _getClaims();
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
    isHasAnyPlan = await SharedPreferenceService.getHasAnyPlan();

    trialMap = await SharedPreferenceService.getTrialPeriodStartRaw();
    showVerificationRequests =
        showCorporateVerificationRequests || showUserVerificationRequests;

    _getMaintainancePeriod();
    setState(() {});
  }

  Future<void> _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? "false";
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
                  // // Search bar added
                  Consumer<UserProfileProvider>(
                    builder: (context, userProfile, child) {
                      final trialStatus = userProfile.trialInfo['status'] ?? '';

                      // if (trialStatus.contains('Expired'))
                      if (trialStatus.contains('Expired') &&
                          isHasAnyPlan == false) {
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
                                          'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before ${trialMap ?? 'your trial end date'}. After this date, we will need to delete your data. Thank you for being with us!',
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
                                                      PurchaseLicensePage()));
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
                      SizedBox(height: 10),
                      Consumer<MyLocationListProvider>(
                        builder: (context, provider, child) {
                          return AutocompleteOptionsLocation(
                            options: provider.searchLocationList,
                            isLoading: provider.isSearchLoading,
                            onSelected: (MyLocation location) {
                              // Update text field
                              searchController.text = location.address ?? '';

                              // Clear results
                              provider.searchLocationList = [];

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => LocationProfile(
                                    accountId: location.accountId!,
                                    accountName: location.accountName!,
                                    subAccountId: location.subAccountId!,
                                    subAccountName: location.subAccountName!,
                                    sovId: "",
                                    sovName: "test",
                                    searchQuery: "",
                                    locationId: location.locationId,
                                    page: "1",
                                    totalPages: "1",
                                    // hazardProcess: "",
                                    // onConfirmCallback: widget.getData,
                                    // onNavigateBack: widget.onNavigateBack,
                                    tab: 0,
                                  ),
                                  // builder: (_) => LocationProfile(
                                  //   accountId: location.accountId ?? "",
                                  //   accountName: location.accountName ?? "",
                                  //   subAccountId: location.subAccountId ?? "",
                                  //   subAccountName: location.subAccountName ?? "",
                                  //   sovId: "",
                                  //   sovName: "",
                                  //   searchQuery:  "",
                                  //   locationId:  location.locationId,
                                  //   page: "1",
                                  //   totalPages: "1",
                                  // ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer2<DrawerSelectionProvider, UserProfileProvider>(
                builder: (context, provider, userProfileProvider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    // controller: _scrollController,
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.only(top: 0),
                    children: <Widget>[
                      _buildDrawerItem(
                        context,
                        provider,
                        title: LanguageService.getTranslated(
                            context, 'drawer_menu_dashboard'),
                        icon: Icons.home,
                        onTap: () {
                          provider.setSelectedItem("dashboard");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => DashboardScreen(
                                      newUser: "true",
                                      defaultTab: "dashboard",
                                    )),
                          );
                        },
                        isSelected: provider.selectedItem == "dashboard",
                      ),
                      _buildDrawerItem(
                        context,
                        provider,
                        title: LanguageService.getTranslated(
                            context, 'drawer_menu_locations'),
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
                      buildDrawerCategory(
                        context: context,
                        title: LanguageService.getTranslated(
                            context, 'drawer_menu_sovs'),
                        icon: Icons.ballot,
                        isExpanded: !sovExpanded,
                        onTap: () {
                          provider.setSelectedItem("sov_list"); // FIX 🔥
                          setState(() {
                            sovExpanded = !sovExpanded;
                          });
                        },
                      ),

                      if (sovExpanded) ...[
                        buildSubMenuItem(
                          title: LanguageService.getTranslated(
                              context, 'drawer_menu_mysovs'),
                          isSelected: selectedSovMenu == "My SOVs",
                          onTap: () {
                            setState(() => selectedSovMenu = "My SOVs");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MySovList(status: "my")));
                          },
                        ),
                        buildSubMenuItem(
                          title: LanguageService.getTranslated(
                              context, 'drawer_menu_sharedsovs'),
                          isSelected: selectedSovMenu == "Shared SOVs",
                          onTap: () {
                            setState(() => selectedSovMenu = "Shared SOVs");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MySovList(status: "shared")));
                          },
                        ),
                        buildSubMenuItem(
                          title: LanguageService.getTranslated(
                              context, 'drawer_menu_receivedsovs'),
                          isSelected: selectedSovMenu == "Received SOVs",
                          onTap: () {
                            setState(() => selectedSovMenu = "Received SOVs");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MySovList(status: "received")));
                          },
                        ),
                      ],
                      isSuperAdmin.toString() == "true" &&
                              userProfileProvider.userData.isIndividual
                                      .toString() !=
                                  "true"
                          ? _buildDrawerItem(
                              context,
                              provider,
                              title: 'Credit Usage',
                              icon: Icons.request_quote_outlined,
                              onTap: () {
                                provider.setSelectedItem("credit_usage");
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VendorList(status: 'vendor')),
                                );
                              },
                              isSelected:
                                  provider.selectedItem == "credit_usage",
                            )
                          : Container(),

                      if (showUserOnboardingStats) ...[
                        buildDrawerCategory(
                          context: context,
                          title: 'Manage',
                          icon: Icons.ballot,
                          isExpanded: !adminExpanded,
                          onTap: () {
                            provider.setSelectedItem("sov_list"); // FIX 🔥
                            setState(() {
                              adminExpanded = !adminExpanded;
                            });
                          },
                        ),
                        if (adminExpanded) ...[
                          buildSubMenuItem(
                            title: 'Vendors',
                            isSelected: selectedSovMenu == "My SOVs",
                            onTap: () {
                              setState(() => selectedSovMenu = "My SOVs");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VendorList(status: 'vendor')));
                            },
                          ),
                          buildSubMenuItem(
                            title: 'Corporate Admin',
                            isSelected: selectedSovMenu == "Corporate Admin",
                            onTap: () {
                              setState(
                                  () => selectedSovMenu = "Corporate Admin");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          VendorList(status: 'corporate')));
                            },
                          ),
                        ],
                      ],
                      _buildDrawerItem(
                        context,
                        provider,
                        title: LanguageService.getTranslated(
                            context, 'drawer_menu_activity'),
                        icon: Icons.space_dashboard,
                        onTap: () {
                          provider.setSelectedItem("news");
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => NewsFeedScreen()),
                          );
                        },
                        isSelected: provider.selectedItem == "news",
                      ),
                      // Text(  isPgAdmin.toString()),// == "true"
                      //       // ? _buildDrawerItem(
                      //       //     context,
                      //       //     provider,
                      //       //     title: "Payment History",
                      //       //     icon: Icons.payments_sharp,
                      //       //     onTap: () {
                      //       //       provider.setSelectedItem("payment_history");
                      //       //       Navigator.of(context).push(
                      //       //         MaterialPageRoute(
                      //       //           builder: (_) => PaymentTransactionsPage(),
                      //       //         ),
                      //       //       );
                      //       //     },
                      //       //     isSelected:
                      //       //         provider.selectedItem == "Payment History",
                      //       //   )
                      //       // : Container(),
                      if (isIndivudual.toString() == "false" &&
                          isPgAdmin.toString() == "false" &&
                          isSuperAdmin.toString() == "false" &&
                          userProfileProvider.userData.isIndividual
                                  .toString() ==
                              "false")
                        ...[]
                      else ...[
                        // if (Platform.isAndroid)
                        _buildDrawerItem(
                          context,
                          provider,
                          title: Platform.isIOS
                              ? 'License & Sharing'
                              : 'Purchase License',
                          // "Purchase License",
                          icon: Icons.description,
                          onTap: () {
                            provider.setSelectedItem("purchase_license");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PurchaseLicensePage()),
                            );
                          },
                          isSelected:
                              provider.selectedItem == "purchase_license",
                        ),
                        _buildDrawerItem(
                          context,
                          provider,
                          title: LanguageService.getTranslated(
                              context, 'drawer_menu_paymentHistory'),
                          icon: Icons.payments_sharp,
                          onTap: () {
                            provider.setSelectedItem("payment_history");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PaymentTransactionsPage()),
                            );
                          },
                          isSelected:
                              provider.selectedItem == "payment_history",
                        ),
                      ],
//below code feature reference
                      // Text(isIndivudual.toString()),
                      // Text(isPgAdmin.toString()),
                      // Text(isSuperAdmin.toString()),
                      // Text(
                      //     userProfileProvider.userData.isIndividual.toString()),
                      // isPgAdmin.toString() == "true" ||
                      //         (isPgAdmin.toString() == "false" &&
                      //             isIndivudual.toString() == "false" &&
                      //             isSuperAdmin.toString() == "false")
                      //     ? Container()
                      //     :
                      // (userProfileProvider.userData.role != null &&
                      //         userProfileProvider.userData.role!.isNotEmpty &&
                      //         userProfileProvider.userData.role![0].name
                      //                 .toString() ==
                      //             "Admin" &&
                      // if (Platform.isAndroid)

//                if(!isSuperAdmin && !isPgAdmin && !isAdmin && !userProfileProvider.userData.isIndividual!) ...[
//                  Consumer<UserProfileProvider>(
//                    builder: (context, userProfileProvider, child) {
//                      if (isSuperAdmin ||
//                          isPgAdmin ||
//                          isAdmin ||
//                          userProfileProvider.userData.isIndividual ==
//                              true) {
//                        return _buildDrawerItem(
//                          context,
//                          provider,
//                          title: "Purchase License",
//                          icon: Icons.description,
//                          onTap: () {
//                            provider.setSelectedItem("purchase_license");
//                            Navigator.of(context).push(
//                              MaterialPageRoute(
//                                builder: (_) => PurchaseLicensePage(),
//                              ),
//                            );
//                          },
//                          isSelected:
//                          provider.selectedItem == "purchase_license",
//                        );
//                      } else {
//                        return Container();
//                      }
//                    },
//                  ),
//                  Consumer<UserProfileProvider>(
//                    builder: (context, userProfileProvider, child) {
//                      if (isSuperAdmin ||
//                          isPgAdmin ||
//                          isAdmin ||
//                          userProfileProvider.userData.isIndividual ==
//                              true) {
//                        return _buildDrawerItem(
//                          context,
//                          provider,
//                          title: "Payment History",
//                          icon: Icons.payments_sharp,
//                          onTap: () {
//                            provider.setSelectedItem("payment_history");
//                            Navigator.of(context).push(
//                              MaterialPageRoute(
//                                builder: (_) => PaymentTransactionsPage(),
//                              ),
//                            );
//                          },
//                          isSelected:
//                          provider.selectedItem == "Payment History",
//                        );
//                      } else {
//                        return Container();
//                      }
//                    },
//                  ),
//                ]
// ,

                      _buildDrawerItem(
                        context,
                        provider,
                        title: LanguageService.getTranslated(
                            context, 'drawer_menu_delete_account'),
                        icon: Icons.delete_rounded,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  LanguageService.getTranslated(
                                      context, 'delete_account'),
                                  style: typography.H5_Regular,
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      LanguageService.getTranslated(
                                          context, 'confirm_delete_account'),
                                      style: typography.Body1,
                                    ),
                                    SizedBox(height: CustomSpacing.two),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context, "cancel"),
                                              style: typography.ButtonLarge,
                                            ),
                                            type: ButtonType.text,
                                          ),
                                        ),
                                        Consumer<AuthNotifier>(
                                          builder:
                                              (context, authNotifier, child) {
                                            return ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                // 🔴 Red background
                                                foregroundColor: Colors.white,
                                                // ⚪ White text
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    bool isDeleting =
                                                        false; // local state

                                                    return StatefulBuilder(
                                                      builder:
                                                          (context, setState) {
                                                        return AlertDialog(
                                                          title: Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "delete_account"),
                                                            style: typography
                                                                .H5_Regular,
                                                          ),
                                                          content: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                LanguageService
                                                                    .getTranslated(
                                                                        context,
                                                                        "confirm_delete_account"),
                                                                style:
                                                                    typography
                                                                        .Body1,
                                                              ),
                                                              SizedBox(
                                                                  height:
                                                                      CustomSpacing
                                                                          .two),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        CustomButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                      child:
                                                                          Text(
                                                                        LanguageService.getTranslated(
                                                                            context,
                                                                            "cancel"),
                                                                        style: typography
                                                                            .ButtonLarge,
                                                                      ),
                                                                      type: ButtonType
                                                                          .text,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  // Consumer<
                                                                  //     AuthNotifier>(
                                                                  //   builder: (context,
                                                                  //       authNotifier,
                                                                  //       child) {
                                                                  //     return ElevatedButton(
                                                                  //       style: ElevatedButton
                                                                  //           .styleFrom(
                                                                  //         backgroundColor:
                                                                  //             Colors.red,
                                                                  //         foregroundColor:
                                                                  //             Colors.white,
                                                                  //         padding: const EdgeInsets
                                                                  //             .symmetric(
                                                                  //             horizontal: 20,
                                                                  //             vertical: 12),
                                                                  //         shape:
                                                                  //             RoundedRectangleBorder(
                                                                  //           borderRadius:
                                                                  //               BorderRadius.circular(6),
                                                                  //         ),
                                                                  //       ),
                                                                  //       onPressed: isDeleting
                                                                  //           ? null // disable while deleting
                                                                  //           : () async {
                                                                  //               setState(() => isDeleting = true);
                                                                  //
                                                                  //               try {
                                                                  //                 final googleSignIn = GoogleSignIn();
                                                                  //                 if (await googleSignIn.isSignedIn()) {
                                                                  //                   await googleSignIn.disconnect();
                                                                  //                 }
                                                                  //                 await authNotifier.signOut();
                                                                  //
                                                                  //                 Navigator.pushAndRemoveUntil(
                                                                  //                   context,
                                                                  //                   MaterialPageRoute(builder: (_) => LoginScreen()),
                                                                  //                   (route) => false,
                                                                  //                 );
                                                                  //
                                                                  //                 ScaffoldMessenger.of(context).showSnackBar(
                                                                  //                   const SnackBar(
                                                                  //                     content: Text("Account deleted successfully"),
                                                                  //                   ),
                                                                  //                 );
                                                                  //               } catch (e) {
                                                                  //                 ScaffoldMessenger.of(context).showSnackBar(
                                                                  //                   SnackBar(content: Text("Delete failed: $e")),
                                                                  //                 );
                                                                  //                 setState(() => isDeleting = false);
                                                                  //               }
                                                                  //             },
                                                                  //       child: isDeleting
                                                                  //           ? const SizedBox(
                                                                  //               height: 20,
                                                                  //               width: 20,
                                                                  //               child: CircularProgressIndicator(
                                                                  //                 strokeWidth: 2,
                                                                  //                 valueColor: AlwaysStoppedAnimation(Colors.white),
                                                                  //               ),
                                                                  //             )
                                                                  //           : Text(
                                                                  //               LanguageService.getTranslated(context, "delete"),
                                                                  //               style: TextStyle(
                                                                  //                 color: Colors.white,
                                                                  //                 fontSize: 18,
                                                                  //                 fontWeight: FontWeight.bold,
                                                                  //               ),
                                                                  //             ),
                                                                  //     );
                                                                  //   },
                                                                  // ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },

                                              // onPressed: () async {
                                              //   final googleSignIn = GoogleSignIn();
                                              //   if (await googleSignIn.isSignedIn()) {
                                              //     await googleSignIn.disconnect();
                                              //   }
                                              //   await authNotifier.signOut();
                                              //   Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(builder: (_) => LoginScreen()),
                                              //   );
                                              //   ScaffoldMessenger.of(context).showSnackBar(
                                              //     const SnackBar(
                                              //       content: Text("Account deleted successfully"),
                                              //     ),
                                              //   );
                                              // },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context, "delete"),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        isSelected: provider.selectedItem == "delete_account",
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
                  // ThemeSwitcher(),
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
                  InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SupportScreen()));
                      },
                      child: Icon(Icons.support_agent)),
                  Consumer<AuthNotifier>(
                    builder: (context, authNotifier, child) {
                      return IconButton(
                        icon: Icon(Icons.logout_rounded,
                            color: Colors.red.withOpacity(0.8)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setSheetState) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 16, 24, 32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ─── Drag Handle ───
                                        Container(
                                          width: 40,
                                          height: 4,
                                          margin:
                                              const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade600,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),

                                        // ─── Icon ───
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.logout_rounded,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // ─── Title ───
                                        Text(
                                          LanguageService.getTranslated(
                                              context, "logout"),
                                          style: typography.Body1.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // ─── Message ───
                                        Text(
                                          LanguageService.getTranslated(
                                              context, "confirm_logout"),
                                          textAlign: TextAlign.center,
                                          style: typography.Body1.copyWith(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 28),

                                        // ─── Logout Button ───
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: isLoggingOut
                                                ? null
                                                : () async {
                                                    try {
                                                      setSheetState(() =>
                                                          isLoggingOut = true);

                                                      await FirebaseAuth
                                                          .instance
                                                          .signOut();

                                                      final prefs =
                                                          await SharedPreferences
                                                              .getInstance();
                                                      await prefs.setBool(
                                                          'isFirstTime', false);

                                                      await authNotifier
                                                          .signOut();

                                                      Provider.of<
                                                          DrawerSelectionProvider>(
                                                        context,
                                                        listen: false,
                                                      ).setSelectedItem(
                                                          "dashboard");

                                                      if (!context.mounted)
                                                        return;

                                                      Navigator
                                                          .pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) =>
                                                                SplashScreen()),
                                                        (_) => false,
                                                      );
                                                    } catch (e, stack) {
                                                      debugPrint(
                                                          "Logout error: $e");
                                                      debugPrintStack(
                                                          stackTrace: stack);

                                                      if (!context.mounted)
                                                        return;

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              "Logout failed. Please try again."),
                                                        ),
                                                      );
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() =>
                                                            isLoggingOut =
                                                                false);
                                                      }
                                                    }
                                                  },
                                            child: isLoggingOut
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    LanguageService
                                                        .getTranslated(
                                                            context, "logout"),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // ─── Cancel Button ───
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.white24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context, "cancel"),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
                  //       icon: Icon(Icons.logout_rounded,
                  //           color: Colors.red.withOpacity(0.8)),
                  //       onPressed: () {
                  //         showDialog(
                  //           context: context,
                  //           builder: (context) {
                  //             return AlertDialog(
                  //               title: Text(
                  //                 LanguageService.getTranslated(
                  //                     context, "logout"),
                  //                 style: typography.Body1.copyWith(
                  //                     color: iconColor),
                  //               ),
                  //               content: Text(
                  //                 LanguageService.getTranslated(
                  //                     context, "confirm_logout"),
                  //                 style: typography.Body1.copyWith(
                  //                     color: iconColor),
                  //               ),
                  //               actions: <Widget>[
                  //                 TextButton(
                  //                   onPressed: () {
                  //                     Navigator.pop(context);
                  //                   },
                  //                   child: Text(
                  //                     LanguageService.getTranslated(
                  //                         context, "cancel"),
                  //                     style: typography.Body1.copyWith(
                  //                         color: iconColor),
                  //                   ),
                  //                 ),
                  //                 TextButton(
                  //                   style: TextButton.styleFrom(
                  //                     backgroundColor: Colors.red,
                  //
                  //                     foregroundColor: Colors.white,
                  //                     // ⚪ White text (also sets overlay ripple)
                  //                     padding: const EdgeInsets.symmetric(
                  //                         horizontal: 20, vertical: 12),
                  //                     shape: RoundedRectangleBorder(
                  //                       borderRadius: BorderRadius.circular(6),
                  //                     ),
                  //                   ),
                  //                   onPressed: () async {
                  //                     try {
                  //                       setState(() => isLoggingOut = true);
                  //
                  //                       /// 1️⃣ Google SignOut (ONLY if signed in)
                  //                       // final GoogleSignIn googleSignIn =
                  //                       //     GoogleSignIn();
                  //                       //
                  //                       // if (await googleSignIn.isSignedIn()) {
                  //                       //   await googleSignIn.signOut();
                  //                       //
                  //                       //   // ⚠️ Do NOT call disconnect() on Android unless required
                  //                       //   // await googleSignIn.disconnect(); ❌ REMOVE
                  //                       // }
                  //
                  //                       /// 2️⃣ Firebase sign out (AFTER Google)
                  //                       await FirebaseAuth.instance.signOut();
                  //
                  //                       /// 3️⃣ Clear local state
                  //                       final prefs = await SharedPreferences
                  //                           .getInstance();
                  //                       await prefs.setBool(
                  //                           'isFirstTime', false);
                  //
                  //                       await authNotifier.signOut();
                  //
                  //                       Provider.of<DrawerSelectionProvider>(
                  //                         context,
                  //                         listen: false,
                  //                       ).setSelectedItem("dashboard");
                  //
                  //                       /// 4️⃣ Navigate cleanly
                  //                       if (!context.mounted) return;
                  //
                  //                       Navigator.pushAndRemoveUntil(
                  //                         context,
                  //                         MaterialPageRoute(
                  //                             builder: (_) => SplashScreen()),
                  //                         (_) => false,
                  //                       );
                  //                     } catch (e, stack) {
                  //                       debugPrint("Logout error: $e");
                  //                       debugPrintStack(stackTrace: stack);
                  //
                  //                       if (!context.mounted) return;
                  //
                  //                       ScaffoldMessenger.of(context)
                  //                           .showSnackBar(
                  //                         const SnackBar(
                  //                           content: Text(
                  //                               "Logout failed. Please try again."),
                  //                         ),
                  //                       );
                  //                     } finally {
                  //                       if (mounted)
                  //                         setState(() => isLoggingOut = false);
                  //                     }
                  //                   },
                  //                   child: isLoggingOut
                  //                       ? SizedBox(
                  //                           height: 18,
                  //                           width: 18,
                  //                           child: CircularProgressIndicator(
                  //                             strokeWidth: 2.0,
                  //                             color: iconColor,
                  //                           ),
                  //                         )
                  //                       : Text(
                  //                           LanguageService.getTranslated(
                  //                               context, "logout"),
                  //                           style: typography.Body1.copyWith(
                  //                               color: iconColor,
                  //                               fontSize: 16,
                  //                               fontWeight: FontWeight.bold),
                  //                         ),
                  //                 ),
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
                          },
                        );
                      },
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSubMenuItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primaryMain.withOpacity(0.1) // SAME AS DASHBOARD
            : Colors.transparent,
      ),
      margin: EdgeInsets.only(left: 48, right: 12, top: 1, bottom: 1),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? AppColors.primaryMain : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
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

  Widget buildDrawerCategory({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // color: const Color(0xFF223748),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 22,
                  color: !isExpanded ? AppColors.primaryMain : AppColors.red50),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: !isExpanded ? AppColors.primaryMain : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              !isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: !isExpanded ? AppColors.primaryMain : null,
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
