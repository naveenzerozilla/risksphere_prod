import 'dart:async';
import 'dart:developer';

import 'package:RiskSphere/models/companymodel.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';

// import 'package:country_list_picker/country_list_picker.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autocomplete_label/autocomplete_label.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:RiskSphere/design_system/components/country_picker_flag_name.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/main.dart';
import 'package:RiskSphere/models/initial_data_model.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/screens/home/dashboard_screen.dart';
import 'package:RiskSphere/screens/onboarding/splash_screen.dart';
import 'package:phone_input/phone_input_package.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../design_system/repo/home.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/language_service.dart';
import '../../utils/utils.dart';

import 'package:country_picker/country_picker.dart' as country_picker;

import '../terms_privacy.dart';

class CreateAccountScreen extends StatefulWidget {
  final UserCredential? userCredential;

  const CreateAccountScreen({super.key, this.userCredential});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  SignUpOptions? _selectedOption;

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
  // void onSearchChanged(String query, AuthNotifier authNotifier) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //
  //   _debounce = Timer(Duration(milliseconds: 300), () {
  //     authNotifier.fetchCompanies(query); // 🔹 Fetch data and trigger UI updates
  //   });
  // }

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
  CompanyType? selectedCompanyType;
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
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.fetchCompanies(""); // Initial fetch
    // authNotifier.companyOptionsNotifier.addListener(() {
    //   // setState(() {}); // Force rebuild when data changes
    // });
    _selectedOption = SignUpOptions.individual;
    /* if(widget.userCredential!=null&&widget.userCredential?.user!=null && widget.userCredential!.additionalUserInfo!=null && widget.userCredential!.additionalUserInfo!.isNewUser) {
      setState(() {
        isNewUser = true;
      });
    }*/
    _updateHintText();
  }

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
    Provider.of<AuthNotifier>(context, listen: false).signOut();
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
                          LanguageService.getTranslated(
                              context, "login_image_text"),
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
                          height: 60,
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
                                    if (!_termsAccepted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please accept the Terms & Conditions.'),
                                        ),
                                      );
                                      return;
                                    }

                                    if (!_privacyAccepted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please accept the Privacy Policy.'),
                                        ),
                                      );
                                      return;
                                    }

                                    if (_formKey.currentState!.validate()) {
                                      /* if(isCaptchaVerified == false) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Please verify that you are not a robot.'),
                                              ),
                                            );
                                            return;
                                          }*/
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
                                          /*Navigator.push(context, MaterialPageRoute(builder: (context) => */ /*Home(
                                                useLightMode: false,
                                                useMaterial3: true,
                                                colorSelected: ColorSeed.baseColor,
                                                imageSelected: ColorImageProvider.leaves,
                                                handleBrightnessChange: handleBrightnessChange,
                                                handleMaterialVersionChange: handleMaterialVersionChange,
                                                handleColorSelect: handleColorSelect,
                                                handleImageSelect: handleImageSelect,
                                                colorSelectionMethod: ColorSelectionMethod.colorSeed,
                                              )*/ /*HomeScreen()));*/
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
                                        print('Individual Account');
                                        print('Name: ${nameController.text}');
                                        print(
                                            'Display Name: ${displayNameController.text}');
                                        print('Email: ${emailController.text}');
                                        print(
                                            'Mobile: $_selectedCountryCode ${mobileController.value?.nsn ?? ""}');
                                        print('Roles: $_selectedRoles');
                                        print('Account Type: $_selectedOption');
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
                                        print('Corporate Account');
                                        print(
                                            'Company Legal Name: ${companyName}');
                                        print(
                                            'Company Type: $selectedCompanyType');
                                        print(
                                            'Company Display Name: ${companyDisplayNameController.text}');
                                        print(
                                            'Admin Email: ${adminEmailController.text}');
                                        print(
                                            'Admin Mobile: $_selectedAdminCountryCode ${adminMobileController.text}');
                                        print('Roles: $_selectedRoles');
                                        print('Account Type: $_selectedOption');
                                        bool isApplicableForTrial = authNotifier
                                                .companyTypeList
                                                ?.where((companyType) =>
                                                    companyType.id ==
                                                    selectedCompanyType?.id)
                                                .first
                                                .isApplicableForTrial ??
                                            false;
                                        int trialPeriodDays = authNotifier
                                                .companyTypeList
                                                ?.where((companyType) =>
                                                    companyType.id ==
                                                    selectedCompanyType?.id)
                                                .first
                                                .trialPeriodDays ??
                                            0;
                                        authNotifier
                                            .signUpCorporateWithEmailAndPassword(
                                          companyId,
                                          companyName,
                                          selectedCompanyType!,
                                          companyDisplayNameController.text,
                                          adminNameController.text,
                                          adminEmailController.text,
                                          mobileController.value?.countryCode ??
                                              "",
                                          mobileController.value?.nsn ?? "",
                                          adminPasswordController.text,
                                          !_enableCompanyTypeDropdown
                                              ? selectedCompanyRole
                                              : Roles(
                                                  isForIndividual: true,
                                                  isApplicableForTrial: false,
                                                  role: "admin",
                                                  name: "Admin",
                                                  isMultipleRoleEnabled: false,
                                                  id: "admin",
                                                ),
                                          context,
                                          selectedCompany,
                                          isApplicableForTrial,
                                          trialPeriodDays,
                                          _selectedCorporateCountryName,
                                        );
                                      }
                                    }
                                  },
                                  child: _selectedOption ==
                                          SignUpOptions.individual
                                      ? Text(
                                          // If companyTypeList contains an individual_account with isApplicableForTrial as true, show 'Start Trial' else 'Create Account'
                                          (authNotifier.companyTypeList ?? [])
                                                  .any((companyType) {
                                            log("Processing companyType: ${companyType.type}, isApplicableForTrial: ${companyType.isApplicableForTrial}");
                                            return companyType.type
                                                        .toLowerCase() ==
                                                    'individual_account' &&
                                                companyType
                                                    .isApplicableForTrial;
                                          })
                                              ? "Start your ${(authNotifier.companyTypeList ?? []).where((companyType) {
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
                                          // Check selected_company_type in the companyTypeList
                                          (authNotifier.companyTypeList ?? [])
                                                  .any((companyType) {
                                            // log("Checking selectedCompanyType: ${selectedCompanyType}");
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
              _selectedOption == SignUpOptions.individual
                  ? LanguageService.getTranslated(context,
                      "register_non_corporate_create_user_account_title")
                  : LanguageService.getTranslated(
                      context, "register_corporate_create_corporate_act_title"),
              style: typography.H5_Regular.copyWith(
                  color: Theme.of(context).colorScheme.onBackground),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: CustomSpacing.eight),
          Row(
            children: [
              Expanded(
                child: RadioListTile<SignUpOptions>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(LanguageService.getTranslated(
                      context, "register_non_corporate_radio_Individual")),
                  value: SignUpOptions.individual,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                      _removeAllChips();
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<SignUpOptions>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(LanguageService.getTranslated(
                      context, "register_non_corporate_radio_Corporate")),
                  value: SignUpOptions.corporate,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                      _removeAllChips();
                    });
                  },
                ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Social Media Buttons
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
        // SizedBox(
        //   height: CustomSpacing.one,
        // ),
        // SocialMediaButton(
        //   onPressed: () {
        //     // Add your onPressed function here
        //   },
        //   buttonText:
        //       LanguageService.getTranslated(context, "login_microsoft_button"),
        //   iconPath: 'assets/images/microsoftLogo.svg',
        // ),
        SizedBox(height: CustomSpacing.eight),
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
        // Name
        TextFormField(
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
        SizedBox(height: CustomSpacing.two),
        // Display Name
        TextFormField(
          decoration: InputDecoration(
            // labelText: LanguageService.getTranslated(
            //     context, "usermanagement_display_name_field_label"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
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
        SizedBox(height: CustomSpacing.two),
        // Email
        TextFormField(
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
            // You can add more specific email validation here if needed
            return null;
          },
          controller: emailController,
        ),
        SizedBox(height: CustomSpacing.two),
        // mobile (optional)
        Row(
          children: [
            Expanded(
              child: FormField<String>(
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
        SizedBox(height: CustomSpacing.two),
        // Password
        TextFormField(
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
        SizedBox(height: CustomSpacing.two),

        // Confirm Password
        TextFormField(
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

        // TextFormField(
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
        SizedBox(height: CustomSpacing.two),
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
        SizedBox(height: CustomSpacing.two),
        Stack(
          children: [
            FormField<String>(
              validator: (value) {
                if (_selectedRoles.isEmpty) {
                  return 'Please select at least one role.';
                }
                return null;
              },
              builder: (FormFieldState<String> fieldState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: ""),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return RolesBottomSheet(
                              showCorporateSwitch: true,
                              options: roles,
                              selectedRoles: _selectedRoles,
                              addChip: (role) {
                                setState(() {
                                  _selectedRoles.add(role);
                                  _textEditingController.text = _selectedRoles
                                      .map((e) => e.name!)
                                      .join(', ');
                                  fieldState.didChange(role.name);
                                });
                              },
                              removeChip: (role) {
                                setState(() {
                                  _selectedRoles.remove(role);
                                  _textEditingController.text =
                                      _selectedRoles.isEmpty
                                          ? ''
                                          : _selectedRoles
                                              .map((e) => e.name!)
                                              .join(', ');
                                  fieldState.didChange(_selectedRoles.isEmpty
                                      ? null
                                      : role.name);
                                });
                              },
                              removeAllChips: () {
                                setState(() {
                                  _selectedRoles.clear();
                                  _textEditingController.clear();
                                  fieldState.didChange(null);
                                });
                              },
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
                        label: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    "register_non_corporate_role_field_label"),
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
                        hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
                        border: const OutlineInputBorder(),
                        errorText: fieldState.errorText,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              useSafeArea: true,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return RolesBottomSheet(
                                  showCorporateSwitch: true,
                                  options: roles,
                                  selectedRoles: _selectedRoles,
                                  addChip: (role) {
                                    setState(() {
                                      _selectedRoles.add(role);
                                      _textEditingController.text =
                                          _selectedRoles
                                              .map((e) => e.name!)
                                              .join(', ');
                                      fieldState.didChange(role.name);
                                    });
                                  },
                                  removeChip: (role) {
                                    setState(() {
                                      _selectedRoles.remove(role);
                                      _textEditingController.text =
                                          _selectedRoles.isEmpty
                                              ? ''
                                              : _selectedRoles
                                                  .map((e) => e.name!)
                                                  .join(', ');
                                      fieldState.didChange(
                                          _selectedRoles.isEmpty
                                              ? null
                                              : role.name);
                                    });
                                  },
                                  removeAllChips: () {
                                    setState(() {
                                      _selectedRoles.clear();
                                      _textEditingController.clear();
                                      fieldState.didChange(null);
                                    });
                                  },
                                  selectedOption: _selectedOption ??
                                      SignUpOptions.individual,
                                  onOptionChanged:
                                      (SignUpOptions signUpOptions) {
                                    setState(() {
                                      _selectedOption = signUpOptions;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                        prefixIcon: _selectedRoles.isNotEmpty
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _selectedRoles.map((role) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 12.0, left: 12),
                                      child: Chip(
                                        label: Text(role.name!),
                                        deleteIcon: const Icon(Icons.cancel),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedRoles.remove(role);
                                            _textEditingController.text =
                                                _selectedRoles.isEmpty
                                                    ? ''
                                                    : _selectedRoles
                                                        .map((e) => e.name!)
                                                        .join(', ');
                                            fieldState.didChange(
                                                _selectedRoles.isEmpty
                                                    ? null
                                                    : role.name);
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            : null,
                      ),
                    ),

                    // TextField(
                    //   readOnly: true,
                    //   onTap: () {
                    //     showModalBottomSheet(
                    //       context: context,
                    //       useSafeArea: true,
                    //       isScrollControlled: true,
                    //       builder: (BuildContext context) {
                    //         return RolesBottomSheet(
                    //           showCorporateSwitch: true,
                    //           options: roles,
                    //           selectedRoles: _selectedRoles,
                    //           addChip: (role) {
                    //             setState(() {
                    //               _selectedRoles.add(role);
                    //               _textEditingController.text =
                    //                   _selectedRoles.map((e) => e.name!).join(', ');
                    //               fieldState.didChange(role.name);
                    //             });
                    //           },
                    //           removeChip: (role) {
                    //             setState(() {
                    //               _selectedRoles.remove(role);
                    //               _textEditingController.text =
                    //               _selectedRoles.isEmpty
                    //                   ? ''
                    //                   : _selectedRoles.map((e) => e.name!).join(', ');
                    //               fieldState.didChange(_selectedRoles.isEmpty ? null : role.name);
                    //             });
                    //           },
                    //           removeAllChips: () {
                    //             setState(() {
                    //               _selectedRoles.clear();
                    //               _textEditingController.clear();
                    //               fieldState.didChange(null);
                    //             });
                    //           },
                    //           selectedOption: _selectedOption ?? SignUpOptions.individual,
                    //           onOptionChanged: (SignUpOptions option) {
                    //             setState(() {
                    //               _selectedOption = option;
                    //             });
                    //           },
                    //         );
                    //       },
                    //     );
                    //   },
                    //   controller: _textEditingController,
                    //   decoration: InputDecoration(
                    //     label: RichText(
                    //       text: TextSpan(
                    //         children: [
                    //           TextSpan(
                    //             text: LanguageService.getTranslated(
                    //                 context, "register_non_corporate_role_field_label"),
                    //           ),
                    //           TextSpan(
                    //             text: " *",
                    //             style: const TextStyle(
                    //               color: Colors.red,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.bold,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //     hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
                    //     border: const OutlineInputBorder(),
                    //     errorText: fieldState.errorText,
                    //     suffixIcon: IconButton(
                    //       icon: const Icon(Icons.arrow_drop_down),
                    //       onPressed: () {
                    //         showModalBottomSheet(
                    //           context: context,
                    //           useSafeArea: true,
                    //           isScrollControlled: true,
                    //           builder: (BuildContext context) {
                    //             return RolesBottomSheet(
                    //               showCorporateSwitch: true,
                    //               options: roles,
                    //               selectedRoles: _selectedRoles,
                    //               addChip: (role) {
                    //                 setState(() {
                    //                   _selectedRoles.add(role);
                    //                   _textEditingController.text =
                    //                       _selectedRoles.map((e) => e.name!).join(', ');
                    //                   fieldState.didChange(role.name);
                    //                 });
                    //               },
                    //               removeChip: (role) {
                    //                 setState(() {
                    //                   _selectedRoles.remove(role);
                    //                   _textEditingController.text =
                    //                   _selectedRoles.isEmpty
                    //                       ? ''
                    //                       : _selectedRoles.map((e) => e.name!).join(', ');
                    //                   fieldState.didChange(
                    //                       _selectedRoles.isEmpty ? null : role.name);
                    //                 });
                    //               },
                    //               removeAllChips: () {
                    //                 setState(() {
                    //                   _selectedRoles.clear();
                    //                   _textEditingController.clear();
                    //                   fieldState.didChange(null);
                    //                 });
                    //               },
                    //               selectedOption: _selectedOption ?? SignUpOptions.individual,
                    //               onOptionChanged: (SignUpOptions signUpOptions) {
                    //                 setState(() {
                    //                   _selectedOption = signUpOptions;
                    //                 });
                    //               },
                    //             );
                    //           },
                    //         );
                    //       },
                    //     ),
                    //   ),
                    // ),
                    // Positioned(
                    //   top: 12.0,
                    //   left: 10.0,
                    //   right: 50.0,
                    //   child: Container(
                    //     margin: const EdgeInsets.only(right: 8.0),
                    //     child: SingleChildScrollView(
                    //       scrollDirection: Axis.horizontal,
                    //       child: Row(
                    //         children: _selectedRoles
                    //             .map(
                    //               (value) => Padding(
                    //             padding: const EdgeInsets.only(right: 8.0),
                    //             child: Chip(
                    //               label: Text(value.name!),
                    //               deleteIcon: const Icon(Icons.cancel),
                    //               onDeleted: () {
                    //                 setState(() {
                    //                   _selectedRoles.remove(value);
                    //                   _textEditingController.text =
                    //                   _selectedRoles.isEmpty
                    //                       ? ''
                    //                       : _selectedRoles.map((e) => e.name!).join(', ');
                    //                   fieldState.didChange(
                    //                       _selectedRoles.isEmpty ? null : value.name);
                    //                 });
                    //               },
                    //             ),
                    //           ),
                    //         )
                    //             .toList(),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              },
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
        //               showCorporateSwitch: true,
        //               options: roles,
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
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return RolesBottomSheet(
                      showCorporateSwitch: false,
                      options: roles,
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
              controller: _textEditingController,
              onChanged: (value) {
                // Handle input changes
              },
              decoration: InputDecoration(
                labelText: LanguageService.getTranslated(
                    context, "usermanagement_roles_label"),
                hintText: _selectedRoles.isEmpty
                    ? LanguageService.getTranslated(
                        context, "usermanagement_cuser_roles_placeholder")
                    : "",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return RolesBottomSheet(
                          showCorporateSwitch: false,
                          options: roles,
                          selectedRoles: _selectedRoles,
                          addChip: _addChip,
                          removeChip: _removeChip,
                          removeAllChips: _removeAllChips,
                          selectedOption:
                              _selectedOption ?? SignUpOptions.individual,
                          onOptionChanged: (SignUpOptions signUpOptions) {
                            setState(() {
                              _selectedOption = signUpOptions;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              right: 10.0,
              child: Container(
                margin: const EdgeInsets.only(right: 32.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedRoles
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(value.name!),
                              deleteIcon: Icon(Icons.cancel),
                              onDeleted: () => _removeChip(value),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _corporateAccountUI() {
    var typography = CustomTypography(context);
    print('Corporate Country: $_selectedCorporateCountryName');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Corporate Country just show flag and country name
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: CountryPickerFlagName(
                onCountryChange: !_enableCountryDropdown
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
        // Company Legal Name
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<List<Companies>>(
                  valueListenable: authNotifier.companyOptionsNotifier,
                  builder: (context, companyOptions, _) {
                    return Autocomplete<Companies>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          print(
                              'Options builder called with: ${textEditingValue.text}');

                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Companies>.empty();
                          }

                          final filteredOptions = List<Companies>.from(
                              companyOptions.where((Companies) => Companies.name
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase())));
                          print(
                              'Filtered options count: ${filteredOptions.length}');
                          return filteredOptions;
                        },
                        onSelected: (Companies selection) {
                          print('Selected: ${selection.name}');
                          _textEditingController.text = selection.name;
                          companyDisplayNameController.text = selection.name;
                          setState(() {
                            _enableCompanyTypeDropdown = false;
                          });
                        },
                        displayStringForOption: (Companies option) =>
                            option.name,
                        fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) {
                          _textEditingController = textEditingController;
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Company Name",
                              hintText: "Enter company name...",
                              border: const OutlineInputBorder(),
                              suffixIcon: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : const Icon(Icons.search),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          print("options");
                          print(options);
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    constraints: BoxConstraints(maxHeight: 130),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option.name),
                                          onTap: () {
                                            onSelected(option);
                                            setState(
                                                () {}); // Ensures UI updates
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        });
                  },
                ),
              ],
            );
          },
        ),

        // Consumer<AuthNotifier>(
        //   builder: (context, authNotifier, child) {
        //     return Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Autocomplete<Companies>(
        //
        //           optionsBuilder: (TextEditingValue textEditingValue) {
        //             if (textEditingValue.text.isEmpty) {
        //               return const Iterable<Companies>.empty();
        //             }
        //             return authNotifier.companyOptions.where((company) =>
        //                 company.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        //           },
        //
        //           onSelected: (Companies selection) {
        //             _textEditingController.text = selection.name;
        //             companyDisplayNameController.text = selection.name;
        //             _enableCompanyTypeDropdown = false;
        //           },
        //           displayStringForOption: (Companies option) => option.name,
        //           fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        //             _textEditingController = textEditingController;
        //             return TextFormField(
        //               controller: textEditingController,
        //               focusNode: focusNode,
        //               decoration: InputDecoration(
        //                 labelText: "Company Name",
        //                 hintText: "Enter company name...",
        //                 border: OutlineInputBorder(),
        //                 suffixIcon: isLoading
        //                     ? Padding(
        //                   padding: EdgeInsets.all(10),
        //                   child: SizedBox(
        //                     width: 20,
        //                     height: 20,
        //                     child: CircularProgressIndicator(strokeWidth: 2),
        //                   ),
        //                 )
        //                     : Icon(Icons.search),
        //
        //               ),
        //     onChanged: (value) {
        //     if (_debounce?.isActive ?? false) _debounce!.cancel();
        //
        //     setState(() { isLoading = true; }); // Show loading immediately
        //
        //     _debounce = Timer(const Duration(milliseconds: 500), () {
        //     if (value.isEmpty) {
        //     _enableCompanyTypeDropdown = true;
        //     companyDisplayNameController.clear();
        //     authNotifier.companyOptions = [];
        //     setState(() { isLoading = false; }); // Stop loading
        //     } else {
        //     authNotifier.fetchCompanies(value).then((_) {
        //     setState(() { isLoading = false; }); // Stop loading after response
        //     });
        //     }
        //     });
        //
        //
        //
        //
        //               },
        //             );
        //           },
        //
        //           optionsViewBuilder: (context, onSelected, options) {
        //             return Align(
        //               alignment: Alignment.topLeft,
        //               child: Material(
        //                 elevation: 4.0,
        //                 child: Container(
        //                   width: MediaQuery.of(context).size.width * 0.9,
        //                   constraints: BoxConstraints(maxHeight: 250),
        //                   child: ListView.builder(
        //                     padding: EdgeInsets.zero,
        //                     itemCount: options.length,
        //                     itemBuilder: (BuildContext context, int index) {
        //                       final option = options.elementAt(index);
        //                       return ListTile(
        //                         title: Text('${option.name}'),
        //                         onTap: () => onSelected(option),
        //                       );
        //                     },
        //                   ),
        //                 ),
        //               ),
        //             );
        //           },
        //         ),
        //       ],
        //     );
        //   },
        // ),

        // Consumer<AuthNotifier>(
        //   builder: (context, authNotifier, child) {
        //     return Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Autocomplete<Companies>(
        //           optionsBuilder: (TextEditingValue textEditingValue) {
        //             if (textEditingValue.text.isEmpty) {
        //               return const Iterable<Companies>.empty();
        //             }
        //             return companyOptions.where((company) => company.name
        //                 .toLowerCase()
        //                 .contains(textEditingValue.text.toLowerCase()));
        //           },
        //           onSelected: (Companies selection) {
        //             setState(() {
        //               _textEditingController.text = selection.name;
        //               companyDisplayNameController.text = selection.name;
        //
        //               // Disable dropdown when a company is selected
        //               _enableCompanyTypeDropdown = false;
        //
        //               // Map company type
        //               selectedCompanyType = authNotifier.companyTypeList?.firstWhere(
        //                     (type) => type.name == selection.companyTypeName,
        //                 orElse: () => null as CompanyType,
        //               );
        //
        //               // If no valid match, set it to null
        //               if (selectedCompanyType?.id == "") {
        //                 selectedCompanyType = null;
        //               }
        //             });
        //           },
        //           // onSelected: (Companies selection) {
        //           //   setState(() {
        //           //     _textEditingController.text = selection.name;
        //           //     companyDisplayNameController.text = selection.name;
        //           //     _enableCompanyTypeDropdown=false;
        //           //     selectedCompanyType =
        //           //         authNotifier.companyTypeList?.firstWhere(
        //           //       (type) => type.name == selection.companyTypeName,
        //           //       orElse: () => null as CompanyType,
        //           //     );
        //           //   });
        //           //
        //           //   print(
        //           //       "Selected: ${selection.name}, Type: ${selection.name}");
        //           // },
        //           displayStringForOption: (Companies option) => option.name,
        //           fieldViewBuilder: (context, textEditingController, focusNode,
        //               onFieldSubmitted) {
        //             _textEditingController = textEditingController;
        //             return TextFormField(
        //               controller: textEditingController,
        //               focusNode: focusNode,
        //               decoration: InputDecoration(
        //                 labelText: "Company Name",
        //                 hintText: "Enter company name...",
        //                 border: OutlineInputBorder(),
        //                 suffixIcon: isLoading
        //                     ? Padding(
        //                         padding: EdgeInsets.all(10),
        //                         child: SizedBox(
        //                           width: 20,
        //                           height: 20,
        //                           child:
        //                               CircularProgressIndicator(strokeWidth: 2),
        //                         ),
        //                       )
        //                     : Icon(Icons.search),
        //               ),
        //
        //               onChanged: (value) {
        //                 if (value.isEmpty) {
        //                   setState(() {
        //                     _enableCompanyTypeDropdown = true; // Enable dropdown when cleared
        //                     selectedCompanyType = null; // Reset selected type
        //                     companyDisplayNameController.clear(); // Clear company display name
        //                   });
        //                 }
        //                 onSearchChanged(value, authNotifier); // Uses debouncer
        //               },
        //             );
        //           },
        //           optionsViewBuilder: (context, onSelected, options) {
        //             return Align(
        //               alignment: Alignment.topLeft,
        //               child: Material(
        //                 elevation: 4.0,
        //                 child: Container(
        //                   width: MediaQuery.of(context).size.width * 0.9,
        //                   constraints: BoxConstraints(maxHeight: 250),
        //                   child: ListView.builder(
        //                     padding: EdgeInsets.zero,
        //                     itemCount: options.length,
        //                     itemBuilder: (BuildContext context, int index) {
        //                       final option = options.elementAt(index);
        //                       return ListTile(
        //                         title: Text(
        //                             '${option.name} (${option.countryName})'),
        //                         onTap: () {
        //                           onSelected(option);
        //                         },
        //                       );
        //                     },
        //                   ),
        //                 ),
        //               ),
        //             );
        //           },
        //         ),
        //       ],
        //     );
        //   },
        // ),

        SizedBox(height: CustomSpacing.four),
        // Company Type
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return FormField<String>(
              builder: (FormFieldState<String> state) {
                return _showCompanyType
                    ? IgnorePointer(
                        ignoring: !_enableCompanyTypeDropdown,
                        child: DropdownButtonFormField<CompanyType>(
                          value: selectedCompanyType,
                          // Provide the currently selected value

                          onChanged: (CompanyType? newValue) {
                            setState(() {
                              _showRoles = false;
                              selectedCompanyRole = null;
                              selectedCompanyType =
                                  newValue; // Update the selected value
                              state.didChange(null); // Reset validation state
                            });
                            Future.delayed(Duration(milliseconds: 1), () {
                              setState(() {
                                _showRoles = true;
                              });
                            });
                          },
                          items: authNotifier.companyTypeList
                                  ?.where((companyType) =>
                                      companyType.type.toLowerCase() !=
                                      'individual_account')
                                  .map((CompanyType companyType) {
                                return DropdownMenuItem<CompanyType>(
                                  value: companyType,
                                  child: Text(companyType.name),
                                );
                              }).toList() ??
                              [],
                          decoration: InputDecoration(
                            enabled: _enableCompanyTypeDropdown,
                            // labelText: LanguageService.getTranslated(context,
                            //     "register_corporate_company_type_field_label"),
                            label: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: LanguageService.getTranslated(context,
                                        "register_corporate_company_type_field_label"), // Label text, // Black color for "Name"
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
                                "register_corporate_company_type_field_placeholder"),
                            border: const OutlineInputBorder(),
                            errorText: state.errorText,
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Company Type is required'; // Add your validation logic here
                            }
                            return null;
                          },
                        ),
                      )
                    : Center(
                        child: CircularProgressIndicator(),
                      );
              },
            );
          },
        ),

        SizedBox(height: CustomSpacing.four),
        // Company Display Name
        TextFormField(
          decoration: InputDecoration(
            enabled: _enableCompanyTypeDropdown,
            // labelText: LanguageService.getTranslated(
            //     context, "register_corporate_company_displayname_field_label"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
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
            hintText: LanguageService.getTranslated(context,
                "register_corporate_comapny_displayname_field_placeholder"),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                    value
                        .isEmpty /*||
                value.contains(RegExp(r'[0-9]'))*/
                ) {
              return 'Company display name is required';
            }
            // You can add more specific email validation here if needed
            return null;
          },
          controller: companyDisplayNameController,
        ),
        SizedBox(height: CustomSpacing.four),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _enableCompanyTypeDropdown ? 'Admin' : 'User & Role(s)',
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
        SizedBox(height: CustomSpacing.four),
        !_enableCompanyTypeDropdown
            ? Consumer<AuthNotifier>(
                builder: (context, authNotifier, child) {
                  return FormField<String>(
                    builder: (FormFieldState<String> state) {
                      return _showRoles
                          ? DropdownButtonFormField<Roles>(
                              onChanged: (Roles? newValue) {
                                setState(() {
                                  selectedCompanyRole = newValue;
                                  state.didChange(newValue
                                      ?.name); // Notify form field state
                                });
                              },
                              items:
                                  // (_customRoles
                                  //             ? selectedCompany?.roles
                                  //             :
                                  selectedCompanyType?.roles
                                          .map((Roles companyTypeRoles) {
                                        return DropdownMenuItem<Roles>(
                                          value: companyTypeRoles,
                                          child: Text(companyTypeRoles.name),
                                        );
                                      }).toList() ??
                                      [],
                              decoration: InputDecoration(
                                labelText: 'Role(s)',
                                labelStyle: typography.Subtitle1,
                                hintText: 'Select Role',
                                hintStyle: typography.Body1,
                                border: const OutlineInputBorder(),
                                errorText: state
                                    .errorText, // Display validation error message
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Role(s) is required'; // Add your validation logic here
                                }
                                return null;
                              },
                            )
                          : Center(child: CircularProgressIndicator());
                    },
                  );
                },
              )
            : SizedBox(),
        SizedBox(height: CustomSpacing.four),
        // Admin Name
        TextFormField(
          decoration: InputDecoration(
            // labelText: LanguageService.getTranslated(
            //     context, "usermanagement_name_field_label"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: LanguageService.getTranslated(context,
                        "usermanagement_name_field_label"), // Label text, // Black color for "Name"
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
                context, "usermanagemet_cuser_name_place_holder"),
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
          controller: adminNameController,
        ),
        SizedBox(height: CustomSpacing.four),
        // Admin Email
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            // labelText: LanguageService.getTranslated(
            //     context, "connections_user_connection_email_filter"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: LanguageService.getTranslated(context,
                        "connections_user_connection_email_filter"), // Label text, // Black color for "Name"
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
                context, "user_profile_user_management_email_placeholer"),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || regextest(value) == false) {
              return 'Enter a valid email address';
            }
            // You can add more specific email validation here if needed
            return null;
          },
          controller: adminEmailController,
        ),
        // Admin Mobile
        SizedBox(height: CustomSpacing.four),
        Row(
          children: [
            Expanded(
              child: FormField<String>(
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
                          hintText: _corporateAdminHintText,
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
                            _selectedAdminCorporateCountry = p.isoCode.name;
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
        //           hintText: _corporateAdminHintText,
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
        //             _selectedAdminCorporateCountry = p.isoCode.name;
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
        // Admin Password
        SizedBox(height: CustomSpacing.four),
        TextFormField(
          decoration: InputDecoration(
            // labelText: LanguageService.getTranslated(
            //     context, "emailsetup_field_password"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: LanguageService.getTranslated(context,
                        "emailsetup_field_password"), // Label text, // Black color for "Name"
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
            suffixIcon: IconButton(
              icon: _showPasswordCorporate
                  ? Icon(Icons.visibility)
                  : Icon(Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _showPasswordCorporate = !_showPasswordCorporate;
                });
              },
            ),
          ),
          obscureText: !_showPasswordCorporate,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            // You can add more specific password validation here if needed
            return null;
          },
          controller: adminPasswordController,
        ),
        // Admin Confirm Password
        SizedBox(height: CustomSpacing.four),
        TextFormField(
          decoration: InputDecoration(
            // labelText: LanguageService.getTranslated(
            //     context, "register_corporate_password_field_placeholder"),
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: LanguageService.getTranslated(context,
                        "register_corporate_password_field_placeholder"), // Label text, // Black color for "Name"
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
            suffixIcon: IconButton(
              icon: _showPasswordConfirmationCorporate
                  ? Icon(Icons.visibility)
                  : Icon(Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _showPasswordConfirmationCorporate =
                      !_showPasswordConfirmationCorporate;
                });
              },
            ),
          ),
          obscureText: !_showPasswordConfirmationCorporate,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (value != adminPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          controller: adminConfirmPasswordController,
        ),

        // TextFormField(
        //   decoration: InputDecoration(
        //     labelText: LanguageService.getTranslated(
        //         context, "register_corporate_password_field_placeholder"),
        //     hintText: LanguageService.getTranslated(context,
        //         "register_corporate_confirm_password_field_placeholder"),
        //     border: const OutlineInputBorder(),
        //     suffixIcon: IconButton(
        //       icon: _showPasswordConfirmationCorporate
        //           ? Icon(Icons.visibility)
        //           : Icon(Icons.visibility_off),
        //       onPressed: () {
        //         setState(() {
        //           _showPasswordConfirmationCorporate =
        //               !_showPasswordConfirmationCorporate;
        //         });
        //       },
        //     ),
        //   ),
        //   obscureText: !_showPasswordConfirmationCorporate,
        //   validator: (value) {
        //     if (value == null || value.isEmpty || value.length < 8) {
        //       return 'Password must be at least 8 characters';
        //     }
        //     // You can add more specific password validation here if needed
        //     return null;
        //   },
        //   controller: adminConfirmPasswordController,
        // ),
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
