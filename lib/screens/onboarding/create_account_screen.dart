import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:RiskSphere/design_system/components/country_picker_flag_name.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/initial_data_model.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:phone_input/phone_input_package.dart';
import 'package:provider/provider.dart';
import '../../appleauth.dart';
import '../../constants/enums.dart';
import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/language_service.dart';
import '../../utils/utils.dart';

import 'package:country_picker/country_picker.dart' as country_picker;

import '../terms_privacy.dart';

class CreateAccountScreen extends StatefulWidget {
  final UserCredential? userCredential;
  final String? email;
  final String? user;

  const CreateAccountScreen(
      {super.key, this.userCredential, this.email, this.user});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  SignUpOptions? _selectedOption;
  Roles? selectedRole;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  bool _isDropdownOpen = false;

  /// Individual account UI
  TextEditingController nameController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  PhoneController mobileController =
      PhoneController(PhoneNumber(nsn: '', isoCode: IsoCode.US));
  TextEditingController countryCodeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController _textEditingController = TextEditingController();

  String _selectedCountryCode = '+1';
  List<Companies> companyOptions = [];
  Timer? _debounce;

  // TextEditingController _textEditingController = TextEditingController();
  bool isLoading = false;

  // void onSearchChanged(String query, AuthNotifier authNotifier, Function setState) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //
  //   _debounce = Timer(Duration(milliseconds: 300), () async {
  //     await authNotifier.fetchCompanies(query);
  //     setState(() {}); // Force UI to refresh and show results
  //   });
  // }
  // ✅ Updated search handler with null safety
  void onSearchChanged(String query, AuthNotifier authNotifier) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(milliseconds: 300), () {
      authNotifier.fetchCompanies(query);
      setState(() {}); // Trigger UI update when new options are fetched
    });
  }

  // Future<void> fetchCompanies(String name, AuthNotifier authNotifier) async {
  //   if (name.isEmpty) {
  //     // setState(() {
  //       companyOptions = [];
  //     // });
  //
  //     return;
  //   }
  //
  //   // setState(() {
  //     isLoading = true; // Show loading indicator
  //   // });
  //
  //   List<Companies> fetchedCompanies = await authNotifier.fetchCompanies(name);
  //
  //   // setState(() {
  //     companyOptions = fetchedCompanies;
  //     isLoading = false;
  //
  //     // Hide loading indicator
  //   // });
  // }

  List<Categories> _selectedRoles = [];

  String verifyResult = "";
  bool isCaptchaVerified = false;

  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();

  /// Corporate account UI
  TextEditingController companyLegalNameController = TextEditingController();
  TextEditingController companyTypeController = TextEditingController();
  TextEditingController companyDisplayNameController = TextEditingController();
  TextEditingController adminNameController = TextEditingController();
  TextEditingController adminEmailController = TextEditingController();
  TextEditingController adminMobileController = TextEditingController();
  TextEditingController adminPasswordController = TextEditingController();
  TextEditingController adminConfirmPasswordController =
      TextEditingController();
  dynamic? selectedCompanyType;
  String? selectedCompanyType1 = "";
  String? selectedCompanyId = ""; // <-- This will store company ID
  String? selectedCompanyTypeId;

  Roles? selectedCompanyRole;
  bool _showRoles = true;
  bool _showCompanyType = true;
  bool _enableCompanyTypeDropdown = true;
  bool _customRoles = false;
  bool _enableCountryDropdown = true;
  Companies? selectedCompany;
  String companyName = '';
  String companyId = "";

  String _selectedAdminCountryCode = '+1';

  //bool isNewUser = false;

  String _corporateAdminHintText = '+1 (XXX) XXX-XXXX';
  String _selectedAdminCorporateCountry = 'US';
  String _selectedCorporateCountryName = 'United States';

  String _individualHintText = '(XXX) XXX-XXXX';
  String _selectedIndividualCountry = 'US';

  bool _showPasswordIndividual = false;
  bool _showPasswordConfirmationIndividual = false;
  bool _showPasswordConfirmationCorporate = false;

  bool _showPasswordCorporate = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();

    _selectedOption = SignUpOptions.individual;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.email != null && widget.email!.isNotEmpty) {
        emailController.text = widget.email!;
        setState(() {}); // ensure UI refresh
      }
    });

    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    Future.wait([
      authNotifier.fetchIndividualRoles(),
      authNotifier.fetchCompanies(""),
    ]);

    _updateHintText();
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _selectedOption = SignUpOptions.individual;
  //
  //   emailController.text = widget.email ?? "";
  //
  //   // Call APIs as soon as possible with a single Provider instance
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
  //
  //     // Run both API calls in parallel to reduce total time
  //     Future.wait([
  //       authNotifier.fetchIndividualRoles(),
  //       authNotifier.fetchCompanies(""),
  //     ]);
  //   });
  //
  //   _updateHintText();
  // }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _selectedOption = SignUpOptions.individual;
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
  //     authNotifier.fetchCompanies("");
  //   });
  //   Future.microtask(() {
  //     Provider.of<AuthNotifier>(context, listen: false).fetchIndividualRoles();
  //   });
  //
  //   _updateHintText();
  // }

  @override
  void dispose() {
    nameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    countryCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _textEditingController.dispose();
    companyLegalNameController.dispose();
    companyTypeController.dispose();
    companyDisplayNameController.dispose();
    adminEmailController.dispose();
    adminMobileController.dispose();
    adminPasswordController.dispose();
    adminNameController.dispose();
    adminConfirmPasswordController.dispose();
    recaptchaV2Controller.dispose();
    Provider.of<AuthNotifier>(context, listen: false).isNewUser = false;
    // Provider.of<AuthNotifier>(context, listen: false).signOut();
    super.dispose();
  }

  void _updateHintText() {
    setState(() {
      print('Selected Corporate Country: $_selectedAdminCorporateCountry');
      print('Selected Individual Country: $_selectedIndividualCountry');
      _corporateAdminHintText =
          countryPlaceholders[_selectedAdminCorporateCountry] ?? '';
      _individualHintText =
          countryPlaceholders[_selectedIndividualCountry] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child:
                Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
              return Column(
                children: [
                  Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Image.asset(
                              'assets/images/loginImage.png',
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: Center(
                            child: Text(
                          "Set up your account",
                          // LanguageService.getTranslated(
                          //     context, "login_image_text"),
                          style: typography.H5_Regular,
                        )),
                      ),
                    ],
                  ),
                  authNotifier.isNewUser
                      ? _almostThereForm()
                      // Create Account Form
                      : _createAccountForm(),
                  // Create Account Button
                  //SizedBox(height: CustomSpacing.four),

                  /*Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RecaptchaV2(
                              apiKey: Constants.recaptchaKey,
                              apiSecret: Constants.recaptchaSecret,
                              controller: recaptchaV2Controller,
                              onVerifiedError: (err) {
                                print(err);
                                isCaptchaVerified = false;
                              },
                              onVerifiedSuccessfully: (success) {
                                setState(() {
                                  if (success) {
                                    verifyResult = "You've been verified successfully.";
                                    isCaptchaVerified = true;
                                    Future.delayed(Duration(minutes: 1), () {
                                      isCaptchaVerified = false;
                                    });
                                  } else {
                                    verifyResult = "Failed to verify.";
                                    isCaptchaVerified = false;
                                  }
                                  print(verifyResult);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),*/
                  SizedBox(height: CustomSpacing.three),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _termsAccepted = value!;
                                });
                              },
                            ),
                            Text("I accept the "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TermsPage(
                                      title: 'Terms & conditions',
                                      url:
                                          'https://www.risksphere.ai/terms-and-conditions/', // replace with your actual URL
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Terms & conditions",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _privacyAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _privacyAccepted = value!;
                                });
                              },
                            ),
                            Text("I accept the "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TermsPage(
                                      title: 'Privacy Policy',
                                      url:
                                          'https://www.risksphere.ai/privacy-policy/', // replace with your actual URL
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Privacy Policy",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: CustomSpacing.three),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: authNotifier.isSigningUp
                              ? Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 8),
                                  ),

                                  onPressed: () async {
                                    // ✅ CHECK 1: Terms and conditions
                                    if (!_termsAccepted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please accept the Terms & Conditions.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ CHECK 2: Privacy policy
                                    if (!_privacyAccepted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please accept the Privacy Policy.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ CHECK 3: Validate form fields
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }

                                    if (_selectedRoles.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Please select at least one role to continue.',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return; // 🔥 STOP HERE - DO NOT PROCEED
                                    }

                                    // ✅ ALL VALIDATIONS PASSED - NOW PROCEED WITH SIGNUP
                                    if (authNotifier.isNewUser) {
                                      String result = await authNotifier
                                          .signUpIndividualWithGoogle(
                                        widget.userCredential!,
                                        mobileController.value?.nsn ?? "",
                                        mobileController.value?.countryCode ??
                                            "",
                                        _selectedRoles,
                                        context,
                                      );
                                      if (result == 'role_assigned') {
                                        final _googleSignIn = GoogleSignIn();
                                        var isSignedIn =
                                            await _googleSignIn.isSignedIn();
                                        if (isSignedIn)
                                          await _googleSignIn.disconnect();
                                        FirebaseAuth.instance.signOut();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "register_non_corporate_success_status_title"),
                                                style: typography.ButtonLarge,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                LoginScreen()));
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.arrow_back),
                                                      SizedBox(
                                                          width: CustomSpacing
                                                              .four),
                                                      Text('Back to Login'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } else if (widget.user == "apple") {
                                      String result = await authNotifier
                                          .signUpIndividualWithApple(
                                        emailController.text,
                                        passwordController.text,
                                        nameController.text,
                                        displayNameController.text,
                                        mobileController.value?.nsn ?? "",
                                        mobileController.value?.countryCode ??
                                            "",
                                        _selectedRoles,
                                        widget.userCredential!,
                                        context,
                                      );
                                      if (result == 'role_assigned') {
                                        final _googleSignIn = GoogleSignIn();
                                        var isSignedIn =
                                            await _googleSignIn.isSignedIn();
                                        if (isSignedIn)
                                          await _googleSignIn.disconnect();
                                        FirebaseAuth.instance.signOut();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "register_non_corporate_success_status_title"),
                                                style: typography.ButtonLarge,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                LoginScreen()));
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.arrow_back),
                                                      SizedBox(
                                                          width: CustomSpacing
                                                              .four),
                                                      Text('Back to Login'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } else if (_selectedOption ==
                                        SignUpOptions.individual) {
                                      if (_selectedCorporateCountryName
                                          .isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "usermanagement_app_corporate_create_company_country_invalid_error_text")),
                                          ),
                                        );
                                      }
                                      bool isApplicableForTrial = authNotifier
                                              .companyTypeList
                                              ?.where((companyType) =>
                                                  companyType.type
                                                      .toLowerCase() ==
                                                  'individual_account')
                                              .first
                                              .isApplicableForTrial ??
                                          false;
                                      int trialPeriodDays = authNotifier
                                              .companyTypeList
                                              ?.where((companyType) =>
                                                  companyType.type
                                                      .toLowerCase() ==
                                                  'individual_account')
                                              .first
                                              .trialPeriodDays ??
                                          0;
                                      authNotifier
                                          .signUpIndividualWithEmailAndPassword(
                                        emailController.text,
                                        passwordController.text,
                                        nameController.text,
                                        displayNameController.text,
                                        mobileController.value?.nsn ?? "",
                                        mobileController.value?.countryCode ??
                                            "",
                                        _selectedRoles,
                                        isApplicableForTrial,
                                        trialPeriodDays,
                                        context,
                                      );
                                    } else {
                                      bool isApplicableForTrial = authNotifier
                                              .companyTypeList
                                              ?.where((companyType) =>
                                                  companyType.id ==
                                                  selectedCompanyType?.id)
                                              .first
                                              .isApplicableForTrial ??
                                          true;
                                      int trialPeriodDays = authNotifier
                                              .companyTypeList
                                              ?.where((companyType) =>
                                                  companyType.id ==
                                                  selectedCompanyType?.id)
                                              .first
                                              .trialPeriodDays ??
                                          7;

                                      authNotifier
                                          .signUpCorporateWithEmailAndPassword(
                                        selectedCompanyId,
                                        companyName.trim(),
                                        selectedCompanyType1!,
                                        companyDisplayNameController.text
                                            .trim(),
                                        adminNameController.text.trim(),
                                        adminEmailController.text.trim(),
                                        "+${mobileController.value?.countryCode ?? ""}",
                                        mobileController.value?.nsn ?? "",
                                        adminPasswordController.text.trim(),
                                        selectedCompanyRole,
                                        context,
                                        selectedCompany,
                                        isApplicableForTrial,
                                        trialPeriodDays,
                                        _selectedCorporateCountryName,
                                        selectedCompanyTypeId,
                                      );
                                    }
                                  },
                                  // onPressed: () async {
                                  //   if (!_termsAccepted) {
                                  //     ScaffoldMessenger.of(context)
                                  //         .showSnackBar(
                                  //       SnackBar(
                                  //         content: Text(
                                  //             'Please accept the Terms & Conditions.'),
                                  //       ),
                                  //     );
                                  //     return;
                                  //   }
                                  //
                                  //   if (!_privacyAccepted) {
                                  //     ScaffoldMessenger.of(context)
                                  //         .showSnackBar(
                                  //       SnackBar(
                                  //         content: Text(
                                  //             'Please accept the Privacy Policy.'),
                                  //       ),
                                  //     );
                                  //     return;
                                  //   }
                                  //
                                  //   if (_formKey.currentState!.validate()) {
                                  //     if (authNotifier.isNewUser) {
                                  //       String result = await authNotifier
                                  //           .signUpIndividualWithGoogle(
                                  //         widget.userCredential!,
                                  //         mobileController.value?.nsn ?? "",
                                  //         mobileController.value?.countryCode ??
                                  //             "",
                                  //         _selectedRoles,
                                  //         context,
                                  //       );
                                  //       if (result == 'role_assigned') {
                                  //         final _googleSignIn = GoogleSignIn();
                                  //         var isSignedIn =
                                  //             await _googleSignIn.isSignedIn();
                                  //         if (isSignedIn)
                                  //           await _googleSignIn.disconnect();
                                  //         FirebaseAuth.instance.signOut();
                                  //         showDialog(
                                  //           context: context,
                                  //           builder: (BuildContext context) {
                                  //             return AlertDialog(
                                  //               title: Text(
                                  //                 LanguageService.getTranslated(
                                  //                     context,
                                  //                     "register_non_corporate_success_status_title"),
                                  //                 style: typography.ButtonLarge,
                                  //               ),
                                  //               actions: [
                                  //                 TextButton(
                                  //                   onPressed: () {
                                  //                     Navigator.pushReplacement(
                                  //                         context,
                                  //                         MaterialPageRoute(
                                  //                             builder: (context) =>
                                  //                                 LoginScreen()));
                                  //                   },
                                  //                   child: Row(
                                  //                     children: [
                                  //                       Icon(Icons.arrow_back),
                                  //                       SizedBox(
                                  //                           width: CustomSpacing
                                  //                               .four),
                                  //                       Text('Back to Login'),
                                  //                     ],
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             );
                                  //           },
                                  //         );
                                  //       }
                                  //     } else if (widget.user == "apple") {
                                  //       String result = await authNotifier
                                  //           .signUpIndividualWithApple(
                                  //         emailController.text,
                                  //         passwordController.text,
                                  //         nameController.text,
                                  //         displayNameController.text,
                                  //         mobileController.value?.nsn ?? "",
                                  //         mobileController.value?.countryCode ??
                                  //             "",
                                  //         _selectedRoles,
                                  //         widget.userCredential!,
                                  //         context,
                                  //       );
                                  //       if (result == 'role_assigned') {
                                  //         final _googleSignIn = GoogleSignIn();
                                  //         var isSignedIn =
                                  //             await _googleSignIn.isSignedIn();
                                  //         if (isSignedIn)
                                  //           await _googleSignIn.disconnect();
                                  //         FirebaseAuth.instance.signOut();
                                  //         showDialog(
                                  //           context: context,
                                  //           builder: (BuildContext context) {
                                  //             return AlertDialog(
                                  //               title: Text(
                                  //                 LanguageService.getTranslated(
                                  //                     context,
                                  //                     "register_non_corporate_success_status_title"),
                                  //                 style: typography.ButtonLarge,
                                  //               ),
                                  //               actions: [
                                  //                 TextButton(
                                  //                   onPressed: () {
                                  //                     Navigator.pushReplacement(
                                  //                         context,
                                  //                         MaterialPageRoute(
                                  //                             builder: (context) =>
                                  //                                 LoginScreen()));
                                  //                   },
                                  //                   child: Row(
                                  //                     children: [
                                  //                       Icon(Icons.arrow_back),
                                  //                       SizedBox(
                                  //                           width: CustomSpacing
                                  //                               .four),
                                  //                       Text('Back to Login'),
                                  //                     ],
                                  //                   ),
                                  //                 ),
                                  //               ],
                                  //             );
                                  //           },
                                  //         );
                                  //       }
                                  //     } else if (_selectedOption ==
                                  //         SignUpOptions.individual) {
                                  //       if (_selectedCorporateCountryName
                                  //           .isEmpty) {
                                  //         ScaffoldMessenger.of(context)
                                  //             .showSnackBar(
                                  //           SnackBar(
                                  //             content: Text(
                                  //                 LanguageService.getTranslated(
                                  //                     context,
                                  //                     "usermanagement_app_corporate_create_company_country_invalid_error_text")),
                                  //           ),
                                  //         );
                                  //       }
                                  //       bool isApplicableForTrial = authNotifier
                                  //               .companyTypeList
                                  //               ?.where((companyType) =>
                                  //                   companyType.type
                                  //                       .toLowerCase() ==
                                  //                   'individual_account')
                                  //               .first
                                  //               .isApplicableForTrial ??
                                  //           false;
                                  //       int trialPeriodDays = authNotifier
                                  //               .companyTypeList
                                  //               ?.where((companyType) =>
                                  //                   companyType.type
                                  //                       .toLowerCase() ==
                                  //                   'individual_account')
                                  //               .first
                                  //               .trialPeriodDays ??
                                  //           0;
                                  //       authNotifier
                                  //           .signUpIndividualWithEmailAndPassword(
                                  //         emailController.text,
                                  //         passwordController.text,
                                  //         nameController.text,
                                  //         displayNameController.text,
                                  //         mobileController.value?.nsn ?? "",
                                  //         mobileController.value?.countryCode ??
                                  //             "",
                                  //         _selectedRoles,
                                  //         isApplicableForTrial,
                                  //         trialPeriodDays,
                                  //         context,
                                  //       );
                                  //     } else {
                                  //       bool isApplicableForTrial = authNotifier
                                  //               .companyTypeList
                                  //               ?.where((companyType) =>
                                  //                   companyType.id ==
                                  //                   selectedCompanyType?.id)
                                  //               .first
                                  //               .isApplicableForTrial ??
                                  //           true;
                                  //       int trialPeriodDays = authNotifier
                                  //               .companyTypeList
                                  //               ?.where((companyType) =>
                                  //                   companyType.id ==
                                  //                   selectedCompanyType?.id)
                                  //               .first
                                  //               .trialPeriodDays ??
                                  //           7;
                                  //
                                  //       authNotifier
                                  //           .signUpCorporateWithEmailAndPassword(
                                  //         selectedCompanyId,
                                  //         companyName.trim(),
                                  //         selectedCompanyType1!,
                                  //         companyDisplayNameController.text
                                  //             .trim(),
                                  //         adminNameController.text.trim(),
                                  //         adminEmailController.text.trim(),
                                  //         "+${mobileController.value?.countryCode ?? ""}",
                                  //         mobileController.value?.nsn ?? "",
                                  //         adminPasswordController.text.trim(),
                                  //         selectedCompanyRole,
                                  //         context,
                                  //         selectedCompany,
                                  //         isApplicableForTrial,
                                  //         trialPeriodDays,
                                  //         _selectedCorporateCountryName,
                                  //         selectedCompanyTypeId,
                                  //       );
                                  //     }
                                  //   }
                                  // },
                                  child: _selectedOption ==
                                          SignUpOptions.individual
                                      ? Text(
                                          (authNotifier.companyTypeList ?? [])
                                                  .any((companyType) {
                                            return companyType.type
                                                        .toLowerCase() ==
                                                    'individual_account' &&
                                                companyType
                                                    .isApplicableForTrial;
                                          })
                                              ? Platform.isIOS
                                                  ? "Register"
                                                  : "Start your"
                                                      " ${(authNotifier.companyTypeList ?? []).where((companyType) {
                                                      log("Processing companyType for trial days: ${companyType.type}");
                                                      return companyType.type
                                                                  .toLowerCase() ==
                                                              'individual_account' &&
                                                          companyType
                                                              .isApplicableForTrial;
                                                    }).map((companyType) {
                                                      log("Free trial days: ${companyType.trialPeriodDays}");
                                                      return companyType
                                                          .trialPeriodDays;
                                                    }).first}-day free trial"
                                              : LanguageService.getTranslated(
                                                  context,
                                                  "usermanagement_cuser_create_account_btn"),
                                          style:
                                              typography.ButtonLarge.copyWith(
                                                  color: Colors.black),
                                        )
                                      : Text(
                                          (authNotifier.companyTypeList ?? [])
                                                  .any((companyType) {
                                            return companyType.id ==
                                                    selectedCompanyType?.id &&
                                                companyType
                                                    .isApplicableForTrial;
                                          })
                                              ? "Start your ${(authNotifier.companyTypeList ?? []).where((companyType) {
                                                  return companyType.id ==
                                                          selectedCompanyType
                                                              ?.id &&
                                                      companyType
                                                          .isApplicableForTrial;
                                                }).map((companyType) {
                                                  log("Selected Free trial days: ${companyType.trialPeriodDays}");
                                                  return companyType
                                                      .trialPeriodDays;
                                                }).first}-day free trial"
                                              : LanguageService.getTranslated(
                                                  context,
                                                  "usermanagement_cuser_create_account_btn"),
                                          style:
                                              typography.ButtonLarge.copyWith(
                                                  color: Colors.black),
                                        ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  _createAccountForm() {
    var typography = CustomTypography(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Create your personal account",
              // _selectedOption == SignUpOptions.individual
              //     ? LanguageService.getTranslated(context,
              //     "register_non_corporate_create_user_account_title")
              //     : LanguageService.getTranslated(
              //     context, "register_corporate_create_corporate_act_title"),
              style: typography.H5_Regular.copyWith(
                  color: Theme.of(context).colorScheme.onBackground),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: CustomSpacing.eight),
          // In your _createAccountForm() method, update the radio buttons section:
          if (Platform.isAndroid)
            Row(
              children: [
                Expanded(
                  child: Container(
                    // decoration: BoxDecoration(
                    //   border: Border.all(
                    //     color: _selectedOption == SignUpOptions.individual
                    //         ? AppColors.primaryMain
                    //         : Colors.grey,
                    //     width: 2,
                    //   ),
                    //   borderRadius: BorderRadius.circular(8),
                    // ),
                    child: RadioListTile<SignUpOptions>(
                      tileColor: _selectedOption == SignUpOptions.individual
                          ? AppColors.primaryMain.withOpacity(0.1)
                          : Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        LanguageService.getTranslated(
                            context, "register_non_corporate_radio_Individual"),
                        style: TextStyle(
                          fontWeight:
                              _selectedOption == SignUpOptions.individual
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      value: SignUpOptions.individual,
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _clearIndividualForm();
                          _resetRoles();
                          emailController.text = widget.email ?? '';
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Platform.isAndroid
                    ? Expanded(
                        child: Container(
                          // decoration: BoxDecoration(
                          //   border: Border.all(
                          //     color: _selectedOption == SignUpOptions.corporate
                          //         ? AppColors.primaryMain
                          //         : Colors.grey,
                          //     width: 2,
                          //   ),
                          //   borderRadius: BorderRadius.circular(8),
                          // ),
                          child: RadioListTile<SignUpOptions>(
                            tileColor:
                                _selectedOption == SignUpOptions.corporate
                                    ? AppColors.primaryMain.withOpacity(0.1)
                                    : Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              LanguageService.getTranslated(context,
                                  "register_non_corporate_radio_Corporate"),
                              style: TextStyle(
                                fontWeight:
                                    _selectedOption == SignUpOptions.corporate
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            value: SignUpOptions.corporate,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                                _clearCorporateForm();
                                _resetRoles();
                                adminEmailController.text = widget.email ?? '';
                              });
                            },
                          ),
                        ),
                      )
                    : SizedBox(),
              ],
            ),

          SizedBox(height: CustomSpacing.four),
          _selectedOption == SignUpOptions.individual
              ? _individualAccountUI()
              : _corporateAccountUI(),
        ],
      ),
    );
  }

// Add these methods to your State class

  void _clearIndividualForm() {
    nameController.clear();
    displayNameController.clear();
    // emailController.clear();
    mobileController =
        PhoneController(PhoneNumber(nsn: '', isoCode: IsoCode.US));
    passwordController.clear();
    confirmPasswordController.clear();
    _selectedRoles = [];
    _textEditingController.clear();
  }

  void _clearCorporateForm() {
    companyLegalNameController.clear();
    companyTypeController.clear();
    companyDisplayNameController.clear();
    adminNameController.clear();
    // adminEmailController.clear();
    adminMobileController.clear();
    adminPasswordController.clear();
    adminConfirmPasswordController.clear();
    selectedCompanyType = null;
    selectedCompanyType1 = "";
    selectedCompanyRole = null;
    selectedCompany = null;
    companyName = '';
    companyId = "";
    _selectedRoles = [];
    _textEditingController.clear();

    // Reset manual entry mode
    isManualEntry = false;
    selectedManualCompanyType = null;
    selectedManualRole = null;
    selectedAdminDropDownRole = null;
    showAdminDropdown = false;
    _enableCompanyTypeDropdown = true;
  }

  void _resetRoles() {
    setState(() {
      _selectedRoles.clear();
      _textEditingController.clear();
    });
  }

  _almostThereForm() {
    var typography = CustomTypography(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              _selectedOption == SignUpOptions.individual
                  ? 'Almost there! Please complete your account setup.'
                  : 'Do you want to create a corporate account?',
              style: typography.H5_Regular.copyWith(
                  color: Theme.of(context).colorScheme.onBackground),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: CustomSpacing.eight),
          _signUpAdditionFields(),
        ],
      ),
    );
  }

  _individualAccountUI() {
    var typography = CustomTypography(context);
    bool _rolesBottomSheetOpen = false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Social Media Buttons
        // if (Platform.isIOS)
        // Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
        //   return SocialMediaButton(
        //     onPressed: () async {
        //       try {
        //         await authNotifier.signInWithGoogle(c);
        //
        //         if (authNotifier.user != null) {
        //           // Fetch user data only if user exists
        //           Provider.of<UserProfileProvider>(context, listen: false)
        //               .getAllUserData(context, '', '');
        //
        //           // Navigate to Dashboard if not a new user
        //           if (!authNotifier.isNewUser) {
        //             Navigator.pushReplacement(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (context) => DashboardScreen(),
        //               ),
        //             );
        //           }
        //         } else {
        //           // Handle sign-in failure
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             SnackBar(
        //                 content:
        //                     Text("Google sign-in failed. Please try again.")),
        //           );
        //         }
        //       } catch (e) {
        //         // Catch any errors during sign-in
        //         debugPrint("Error during Google sign-in: $e");
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //               content: Text("An error occurred. Please try again.")),
        //         );
        //       }
        //     },
        //     buttonText:
        //         LanguageService.getTranslated(context, "login_googlebutton"),
        //     iconPath: 'assets/images/googleLogo.svg',
        //   );
        // }),
        SizedBox(height: CustomSpacing.eight),
        AppleSignInButton(),
        SizedBox(height: CustomSpacing.two),
        Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
          return SocialMediaButton(
            onPressed: () async {
              try {
                await authNotifier.signInWithGoogle(context: context);

                if (authNotifier.user != null) {
                  // Fetch user data only if user exists
                  Provider.of<UserProfileProvider>(context, listen: false)
                      .getAllUserData(context, '', '');

                  // Navigate to Dashboard if not a new user
                  if (!authNotifier.isNewUser) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                    );
                  }
                } else {
                  // Handle sign-in failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Google sign-in failed. Please try again.")),
                  );
                }
              } catch (e) {
                // Catch any errors during sign-in
                debugPrint("Error during Google sign-in: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("An error occurred. Please try again.")),
                );
              }
            },
            buttonText:
                LanguageService.getTranslated(context, "login_googlebutton"),
            iconPath: 'assets/images/googleLogo.svg',
          );
        }),
        SizedBox(
          height: CustomSpacing.one,
        ),
        // if (Platform.isAndroid)
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return SocialMediaButton(
              onPressed: () async {
                await authNotifier.signInWithMicrosoft(context: context);
                print(authNotifier.user.toString());
                print(authNotifier.userProfile.toString());
                print(authNotifier.isNewUser.toString());
              },
              buttonText: LanguageService.getTranslated(
                  context, "login_microsoft_button"),
              iconPath: 'assets/images/microsoftLogo.svg',
            );
          },
        ),

        // if (Platform.isIOS)
        // Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
        //   return authNotifier.isRemindLoading
        //       ? Center(
        //           child:
        //               Container(child: CircularProgressIndicator()), // loader
        //         )
        //       : SocialMediaButton(
        //           onPressed: () async {
        //             await authNotifier.signInWithMicrosoft(context);
        //           },
        //           buttonText: LanguageService.getTranslated(
        //               context, "login_microsoft_button"),
        //           iconPath: 'assets/images/microsoftLogo.svg',
        //         );
        // }),
        SizedBox(height: CustomSpacing.four),
        if (Platform.isAndroid) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
              SizedBox(width: CustomSpacing.three),
              Text(
                LanguageService.getTranslated(
                    context, "register_non_corporate_register_manually"),
                style: typography.Subtitle1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(width: CustomSpacing.three),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.eight),
        ],
        // Name
        if (widget.user != "apple") ...[
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LanguageService.getTranslated(context,
                          "user_profile_user_management_name_filed_label"), // Label text, // Black color for "Name"
                    ),
                    WidgetSpan(
                      child: Text(
                        " *",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      alignment: PlaceholderAlignment
                          .bottom, // Center aligns the asterisk
                    ),
                  ],
                ),
              ),
              hintText: LanguageService.getTranslated(
                  context, "user_profile_user_management_name_placeholder"),
              hintStyle: typography.Body1,
              labelStyle: typography.Body1,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  value.contains(RegExp(r'[0-9]'))) {
                return 'Name is required';
              }
              // You can add more specific email validation here if needed
              return null;
            },
            controller: nameController,
          ),
          SizedBox(height: CustomSpacing.four),
          // Display Name
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              // labelText: LanguageService.getTranslated(
              //     context, "usermanagement_display_name_field_label"),
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      // Display Name(Optional)
                      text: LanguageService.getTranslated(context,
                          "register_corporate_company_displayname_field_label"), // Label text, // Black color for "Name"
                    ),
                    WidgetSpan(
                      child: Text(
                        " *",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      alignment: PlaceholderAlignment
                          .bottom, // Center aligns the asterisk
                    ),
                  ],
                ),
              ),
              hintText: LanguageService.getTranslated(
                  context, "usermanagement_display_name_field_label"),
              hintStyle: typography.Body1,
              labelStyle: typography.Body1,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  value.startsWith(RegExp(r'[0-9]')) ||
                  value.contains(RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%0-9]'))) {
                return 'Display name is required';
              }
              // You can add more specific email validation here if needed
              return null;
            },
            controller: displayNameController,
          ),
          SizedBox(height: CustomSpacing.four),
          // Email
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              // labelText: LanguageService.getTranslated(
              //     context, "register_non_corporate_emailfield_label"),
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LanguageService.getTranslated(context,
                          "register_non_corporate_emailfield_label"), // Label text, // Black color for "Name"
                    ),
                    WidgetSpan(
                      child: Text(
                        " *",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      alignment: PlaceholderAlignment
                          .bottom, // Center aligns the asterisk
                    ),
                  ],
                ),
              ),
              hintText: LanguageService.getTranslated(
                  context, "register_non_corporate_emailfield_placeholder"),
              hintStyle: typography.Body1,
              labelStyle: typography.Body1,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || regextest(value) == false) {
                return 'Enter a valid email address';
              }
              return null;
            },
            controller: emailController,
            readOnly: widget.email != null && widget.email!.isNotEmpty,
          ),
        ],
        SizedBox(height: CustomSpacing.four),
        // mobile (optional)
        Row(
          children: [
            Expanded(
              child: FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (mobileController.value!.nsn.isEmpty) {
                    return 'Mobile number is required.';
                  }
                  if (mobileController.value!.nsn.length < 10) {
                    return 'Enter a valid mobile number.';
                  }
                  return null;
                },
                builder: (FormFieldState<String> fieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhoneInput(
                        key: const Key('phone-field'),
                        controller: mobileController,
                        shouldFormat: true,
                        defaultCountry: IsoCode.US,
                        decoration: InputDecoration(
                          label: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: LanguageService.getTranslated(
                                    context,
                                    "register_mobile_number",
                                  ),
                                ),
                                TextSpan(
                                  text: " *",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          hintText: _individualHintText,
                          border: const OutlineInputBorder(),
                          counterText: '',
                          errorText:
                              fieldState.errorText, // Show validation error
                        ),
                        countrySelectorNavigator:
                            CountrySelectorNavigator.dialog(
                          showSearchInput: true,
                          searchInputDecoration: const InputDecoration(
                            hintText: 'Search Country',
                          ),
                        ),
                        showFlagInInput: true,
                        flagShape: BoxShape.circle,
                        flagSize: 35,
                        onChanged: (PhoneNumber? p) {
                          if (p == null) return;
                          setState(() {
                            _selectedCountryCode = p.countryCode;
                            _selectedIndividualCountry = p.isoCode.name;
                            _updateHintText();
                          });
                          print('changed ${p.countryCode}');
                          fieldState.didChange(
                              mobileController.value!.nsn); // Notify validator
                        },
                        onSaved: (PhoneNumber? p) {
                          if (p == null) return;
                          setState(() {
                            _selectedCountryCode = p.countryCode;
                          });
                          print('changed ${p.countryCode}');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // Row(
        //   children: [
        //     Expanded(
        //       child: PhoneInput(
        //         key: const Key('phone-field'),
        //         controller: mobileController,
        //         shouldFormat: true,
        //         defaultCountry: IsoCode.US,
        //         decoration: InputDecoration(
        //           // labelText: LanguageService.getTranslated(
        //           //     context, "register_mobile_number"),
        //           label: RichText(
        //             text: TextSpan(
        //               children: [
        //                 TextSpan(
        //                   text: LanguageService.getTranslated(context,
        //                       "register_mobile_number"), // Label text, // Black color for "Name"
        //                 ),
        //                 WidgetSpan(
        //                   child: Text(
        //                     " *",
        //                     style: TextStyle(
        //                       color: Colors.red,
        //                       fontSize: 16,
        //                       fontWeight: FontWeight.bold,
        //                     ),
        //                   ),
        //                   alignment: PlaceholderAlignment
        //                       .bottom, // Center aligns the asterisk
        //                 ),
        //               ],
        //             ),
        //           ),
        //           hintText: _individualHintText,
        //           border: const OutlineInputBorder(),
        //           counterText: '',
        //         ),
        //         countrySelectorNavigator: CountrySelectorNavigator.dialog(
        //           showSearchInput: true,
        //           searchInputDecoration: InputDecoration(
        //             hintText: 'Search Country',
        //           ),
        //         ),
        //         showFlagInInput: true,
        //         flagShape: BoxShape.circle,
        //         flagSize: 35,
        //         onChanged: (PhoneNumber? p) {
        //           if (p == null) return;
        //           setState(() {
        //             _selectedCountryCode = p.countryCode;
        //             _selectedIndividualCountry = p.isoCode.name;
        //             _updateHintText();
        //           });
        //           print('changed ${p.countryCode}');
        //         },
        //         onSaved: (PhoneNumber? p) {
        //           if (p == null) return;
        //           setState(() {
        //             _selectedCountryCode = p.countryCode;
        //           });
        //           print('changed ${p.countryCode}');
        //         },
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(height: CustomSpacing.four),
        // Password

        if (widget.user != "apple") ...[
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: _showPasswordIndividual
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _showPasswordIndividual = !_showPasswordIndividual;
                  });
                },
              ),
              // labelText: LanguageService.getTranslated(
              //     context, "register_non_corporate_passwordfield_label"),
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LanguageService.getTranslated(context,
                          "register_non_corporate_passwordfield_label"), // Label text, // Black color for "Name"
                    ),
                    WidgetSpan(
                      child: Text(
                        " *",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      alignment: PlaceholderAlignment
                          .bottom, // Center aligns the asterisk
                    ),
                  ],
                ),
              ),

              hintText: LanguageService.getTranslated(
                  context, "register_corporate_password_field_placeholder"),
              border: const OutlineInputBorder(),
            ),
            obscureText: !_showPasswordIndividual,
            validator: (value) {
              if (value == null || value.isEmpty || value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              // You can add more specific password validation here if needed
              return null;
            },
            controller: passwordController,
          ),
          SizedBox(height: CustomSpacing.four),

          // Confirm Password
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: _showPasswordConfirmationIndividual
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _showPasswordConfirmationIndividual =
                        !_showPasswordConfirmationIndividual;
                  });
                },
              ),
              // labelText: LanguageService.getTranslated(
              //     context, "register_corporate_confirm_password_field_label"),
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LanguageService.getTranslated(context,
                          "register_corporate_confirm_password_field_label"), // Label text, // Black color for "Name"
                    ),
                    WidgetSpan(
                      child: Text(
                        " *",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      alignment: PlaceholderAlignment
                          .bottom, // Center aligns the asterisk
                    ),
                  ],
                ),
              ),
              hintText: LanguageService.getTranslated(context,
                  "register_corporate_confirm_password_field_placeholder"),
              border: const OutlineInputBorder(),
            ),
            obscureText: !_showPasswordConfirmationIndividual,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            controller: confirmPasswordController,
          ),
        ],

        // TextFormField(       autovalidateMode: AutovalidateMode.onUserInteraction,
        //   decoration: InputDecoration(
        //     suffixIcon: IconButton(
        //       icon: _showPasswordConfirmationIndividual
        //           ? Icon(Icons.visibility)
        //           : Icon(Icons.visibility_off),
        //       onPressed: () {
        //         setState(() {
        //           _showPasswordConfirmationIndividual =
        //               !_showPasswordConfirmationIndividual;
        //         });
        //       },
        //     ),
        //     labelText: LanguageService.getTranslated(
        //         context, "register_corporate_confirm_password_field_label"),
        //     hintText: LanguageService.getTranslated(context,
        //         "register_corporate_confirm_password_field_placeholder"),
        //     border: const OutlineInputBorder(),
        //   ),
        //   obscureText: !_showPasswordConfirmationIndividual,
        //   validator: (value) {
        //     if (value == null || value.isEmpty || value.length < 8) {
        //       return 'Password must be at least 8 characters';
        //     }
        //     // You can add more specific password validation here if needed
        //     return null;
        //   },
        //   controller: confirmPasswordController,
        // ),
        SizedBox(height: CustomSpacing.four),
        Row(
          children: [
            Text(
              LanguageService.getTranslated(
                  context, "categorymanagement_category_role_field_label"),
              style: typography.Subtitle1.copyWith(
                  color: Theme.of(context).colorScheme.onBackground),
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: Colors.white.withOpacity(0.11999999731779099),
              ),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.four),
        // Text(context.read<AuthNotifier>().roles.length.toString()),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown(context),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedRoles.isEmpty
                            ? [
                                Text(
                                  "Select Roles",
                                  style: TextStyle(color: Colors.grey),
                                )
                              ]
                            : _selectedRoles
                                .map(
                                  (role) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Chip(
                                      label: Text(role.name ?? ""),
                                      onDeleted: () => _removeRole(role),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                  Icon(
                    _isDropdownOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stack(
        //   children: [
        //     TextField(
        //       readOnly: true,
        //       onTap: () {
        //         showModalBottomSheet(
        //           context: context,
        //           useSafeArea: true,
        //           isScrollControlled: true,
        //           builder: (BuildContext context) {
        //             return RolesBottomSheet(
        //               showCorporateSwitch: false,
        //               // options: roles,
        //               options: context.read<AuthNotifier>().roles,
        //               selectedRoles: _selectedRoles,
        //               addChip: _addChip,
        //               removeChip: _removeChip,
        //               removeAllChips: _removeAllChips,
        //               selectedOption:
        //                   _selectedOption ?? SignUpOptions.individual,
        //               onOptionChanged: (SignUpOptions option) {
        //                 setState(() {
        //                   _selectedOption = option;
        //                 });
        //               },
        //             );
        //           },
        //         );
        //       },
        //       controller: _textEditingController,
        //       onChanged: (value) {
        //         // Handle input changes
        //       },
        //       decoration: InputDecoration(
        //         labelText: LanguageService.getTranslated(
        //             context, "usermanagement_roles_label"),
        //         hintText: _selectedRoles.isEmpty
        //             ? LanguageService.getTranslated(
        //                 context, "usermanagement_cuser_roles_placeholder")
        //             : "",
        //         border: OutlineInputBorder(),
        //         suffixIcon: IconButton(
        //           icon: Icon(Icons.arrow_drop_down),
        //           onPressed: () {
        //             showModalBottomSheet(
        //               context: context,
        //               useSafeArea: true,
        //               isScrollControlled: true,
        //               builder: (BuildContext context) {
        //                 return RolesBottomSheet(
        //                   showCorporateSwitch: false,
        //                   // options: roles,
        //                   options: context.read<AuthNotifier>().roles,
        //                   selectedRoles: _selectedRoles,
        //                   addChip: _addChip,
        //                   removeChip: _removeChip,
        //                   removeAllChips: _removeAllChips,
        //                   selectedOption:
        //                       _selectedOption ?? SignUpOptions.individual,
        //                   onOptionChanged: (SignUpOptions signUpOptions) {
        //                     setState(() {
        //                       _selectedOption = signUpOptions;
        //                     });
        //                   },
        //                 );
        //               },
        //             );
        //           },
        //         ),
        //       ),
        //     ),
        //     Positioned(
        //       top: 4.0,
        //       left: 10.0,
        //       right: 10.0,
        //       child: Container(
        //         margin: const EdgeInsets.only(right: 32.0),
        //         child: SingleChildScrollView(
        //           scrollDirection: Axis.horizontal,
        //           child: Row(
        //             children: _selectedRoles
        //                 .map(
        //                   (value) => Padding(
        //                     padding: const EdgeInsets.only(right: 8.0),
        //                     child: Chip(
        //                       label: Text(value.name!),
        //                       deleteIcon: Icon(Icons.cancel),
        //                       onDeleted: () => _removeChip(value),
        //                     ),
        //                   ),
        //                 )
        //                 .toList(),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // Stack(
        //   children: [
        //     FormField<String>(
        //       validator: (value) {
        //         if (_selectedRoles.isEmpty) {
        //           return 'Please select at least one role.';
        //         }
        //         return null;
        //       },
        //       builder: (FormFieldState<String> fieldState) {
        //         return Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             TextField(
        //               readOnly: true,
        //               controller: TextEditingController(text: ""),
        //               onTap: () {
        //                 setState(() => _rolesBottomSheetOpen = true);
        //                 showModalBottomSheet(
        //                   context: context,
        //                   useSafeArea: true,
        //                   isScrollControlled: true,
        //                   builder: (BuildContext context) {
        //                     return RolesBottomSheet(
        //                       showCorporateSwitch: true,
        //                       options: context.read<AuthNotifier>().roles,
        //
        //                       // options: roles,
        //                       selectedRoles: _selectedRoles,
        //                       addChip: (role) {
        //                         setState(() {
        //                           _selectedRoles.add(role);
        //                           _textEditingController.text = _selectedRoles
        //                               .map((e) => e.name!)
        //                               .join(', ');
        //                           fieldState.didChange(role.name);
        //                         });
        //                       },
        //                       removeChip: (role) {
        //                         setState(() {
        //                           _selectedRoles.remove(role);
        //                           _textEditingController.text =
        //                               _selectedRoles.isEmpty
        //                                   ? ''
        //                                   : _selectedRoles
        //                                       .map((e) => e.name!)
        //                                       .join(', ');
        //                           fieldState.didChange(_selectedRoles.isEmpty
        //                               ? null
        //                               : role.name);
        //                         });
        //                       },
        //                       removeAllChips: () {
        //                         setState(() {
        //                           _selectedRoles.clear();
        //                           _textEditingController.clear();
        //                           fieldState.didChange(null);
        //                         });
        //                       },
        //                       selectedOption:
        //                           _selectedOption ?? SignUpOptions.individual,
        //                       onOptionChanged: (SignUpOptions option) {
        //                         setState(() {
        //                           _selectedOption = option;
        //                         });
        //                       },
        //                     );
        //                   },
        //                 );
        //                 setState(() => _rolesBottomSheetOpen = false);
        //               },
        //               decoration: InputDecoration(
        //                 label: _selectedRoles.isEmpty && !_rolesBottomSheetOpen
        //                     ? RichText(
        //                         text: TextSpan(
        //                           children: [
        //                             TextSpan(
        //                               text: LanguageService.getTranslated(
        //                                   context,
        //                                   "register_non_corporate_role_field_label"),
        //                             ),
        //                             TextSpan(
        //                               text: " *",
        //                               style: const TextStyle(
        //                                 color: Colors.red,
        //                                 fontSize: 16,
        //                                 fontWeight: FontWeight.bold,
        //                               ),
        //                             ),
        //                           ],
        //                         ),
        //                       )
        //                     : RichText(
        //                         text: TextSpan(
        //                           text: '',
        //                         ),
        //                       ),
        //                 hintText:
        //                     _selectedRoles.isEmpty && !_rolesBottomSheetOpen
        //                         ? 'Select Roles'
        //                         : "",
        //                 border: const OutlineInputBorder(),
        //                 errorText: fieldState.errorText,
        //                 suffixIcon: IconButton(
        //                   icon: const Icon(Icons.arrow_drop_down),
        //                   onPressed: () {
        //                     showModalBottomSheet(
        //                       context: context,
        //                       useSafeArea: true,
        //                       isScrollControlled: true,
        //                       builder: (BuildContext context) {
        //                         final auth = context.read<AuthNotifier>();
        //
        //                         return RolesBottomSheet(
        //                           showCorporateSwitch: true,
        //                           options: auth.roles,     // ✅ CORRECT
        //                           selectedRoles: _selectedRoles,
        //                                 addChip: (role) {
        //                                   setState(() {
        //                                     _selectedRoles.add(role);
        //                                     _textEditingController.text =
        //                                         _selectedRoles
        //                                             .map((e) => e.name!)
        //                                             .join(', ');
        //                                     fieldState.didChange(role.name);
        //                                   });
        //                                 },
        //                                 removeChip: (role) {
        //                                   setState(() {
        //                                     _selectedRoles.remove(role);
        //                                     _textEditingController.text =
        //                                         _selectedRoles.isEmpty
        //                                             ? ''
        //                                             : _selectedRoles
        //                                                 .map((e) => e.name!)
        //                                                 .join(', ');
        //                                     fieldState.didChange(
        //                                         _selectedRoles.isEmpty
        //                                             ? null
        //                                             : role.name);
        //                                   });
        //                                 },
        //                                 removeAllChips: () {
        //                                   setState(() {
        //                                     _selectedRoles.clear();
        //                                     _textEditingController.clear();
        //                                     fieldState.didChange(null);
        //                                   });
        //                                 },
        //                           selectedOption: _selectedOption ?? SignUpOptions.individual,
        //                                 onOptionChanged:
        //                                     (SignUpOptions signUpOptions) {
        //                                   setState(() {
        //                                     _selectedOption = signUpOptions;
        //                                   });
        //                                 },
        //                         );
        //                       },
        //                     );
        //
        //                     // showModalBottomSheet(
        //                     //   context: context,
        //                     //   useSafeArea: true,
        //                     //   isScrollControlled: true,
        //                     //   builder: (BuildContext context) {
        //                     //     return RolesBottomSheet(
        //                     //       showCorporateSwitch: true,
        //                     //       options: roles,
        //                     //       selectedRoles: _selectedRoles,
        //                     //       addChip: (role) {
        //                     //         setState(() {
        //                     //           _selectedRoles.add(role);
        //                     //           _textEditingController.text =
        //                     //               _selectedRoles
        //                     //                   .map((e) => e.name!)
        //                     //                   .join(', ');
        //                     //           fieldState.didChange(role.name);
        //                     //         });
        //                     //       },
        //                     //       removeChip: (role) {
        //                     //         setState(() {
        //                     //           _selectedRoles.remove(role);
        //                     //           _textEditingController.text =
        //                     //               _selectedRoles.isEmpty
        //                     //                   ? ''
        //                     //                   : _selectedRoles
        //                     //                       .map((e) => e.name!)
        //                     //                       .join(', ');
        //                     //           fieldState.didChange(
        //                     //               _selectedRoles.isEmpty
        //                     //                   ? null
        //                     //                   : role.name);
        //                     //         });
        //                     //       },
        //                     //       removeAllChips: () {
        //                     //         setState(() {
        //                     //           _selectedRoles.clear();
        //                     //           _textEditingController.clear();
        //                     //           fieldState.didChange(null);
        //                     //         });
        //                     //       },
        //                     //       selectedOption: _selectedOption ??
        //                     //           SignUpOptions.individual,
        //                     //       onOptionChanged:
        //                     //           (SignUpOptions signUpOptions) {
        //                     //         setState(() {
        //                     //           _selectedOption = signUpOptions;
        //                     //         });
        //                     //       },
        //                     //     );
        //                     //   },
        //                     // );
        //                   },
        //                 ),
        //                 prefixIcon: _selectedRoles.isNotEmpty
        //                     ? Container(
        //                         padding: EdgeInsets.only(right: 28, left: 5),
        //                         child: SingleChildScrollView(
        //                           scrollDirection: Axis.horizontal,
        //                           child: Row(
        //                             mainAxisSize: MainAxisSize.min,
        //                             children: _selectedRoles.map((role) {
        //                               return Container(
        //                                 margin: EdgeInsets.only(right: 5.0),
        //                                 padding: const EdgeInsets.only(
        //                                     right: 2.0, left: 2),
        //                                 child: Chip(
        //                                   label: Text(role.name!),
        //                                   deleteIcon: const Icon(Icons.cancel),
        //                                   onDeleted: () {
        //                                     setState(() {
        //                                       _selectedRoles.remove(role);
        //                                       _textEditingController.text =
        //                                           _selectedRoles.isEmpty
        //                                               ? ''
        //                                               : _selectedRoles
        //                                                   .map((e) => e.name!)
        //                                                   .join(', ');
        //                                       fieldState.didChange(
        //                                           _selectedRoles.isEmpty
        //                                               ? null
        //                                               : role.name);
        //                                     });
        //                                   },
        //                                 ),
        //                               );
        //                             }).toList(),
        //                           ),
        //                         ),
        //                       )
        //                     : null,
        //               ),
        //             ),
        //
        //             // TextField(
        //             //   readOnly: true,
        //             //   onTap: () {
        //             //     showModalBottomSheet(
        //             //       context: context,
        //             //       useSafeArea: true,
        //             //       isScrollControlled: true,
        //             //       builder: (BuildContext context) {
        //             //         return RolesBottomSheet(
        //             //           showCorporateSwitch: true,
        //             //           options: roles,
        //             //           selectedRoles: _selectedRoles,
        //             //           addChip: (role) {
        //             //             setState(() {
        //             //               _selectedRoles.add(role);
        //             //               _textEditingController.text =
        //             //                   _selectedRoles.map((e) => e.name!).join(', ');
        //             //               fieldState.didChange(role.name);
        //             //             });
        //             //           },
        //             //           removeChip: (role) {
        //             //             setState(() {
        //             //               _selectedRoles.remove(role);
        //             //               _textEditingController.text =
        //             //               _selectedRoles.isEmpty
        //             //                   ? ''
        //             //                   : _selectedRoles.map((e) => e.name!).join(', ');
        //             //               fieldState.didChange(_selectedRoles.isEmpty ? null : role.name);
        //             //             });
        //             //           },
        //             //           removeAllChips: () {
        //             //             setState(() {
        //             //               _selectedRoles.clear();
        //             //               _textEditingController.clear();
        //             //               fieldState.didChange(null);
        //             //             });
        //             //           },
        //             //           selectedOption: _selectedOption ?? SignUpOptions.individual,
        //             //           onOptionChanged: (SignUpOptions option) {
        //             //             setState(() {
        //             //               _selectedOption = option;
        //             //             });
        //             //           },
        //             //         );
        //             //       },
        //             //     );
        //             //   },
        //             //   controller: _textEditingController,
        //             //   decoration: InputDecoration(
        //             //     label: RichText(
        //             //       text: TextSpan(
        //             //         children: [
        //             //           TextSpan(
        //             //             text: LanguageService.getTranslated(
        //             //                 context, "register_non_corporate_role_field_label"),
        //             //           ),
        //             //           TextSpan(
        //             //             text: " *",
        //             //             style: const TextStyle(
        //             //               color: Colors.red,
        //             //               fontSize: 16,
        //             //               fontWeight: FontWeight.bold,
        //             //             ),
        //             //           ),
        //             //         ],
        //             //       ),
        //             //     ),
        //             //     hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
        //             //     border: const OutlineInputBorder(),
        //             //     errorText: fieldState.errorText,
        //             //     suffixIcon: IconButton(
        //             //       icon: const Icon(Icons.arrow_drop_down),
        //             //       onPressed: () {
        //             //         showModalBottomSheet(
        //             //           context: context,
        //             //           useSafeArea: true,
        //             //           isScrollControlled: true,
        //             //           builder: (BuildContext context) {
        //             //             return RolesBottomSheet(
        //             //               showCorporateSwitch: true,
        //             //               options: roles,
        //             //               selectedRoles: _selectedRoles,
        //             //               addChip: (role) {
        //             //                 setState(() {
        //             //                   _selectedRoles.add(role);
        //             //                   _textEditingController.text =
        //             //                       _selectedRoles.map((e) => e.name!).join(', ');
        //             //                   fieldState.didChange(role.name);
        //             //                 });
        //             //               },
        //             //               removeChip: (role) {
        //             //                 setState(() {
        //             //                   _selectedRoles.remove(role);
        //             //                   _textEditingController.text =
        //             //                   _selectedRoles.isEmpty
        //             //                       ? ''
        //             //                       : _selectedRoles.map((e) => e.name!).join(', ');
        //             //                   fieldState.didChange(
        //             //                       _selectedRoles.isEmpty ? null : role.name);
        //             //                 });
        //             //               },
        //             //               removeAllChips: () {
        //             //                 setState(() {
        //             //                   _selectedRoles.clear();
        //             //                   _textEditingController.clear();
        //             //                   fieldState.didChange(null);
        //             //                 });
        //             //               },
        //             //               selectedOption: _selectedOption ?? SignUpOptions.individual,
        //             //               onOptionChanged: (SignUpOptions signUpOptions) {
        //             //                 setState(() {
        //             //                   _selectedOption = signUpOptions;
        //             //                 });
        //             //               },
        //             //             );
        //             //           },
        //             //         );
        //             //       },
        //             //     ),
        //             //   ),
        //             // ),
        //             // Positioned(
        //             //   top: 12.0,
        //             //   left: 10.0,
        //             //   right: 50.0,
        //             //   child: Container(
        //             //     margin: const EdgeInsets.only(right: 8.0),
        //             //     child: SingleChildScrollView(
        //             //       scrollDirection: Axis.horizontal,
        //             //       child: Row(
        //             //         children: _selectedRoles
        //             //             .map(
        //             //               (value) => Padding(
        //             //             padding: const EdgeInsets.only(right: 8.0),
        //             //             child: Chip(
        //             //               label: Text(value.name!),
        //             //               deleteIcon: const Icon(Icons.cancel),
        //             //               onDeleted: () {
        //             //                 setState(() {
        //             //                   _selectedRoles.remove(value);
        //             //                   _textEditingController.text =
        //             //                   _selectedRoles.isEmpty
        //             //                       ? ''
        //             //                       : _selectedRoles.map((e) => e.name!).join(', ');
        //             //                   fieldState.didChange(
        //             //                       _selectedRoles.isEmpty ? null : value.name);
        //             //                 });
        //             //               },
        //             //             ),
        //             //           ),
        //             //         )
        //             //             .toList(),
        //             //       ),
        //             //     ),
        //             //   ),
        //             // ),
        //           ],
        //         );
        //       },
        //     ),
        //   ],
        // ),

        // Stack(
        //   children: [
        //     TextField(
        //       readOnly: true,
        //       onTap: () {
        //         showModalBottomSheet(
        //           context: context,
        //           useSafeArea: true,
        //           isScrollControlled: true,
        //           builder: (BuildContext context) {
        //             return RolesBottomSheet(
        //               showCorporateSwitch: true,
        //               options: roles,
        //               selectedRoles: _selectedRoles,
        //               addChip: _addChip,
        //               removeChip: _removeChip,
        //               removeAllChips: _removeAllChips,
        //               selectedOption:
        //                SignUpOptions.individual,
        //               onOptionChanged: (SignUpOptions option) {
        //                 setState(() {
        //                   _selectedOption = option;
        //                 });
        //               },
        //             );
        //           },
        //         );
        //       },
        //       controller: _textEditingController,
        //       onChanged: (value) {
        //         // Handle input changes
        //       },
        //       decoration: InputDecoration(
        //         // labelText: LanguageService.getTranslated(
        //         //     context, "register_non_corporate_role_field_label"),
        //         label: RichText(
        //           text: TextSpan(
        //             children: [
        //               TextSpan(
        //                 text: LanguageService.getTranslated(context,
        //                     "register_non_corporate_role_field_label"), // Label text, // Black color for "Name"
        //               ),
        //               WidgetSpan(
        //                 child: Text(
        //                   " *",
        //                   style: TextStyle(
        //                     color: Colors.red,
        //                     fontSize: 16,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                 ),
        //                 alignment: PlaceholderAlignment
        //                     .bottom, // Center aligns the asterisk
        //               ),
        //             ],
        //           ),
        //         ),
        //         hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
        //         border: OutlineInputBorder(),
        //         suffixIcon: IconButton(
        //           icon: Icon(Icons.arrow_drop_down),
        //           onPressed: () {
        //             showModalBottomSheet(
        //               context: context,
        //               useSafeArea: true,
        //               isScrollControlled: true,
        //               builder: (BuildContext context) {
        //                 return RolesBottomSheet(
        //                   showCorporateSwitch: true,
        //                   options: roles,
        //                   selectedRoles: _selectedRoles,
        //                   addChip: _addChip,
        //                   removeChip: _removeChip,
        //                   removeAllChips: _removeAllChips,
        //                   selectedOption:
        //                       _selectedOption ?? SignUpOptions.individual,
        //                   onOptionChanged: (SignUpOptions signUpOptions) {
        //                     setState(() {
        //                       _selectedOption = signUpOptions;
        //                     });
        //                   },
        //                 );
        //               },
        //             );
        //           },
        //         ),
        //       ),
        //     ),
        //     Positioned(
        //       top: 4.0,
        //       left: 10.0,
        //       right: 10.0,
        //       child: Container(
        //         margin: const EdgeInsets.only(right: 32.0),
        //         child: SingleChildScrollView(
        //           scrollDirection: Axis.horizontal,
        //           child: Row(
        //             children: _selectedRoles
        //                 .map(
        //                   (value) => Padding(
        //                     padding: const EdgeInsets.only(right: 8.0),
        //                     child: Chip(
        //                       label: Text(value.name!),
        //                       deleteIcon: Icon(Icons.cancel),
        //                       onDeleted: () => _removeChip(value),
        //                     ),
        //                   ),
        //                 )
        //                 .toList(),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  void _toggleDropdown(BuildContext context) {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown(context);
    }
  }

  void _openDropdown(BuildContext context) {
    final allRoles = context.read<AuthNotifier>().roles;

    // Filter only unselected roles
    final roles = allRoles.where((roleModel) {
      final role = Categories.fromJson(roleModel.toJson());
      return !_selectedRoles.any((r) => r.id == role.id);
    }).toList();

    if (roles.isEmpty) return;

    // 🔥 Dynamic height calculation
    double tileHeight = 50;
    double maxHeight = 250;
    double dropdownHeight = (roles.length * tileHeight).clamp(50, maxHeight);

    _dropdownOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 48,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 60),
            showWhenUnlinked: false,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: StatefulBuilder(
                builder: (context, overlaySetState) {
                  return Container(
                    height: dropdownHeight, // 🔥 DYNAMIC HEIGHT APPLIED
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: roles.map((roleModel) {
                        final role = Categories.fromJson(roleModel.toJson());

                        return ListTile(
                          title: Text(role.name ?? "",
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedRoles.add(role);
                            });

                            _closeDropdown();
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_dropdownOverlay!);
    setState(() => _isDropdownOpen = true);
  }

  void _closeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    setState(() => _isDropdownOpen = false);
  }

  void _openRolesDropdown(BuildContext context) {
    final roles = context.read<AuthNotifier>().roles;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Select Roles"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = Categories.fromJson(roles[index].toJson());
                final isSelected = _selectedRoles.any((r) => r.id == role.id);

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(role.name ?? ""),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRoles.add(role);
                      } else {
                        _selectedRoles.removeWhere((r) => r.id == role.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _removeRole(Categories role) {
    setState(() {
      _selectedRoles.removeWhere((r) => r.id == role.id);
    });
  }

  _signUpAdditionFields() {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // mobile (optional)
        Row(
          children: [
            Expanded(
              child: PhoneInput(
                key: const Key('phone-field'),
                controller: mobileController,
                shouldFormat: true,
                defaultCountry: IsoCode.US,
                decoration: InputDecoration(
                  // labelText: LanguageService.getTranslated(
                  //     context, "register_mobile_number"),
                  label: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: LanguageService.getTranslated(context,
                              "register_mobile_number"), // Label text, // Black color for "Name"
                        ),
                        WidgetSpan(
                          child: Text(
                            " *",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          alignment: PlaceholderAlignment
                              .bottom, // Center aligns the asterisk
                        ),
                      ],
                    ),
                  ),
                  hintText: LanguageService.getTranslated(context,
                      "register_non_corporate_mobilefield_placeholder"),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                countrySelectorNavigator: CountrySelectorNavigator.dialog(
                  showSearchInput: true,
                  searchInputDecoration: InputDecoration(
                    hintText: 'Search Country',
                  ),
                ),
                showFlagInInput: true,
                flagShape: BoxShape.circle,
                flagSize: 35,
                onChanged: (PhoneNumber? p) {
                  if (p == null) return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
                onSaved: (PhoneNumber? p) {
                  if (p == null) return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
              ),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Text(
              LanguageService.getTranslated(
                  context, "register_non_corporate_role_field_label"),
              style: typography.Subtitle1.copyWith(
                  color: Theme.of(context).colorScheme.onBackground),
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: Colors.white.withOpacity(0.11999999731779099),
              ),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Stack(
          children: [
            TextField(
              readOnly: true,
              controller: _textEditingController,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return RolesBottomSheet(
                      showCorporateSwitch: false,
                      options: context.read<AuthNotifier>().roles,
                      selectedRoles: _selectedRoles,
                      addChip: _addChip,
                      removeChip: _removeChip,
                      removeAllChips: _removeAllChips,
                      selectedOption:
                          _selectedOption ?? SignUpOptions.individual,
                      onOptionChanged: (SignUpOptions option) {
                        setState(() {
                          _selectedOption = option;
                        });
                      },
                    );
                  },
                );
              },
              decoration: InputDecoration(
                labelText: LanguageService.getTranslated(
                    context, "usermanagement_roles_label"),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: _selectedRoles.isEmpty
                    ? LanguageService.getTranslated(
                        context, "usermanagement_cuser_roles_placeholder")
                    : null,
                contentPadding: const EdgeInsets.fromLTRB(12, 40, 48, 12),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
            ),
            if (_selectedRoles.isNotEmpty)
              Positioned(
                top: 18,
                left: 12,
                right: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedRoles.map((value) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(value.name!),
                          onDeleted: () => _removeChip(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),

        // Stack(
        //   children: [
        //     TextField(
        //       readOnly: true,
        //       onTap: () {
        //         showModalBottomSheet(
        //           context: context,
        //           useSafeArea: true,
        //           isScrollControlled: true,
        //           builder: (BuildContext context) {
        //             return RolesBottomSheet(
        //               showCorporateSwitch: false,
        //               // options: roles,
        //               options: context.read<AuthNotifier>().roles,
        //               selectedRoles: _selectedRoles,
        //               addChip: _addChip,
        //               removeChip: _removeChip,
        //               removeAllChips: _removeAllChips,
        //               selectedOption:
        //                   _selectedOption ?? SignUpOptions.individual,
        //               onOptionChanged: (SignUpOptions option) {
        //                 setState(() {
        //                   _selectedOption = option;
        //                 });
        //               },
        //             );
        //           },
        //         );
        //       },
        //       controller: _textEditingController,
        //       onChanged: (value) {
        //         // Handle input changes
        //       },
        //       // decoration: InputDecoration(
        //       //   labelText: LanguageService.getTranslated(
        //       //       context, "usermanagement_roles_label"),
        //       //   hintText: _selectedRoles.isEmpty
        //       //       ? LanguageService.getTranslated(
        //       //           context, "usermanagement_cuser_roles_placeholder")
        //       //       : "",
        //       //   border: OutlineInputBorder(),
        //       //   suffixIcon: IconButton(
        //       //     icon: Icon(Icons.arrow_drop_down),
        //       //     onPressed: () {
        //       //       showModalBottomSheet(
        //       //         context: context,
        //       //         useSafeArea: true,
        //       //         isScrollControlled: true,
        //       //         builder: (BuildContext context) {
        //       //           return RolesBottomSheet(
        //       //             showCorporateSwitch: false,
        //       //             // options: roles,
        //       //             options: context.read<AuthNotifier>().roles,
        //       //             selectedRoles: _selectedRoles,
        //       //             addChip: _addChip,
        //       //             removeChip: _removeChip,
        //       //             removeAllChips: _removeAllChips,
        //       //             selectedOption:
        //       //                 _selectedOption ?? SignUpOptions.individual,
        //       //             onOptionChanged: (SignUpOptions signUpOptions) {
        //       //               setState(() {
        //       //                 _selectedOption = signUpOptions;
        //       //               });
        //       //             },
        //       //           );
        //       //         },
        //       //       );
        //       //     },
        //       //   ),
        //       // ),
        //     ),
        //     Positioned(
        //       top: 10.0,
        //       left: 10.0,
        //       right: 10.0,
        //       child: Container(
        //         margin: const EdgeInsets.only(right: 32.0),
        //         child: SingleChildScrollView(
        //           scrollDirection: Axis.horizontal,
        //           child: Row(
        //             children: _selectedRoles
        //                 .map(
        //                   (value) => Padding(
        //                     padding: const EdgeInsets.only(right: 8.0),
        //                     child: Chip(
        //                       label: Text(value.name!),
        //                       deleteIcon: Icon(Icons.cancel),
        //                       onDeleted: () => _removeChip(value),
        //                     ),
        //                   ),
        //                 )
        //                 .toList(),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  // Put these inside your State<_...> class (top of the class)
  final List<String> _fixedAdminRoles = [
    "Admin",
    "Broker",
    "Insurance Buyer",
  ];

  final List<String> _manualCompanyTypes = [
    // deduped & normalized from your provided list
    "Insurance Broker",
    "Insurance",
    "Risk Manager",
    "Service Provider",
    "Broker",
    "Reinsurer", // added a common one, remove if not required
  ];

  final List<String> _manualRoles = [
    "Admin",
  ];

  CompanyType? matchCompanyType({
    required Companies selected,
    required List<CompanyType> types,
  }) {
    String selName = (selected.companyTypeName ?? "").trim().toLowerCase();
    String selClean = selName.replaceAll("_", "").replaceAll(" ", "");

    // 1️⃣ Match by ID
    try {
      if (selected.companyTypeId != null) {
        return types.firstWhere((t) => t.id == selected.companyTypeId);
      }
    } catch (_) {}

    // 2️⃣ Exact type or name match
    for (var t in types) {
      final type = (t.type ?? "").trim().toLowerCase();
      final name = (t.name ?? "").trim().toLowerCase();
      if (type == selName || name == selName) return t;
    }

    // 3️⃣ Underscore/space insensitive match
    for (var t in types) {
      final type = (t.type ?? "")
          .trim()
          .toLowerCase()
          .replaceAll("_", "")
          .replaceAll(" ", "");
      final name = (t.name ?? "")
          .trim()
          .toLowerCase()
          .replaceAll("_", "")
          .replaceAll(" ", "");
      if (type == selClean || name == selClean) return t;
    }

    // 4️⃣ Contains (Fuzzy)
    for (var t in types) {
      final type = (t.type ?? "").toLowerCase();
      final name = (t.name ?? "").toLowerCase();
      if (type.contains(selName) || name.contains(selName)) return t;
    }

    return null; // fallback
  }

  String? selectedAdminDropDownRole; // shows after API select
  bool showAdminDropdown = false;

// Manual-mode selections
  bool isManualEntry = false;
  String? selectedManualCompanyType;
  String? selectedManualRole;
  bool isLoadingCompanySearch = false;

  Widget _corporateAccountUI() {
    final typography = CustomTypography(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country picker (unchanged)
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: CountryPickerFlagName(
                onCountryChange: !_enableCompanyTypeDropdown
                    ? null
                    : (country) {
                        setState(() {
                          _selectedCorporateCountryName = country.name;
                        });
                      },
                initialValue: country_picker.Country(
                  phoneCode: '1',
                  countryCode:
                      getCountryCodeFromName(_selectedCorporateCountryName) ??
                          "",
                  e164Sc: 1,
                  geographic: true,
                  level: 1,
                  name: _selectedCorporateCountryName,
                  example: '',
                  displayName: '',
                  displayNameNoCountryCode: '',
                  e164Key: '',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.eight),

        // Company Autocomplete (API)
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<Companies>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final input = textEditingValue.text.trim().toLowerCase();
                    if (input.isEmpty) {
                      // no typing → show API options (user can still select)
                      return authNotifier.companyOptions;
                    }
                    return authNotifier.companyOptions.where(
                      (company) => company.name.toLowerCase().contains(input),
                    );
                  },
                  displayStringForOption: (Companies option) => option.name,
                  onSelected: (Companies selection) {
                    setState(() {
                      isManualEntry = false;
                      showAdminDropdown = true;
                      selectedAdminDropDownRole = null;

                      companyDisplayNameController.text =
                          selection.displayName ??
                              selection.countryName ??
                              selection.name ??
                              "";

                      selectedCompany = selection;
                      print("FULL COMPANY OBJECT: ${selection.toJson()}");

                      /// ✔ REAL company ID (UUID)
                      selectedCompanyId = selection.id;

                      /// ✔ CORRECT company type ID (slug)
                      selectedCompanyTypeId = selection.companyTypeId;

                      print(
                          "companyTypeId from model = ${selection.companyTypeId}");

                      /// ✔ Company type name (human readable)
                      selectedCompanyType1 = selection.companyTypeName;
                      companyName = selection.name;
                      print("Company ID = $selectedCompanyId");
                      print("Company Type ID = $selectedCompanyTypeId");
                      print("Company Type Name = $selectedCompanyType1");

                      // Match company type object for available roles
                      final types = authNotifier.companyTypeList ?? [];
                      selectedCompanyType = matchCompanyType(
                        selected: selection,
                        types: types,
                      );

                      if (selectedCompanyType != null &&
                          selectedCompanyType!.roles.isNotEmpty) {
                        selectedCompanyRole = selectedCompanyType!.roles.first;
                      }

                      _enableCompanyTypeDropdown = false;
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    _textEditingController = textEditingController;
                    return TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Company Name",
                        hintText: "Enter or search company name...",
                        border: OutlineInputBorder(),
                        suffixIcon: isLoadingCompanySearch
                            ? Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Icon(Icons.search),
                      ),
                      onChanged: (value) async {
                        print(_manualCompanyTypes.length);
                        print(companyOptions.length);
                        print("_manualCompanyTypes.first");
                        final v = value.trim();
                        if (v.isEmpty) {
                          // reset to initial state
                          setState(() {
                            isManualEntry = false;
                            selectedManualCompanyType = null;
                            selectedManualRole = null;
                            selectedCompanyType = null;
                            selectedCompanyRole = null;
                            _enableCompanyTypeDropdown = true;
                            showAdminDropdown = false;
                            companyDisplayNameController.clear();
                          });
                          authNotifier.filteredCompanyOptions = [];
                          return;
                        }

                        // When user types (and doesn't immediately select), enter manual mode
                        setState(() {
                          isManualEntry = true;

                          selectedManualRole = "Admin";

                          // FIX: default company type must not be null
                          // selectedManualCompanyType ??=
                          //     _manualCompanyTypes.first;

                          // FIX: company type text field value
                          selectedCompanyType1 = selectedManualCompanyType;

                          // FIX: give a placeholder companyTypeId
                          // selectedCompanyTypeId = "manual";

                          // FIX: give a placeholder companyId
                          selectedCompanyId = "manual";

                          selectedCompanyType = null;
                          selectedCompanyRole = null;

                          _enableCompanyTypeDropdown = true;
                          showAdminDropdown = false;
                        });

                        if (v.length > 1) {
                          setState(() => isLoadingCompanySearch = true);
                          await authNotifier.fetchCompanies(v);
                          authNotifier.filterCompanies(v);
                          setState(() => isLoadingCompanySearch = false);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    if (options.isEmpty) return SizedBox.shrink();

                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: Container(
                          color: Colors.black38,
                          width: MediaQuery.of(context).size.width * 0.9,
                          constraints: BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.name,
                                    style: TextStyle(color: Colors.white)),
                                // subtitle: option.displayName != null
                                //     ? Text(option.displayName!)
                                //     : null,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        SizedBox(height: CustomSpacing.four),

        // COMPANY TYPE: API-mode locked dropdown OR manual dropdown when typing
        // Builder(builder: (context) {
        //   if (isManualEntry) {
        //     return DropdownButtonFormField<String>(
        //       value: selectedManualCompanyType,
        //       decoration: InputDecoration(
        //         labelText: "Company Type2",
        //         border: OutlineInputBorder(),
        //       ),
        //       items: _manualCompanyTypes
        //           .map((t) => DropdownMenuItem(value: t, child: Text(t)))
        //           .toList(),
        //
        //       // ✅ FIX: assign manual company type + typeId
        //       onChanged: (val) {
        //         setState(() {
        //           selectedManualCompanyType = val;
        //
        //           // 🔥 These 2 are REQUIRED by backend and must not be null
        //           selectedCompanyType1 = val; // company_type_name
        //           selectedCompanyTypeId = val!
        //               .toLowerCase()
        //               .replaceAll(" ", "_"); // company_type_id
        //         });
        //       },
        //
        //       validator: (v) {
        //         if (v == null || v.trim().isEmpty)
        //           return "Company Type is required";
        //         return null;
        //       },
        //     );
        //   }
        Builder(builder: (context) {
          if (isManualEntry)
            return Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                final companyTypes = authNotifier.companyType;

                if (companyTypes.isEmpty) {
                  return const SizedBox();
                }

                // 🔥 Ensure selected value is valid
                if (selectedManualCompanyType != null &&
                    !companyTypes.any(
                        (e) => e.companyName == selectedManualCompanyType)) {
                  selectedManualCompanyType = null;
                }

                return DropdownButtonFormField<String>(
                  value: selectedManualCompanyType,
                  // 👈 SAME as manual
                  decoration: const InputDecoration(
                    labelText: "Company Type",
                    border: OutlineInputBorder(),
                  ),

                  // ✅ Display NAME, store NAME (manual-style)
                  items: companyTypes.map((ct) {
                    return DropdownMenuItem<String>(
                      value: ct.companyName, // 👈 String
                      child: Text(ct.companyName),
                    );
                  }).toList(),

                  onChanged: (val) {
                    if (val == null) return;
                    print(val);
                    print(val);
                    print("val");
                    final selected =
                        companyTypes.firstWhere((e) => e.companyName == val);

                    setState(() {
                      // ✅ SAME behavior as old manual dropdown
                      selectedManualCompanyType = val;
                      // selectedCompanyId = selected.id;
                      // 🔥 Backend-required values
                      selectedCompanyTypeId = selected.id;
                      // selectedCompanyTypeId = selected.id;
                      selectedCompanyType1 = selected.companyName;
                    });
                  },

                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Company Type is required";
                    }
                    return null;
                  },
                );
              },
            );

          // if (isManualEntry) {
          //   // manual entry path: show manual company type dropdown
          //   return DropdownButtonFormField<String>(
          //     value: selectedManualCompanyType,
          //     decoration: InputDecoration(
          //       labelText: "Company Type",
          //       border: OutlineInputBorder(),
          //     ),
          //     items: _manualCompanyTypes
          //         .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          //         .toList(),
          //     onChanged: (val) {
          //       setState(() => selectedManualCompanyType = val);
          //     },
          //     validator: (v) {
          //       if (v == null || v.trim().isEmpty)
          //         return "Company Type is required";
          //       return null;
          //     },
          //   );
          // }

          else {
            // API-mode: show selectedCompanyType (locked) or allow selection if enabled
            return Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,

                  controller:
                      TextEditingController(text: selectedCompanyType1 ?? ""),
                  enabled: _enableCompanyTypeDropdown,
                  // false = read-only
                  decoration: InputDecoration(
                    labelText: "Company Type",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedCompanyType1 = value;
                    });
                  },
                  validator: (value) {
                    if (!isManualEntry &&
                        (value == null || value.trim().isEmpty)) {
                      return "Company Type is required";
                    }
                    return null;
                  },
                );
              },
            );

            //   Consumer<AuthNotifier>(
            //   builder: (context, authNotifier, child) {
            //     final types = authNotifier.companyTypeList ?? [];
            //     return IgnorePointer(
            //       ignoring: !_enableCompanyTypeDropdown,
            //       child: DropdownButtonFormField<CompanyType>(
            //         value: selectedCompanyType1,
            //         decoration: InputDecoration(
            //           labelText: "Company Type",
            //           border: OutlineInputBorder(),
            //         ),
            //         items: types
            //             .where((ct) =>
            //                 (ct.type ?? "").toLowerCase() !=
            //                 'individual_account')
            //             .map((ct) => DropdownMenuItem(
            //                 value: ct, child: Text(ct.type ?? ct.name ?? '')))
            //             .toList(),
            //         onChanged: _enableCompanyTypeDropdown
            //             ? (CompanyType? newValue) {
            //                 setState(() {
            //                   selectedCompanyType = newValue;
            //                   // when user manually changes companyType from dropdown (allowed only when enabled),
            //                   // reset roles to first of that companyType (if available)
            //                   if (selectedCompanyType != null &&
            //                       selectedCompanyType!.roles.isNotEmpty) {
            //                     selectedCompanyRole =
            //                         selectedCompanyType!.roles.first;
            //                   } else {
            //                     selectedCompanyRole = null;
            //                   }
            //                 });
            //               }
            //             : null,
            //         validator: (value) {
            //           if (!isManualEntry && value == null)
            //             return "Company Type is required";
            //           return null;
            //         },
            //       ),
            //     );
            //   },
            // );
          }
        }),

        SizedBox(height: CustomSpacing.four),

        // COMPANY DISPLAY NAME -- editable only in manual mode
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: companyDisplayNameController,
          enabled: isManualEntry || _enableCompanyTypeDropdown,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'Company Display Name'),
                  WidgetSpan(
                    child: Text(' *', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            hintText: "Enter display name of your company",
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Company display name is required';
            return null;
          },
        ),

        SizedBox(height: CustomSpacing.four),

        // ROLE SECTION
        // If API selected (not manual entry) show roles from API and ALSO show fixed admin dropdown (per your earlier request)
        // If manual entry -> only Admin role (manualRoles)
        if (isManualEntry)
          DropdownButtonFormField<String>(
            value: selectedManualRole,
            decoration: InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: _manualRoles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => selectedManualRole = v),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Role is required';
              return null;
            },
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(selectedCompanyType1.toString()),

              // API-driven roles dropdown (first priority)
              // DropdownButtonFormField<Roles>(
              //   value: selectedCompanyRole,
              //   decoration: InputDecoration(
              //     labelText: 'Role(s)',
              //     border: OutlineInputBorder(),
              //   ),
              //   items: selectedCompanyType?.roles
              //           .map((r) =>
              //               DropdownMenuItem(value: r, child: Text(r.name)))
              //           .toList() ??
              //       [],
              //   onChanged: (r) {
              //     setState(() => selectedCompanyRole = r);
              //   },
              //   validator: (v) {
              //     if (selectedCompanyType != null && (v == null))
              //       return 'Role is required';
              //     return null;
              //   },
              // ),

              SizedBox(height: CustomSpacing.two),

              // After API selection show the fixed Admin/Broker/Insurance Broker/Risk Manager dropdown as extra selection UI
              if (!isManualEntry)
                Consumer<AuthNotifier>(
                  builder: (context, authNotifier, child) {
                    final selectedName = selectedCompanyType1?.trim() ?? "";

                    // Debug: Check the current state
                    print('Selected name: $selectedName');
                    print(
                        'Company list length: ${authNotifier.companyType?.length}');

                    // Find the matching company in companyType list
                    CompanyType? matchingCompany;

                    if (selectedName.isNotEmpty &&
                        authNotifier.companyType != null) {
                      try {
                        matchingCompany = authNotifier.companyType!.firstWhere(
                          (c) =>
                              (c.companyName ?? "").trim().toLowerCase() ==
                              selectedName.toLowerCase(),
                        );
                      } catch (e) {
                        // No match found
                        matchingCompany = null;
                      }
                    }

                    // If no company selected yet or no match found
                    if (selectedName.isEmpty) {
                      return DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select company first'),
                        items: [],
                        onChanged: null,
                      );
                    }

                    if (matchingCompany == null) {
                      return Column(
                        children: [
                          // Text(
                          //     'Company list: ${authNotifier.companyType?.length}'),
                          // Text('Selected: $selectedName'),
                          // DropdownButton<String>(
                          //   isExpanded: true,
                          //   hint: Text('Company not found: $selectedName'),
                          //   items: [],
                          //   onChanged: null,
                          // ),
                        ],
                      );
                    }

                    // Get roles from the matching company
                    final roles = matchingCompany.roles ?? [];

                    // Debug info (optional)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Debug information
                        // Text('Total companies: ${authNotifier.companyType?.length}'),
                        // Text('Matched company: ${matchingCompany.companyName}'),
                        // Text('Available roles: ${roles.length}'),
                        // SizedBox(height: 8),
                        // Text('Available roles: ${roles.length}'),
                        SizedBox(height: 8),

                        DropdownButtonFormField<Roles>(
                          decoration: InputDecoration(
                            labelText: 'Select Role',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedRole, // <-- your selected variable
                          items: roles.map((role) {
                            return DropdownMenuItem<Roles>(
                              value: role,
                              child: Text(role.name.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value; // <-- update selected
                              selectedCompanyRole = value;
                              print(value!.name.toString());
                            });
                          },
                        ),
                      ],
                    );
                  },
                )
              // if (!isManualEntry)
              //   Consumer<AuthNotifier>(
              //     builder: (context, authNotifier, child) {
              //       final selectedName = selectedCompanyType1 ?? "";
              //
              //       // Correct matching using c.name
              //       final matchingCompany =
              //           authNotifier.companyList
              //               ?.firstWhere(
              //         (c) =>
              //             (c.companyName ?? "").toLowerCase() ==
              //             selectedName.toLowerCase(),
              //         // orElse: () => null,
              //       );
              //
              //       // roles list
              //       final roles = matchingCompany!.roles ?? [];
              //
              //       return Container(child: Text(roles.length.toString()),);
              //
              //       //   DropdownButtonFormField<Roles>(
              //       //   value: selectedCompanyRole,
              //       //   decoration: InputDecoration(
              //       //     labelText: "Role(s)1",
              //       //     border: OutlineInputBorder(),
              //       //   ),
              //       //   items: roles
              //       //       .map(
              //       //         (r) => DropdownMenuItem(
              //       //           value: r,
              //       //           child: Text(r.name ?? ""),
              //       //         ),
              //       //       )
              //       //       .toList(),
              //       //   onChanged: (role) {
              //       //     setState(() {
              //       //       selectedCompanyRole = role;
              //       //     });
              //       //   },
              //       //   validator: (value) {
              //       //     if (value == null) return "Role is required";
              //       //     return null;
              //       //   },
              //       // );
              //     },
              //   ),
            ],
          ),

        SizedBox(height: CustomSpacing.four),

        // The rest fields (Admin name, email, phone, passwords) - keep as you had
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: LanguageService.getTranslated(
                          context, "usermanagement_name_field_label")),
                  WidgetSpan(
                      child: Text(" *", style: TextStyle(color: Colors.red)),
                      alignment: PlaceholderAlignment.bottom),
                ],
              ),
            ),
            hintText: LanguageService.getTranslated(
                context, "usermanagemet_cuser_name_place_holder"),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.contains(RegExp(r'[0-9]'))) {
              return 'Name is required';
            }
            return null;
          },
          controller: adminNameController,
        ),

        SizedBox(height: CustomSpacing.four),

        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: LanguageService.getTranslated(
                          context, "connections_user_connection_email_filter")),
                  WidgetSpan(
                      child: Text(" *", style: TextStyle(color: Colors.red)),
                      alignment: PlaceholderAlignment.bottom),
                ],
              ),
            ),
            hintText: LanguageService.getTranslated(
                context, "user_profile_user_management_email_placeholer"),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || regextest(value) == false) {
              return 'Enter a valid email address';
            }
            return null;
          },
          controller: adminEmailController,
          readOnly: widget.email != null && widget.email!.isNotEmpty,
        ),

        SizedBox(height: CustomSpacing.four),

        // Mobile/Phone input - reuse your existing PhoneInput
        Row(
          children: [
            Expanded(
              child: FormField<String>(
                validator: (value) {
                  if (mobileController.value!.nsn.isEmpty)
                    return 'Mobile number is required.';
                  if (mobileController.value!.nsn.length < 10)
                    return 'Enter a valid mobile number.';
                  return null;
                },
                builder: (FormFieldState<String> fieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhoneInput(
                        key: const Key('phone-field'),
                        controller: mobileController,
                        shouldFormat: true,
                        defaultCountry: IsoCode.US,
                        decoration: InputDecoration(
                          label: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: LanguageService.getTranslated(
                                        context, "register_mobile_number")),
                                TextSpan(
                                    text: " *",
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          hintText: _corporateAdminHintText,
                          border: const OutlineInputBorder(),
                          counterText: '',
                          errorText: fieldState.errorText,
                        ),
                        countrySelectorNavigator:
                            CountrySelectorNavigator.dialog(
                          showSearchInput: true,
                          searchInputDecoration:
                              const InputDecoration(hintText: 'Search Country'),
                        ),
                        showFlagInInput: true,
                        flagShape: BoxShape.circle,
                        flagSize: 35,
                        onChanged: (PhoneNumber? p) {
                          if (p == null) return;
                          setState(() {
                            _selectedCountryCode = p.countryCode;
                            _selectedAdminCorporateCountry = p.isoCode.name;
                            _updateHintText();
                          });
                          fieldState.didChange(mobileController.value!.nsn);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        SizedBox(height: CustomSpacing.four),

        // Password fields (kept same as existing)
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: LanguageService.getTranslated(
                          context, "emailsetup_field_password")),
                  WidgetSpan(
                      child: Text(" *", style: TextStyle(color: Colors.red)),
                      alignment: PlaceholderAlignment.bottom),
                ],
              ),
            ),
            hintText: LanguageService.getTranslated(
                context, "register_corporate_password_field_placeholder"),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: _showPasswordCorporate
                  ? Icon(Icons.visibility)
                  : Icon(Icons.visibility_off),
              onPressed: () {
                setState(
                    () => _showPasswordCorporate = !_showPasswordCorporate);
              },
            ),
          ),
          obscureText: !_showPasswordCorporate,
          controller: adminPasswordController,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8)
              return 'Password must be at least 8 characters';
            return null;
          },
        ),

        SizedBox(height: CustomSpacing.four),

        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: LanguageService.getTranslated(context,
                          "register_corporate_password_field_placeholder")),
                  WidgetSpan(
                      child: Text(" *", style: TextStyle(color: Colors.red)),
                      alignment: PlaceholderAlignment.bottom),
                ],
              ),
            ),
            hintText: LanguageService.getTranslated(context,
                "register_corporate_confirm_password_field_placeholder"),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: _showPasswordConfirmationCorporate
                  ? Icon(Icons.visibility)
                  : Icon(Icons.visibility_off),
              onPressed: () {
                setState(() => _showPasswordConfirmationCorporate =
                    !_showPasswordConfirmationCorporate);
              },
            ),
          ),
          obscureText: !_showPasswordConfirmationCorporate,
          controller: adminConfirmPasswordController,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8)
              return 'Password must be at least 8 characters';
            if (value != adminPasswordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),

        SizedBox(height: CustomSpacing.four),
      ],
    );
  }

  void _addChip(Categories value) {
    setState(() {
      _selectedRoles.add(value);
      _textEditingController.clear();
    });
  }

  void _removeChip(Categories value) {
    print('Removing chip: ${value.name}');
    setState(() {
      _selectedRoles.removeWhere((element) => element.name == value.name);
    });
    print(
        'Selected roles: ${_selectedRoles.map((role) => role.name).toList()}');
  }

  void _removeAllChips() {
    setState(() {
      _selectedRoles.clear();
    });
  }

  void handleBrightnessChange(bool useLightMode) {}

  void handleMaterialVersionChange() {}

  void handleColorSelect(int value) {}

  void handleImageSelect(int value) {}

// Define a function to validate the phone number based on the selected country
  String? validatePhoneNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      // Get the dialing code for the selected country
      String dialingCode = _selectedCountryCode ?? '';

      // Construct a regular expression pattern based on the country's dialing code
      String pattern = '';
      print("dialingCode: $dialingCode");
      // Adjust the pattern based on the country dialing code format
      switch (dialingCode) {
        case '+1': // United States
          pattern = r'^[0-9]{10}$'; // 10 digits for the US
          break;
        case '+91': // India
          pattern = r'^[0-9]{10}$'; // 10 digits for India
          break;
        case '+44': // United Kingdom
          pattern = r'^(?:(?:\+?44)?(0)?)?(\d{10})$'; // UK phone number format
          break;
        case '+61': // Australia
          pattern = r'^[0-9]{9}$'; // 9 digits for Australia
          break;
        case '+86': // China
          pattern = r'^1[0-9]{10}$'; // 11 digits for China, starts with 1
          break;
        case '+81': // Japan
          pattern = r'^[0-9]{10,11}$'; // 10 or 11 digits for Japan
          break;
        case '+82': // South Korea
          pattern =
              r'^01(?:0|1|[6-9])-(?:\d{3}|\d{4})-\d{4}$'; // South Korea phone number format
          break;
        case '+966': // Saudi Arabia
          pattern = r'^[0-9]{9}$'; // 9 digits for Saudi Arabia
          break;
        case '+971': // United Arab Emirates
          pattern = r'^[0-9]{9}$'; // 9 digits for UAE
          break;
        case '+20': // Egypt
          pattern = r'^01[0-9]{9}$'; // 11 digits for Egypt, starts with 01
          break;
        // Add more cases for other countries as needed
        default:
          pattern = r'^[0-9]+$'; // Default pattern: any number of digits
          break;
      }

      // Validate the phone number using the constructed pattern
      if (!RegExp(pattern).hasMatch(value)) {
        return 'Invalid phone number format';
      }
    }
    return null; // Return null if validation passes
  }

  String? getCountryCodeFromName(String countryName) {
    return countryNameToCodeMap[countryName];
  }
}

extension StringExtensions on String {
  bool isSameStringCaseAs(String other) {
    if (length != other.length) return false;
    return isNotEmpty && this[0].toUpperCase() == other[0].toUpperCase();
  }

  String capitalizeAfterAbbr(String abbr) {
    if (abbr.isEmpty) return this;
    final firstLetter = abbr[0].toUpperCase();
    final rest = substring(abbr.length).toLowerCase();
    return '$firstLetter$rest';
  }
}
