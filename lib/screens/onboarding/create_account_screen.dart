import 'package:country_list_picker/country_list_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autocomplete_label/autocomplete_label.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/main.dart';
import 'package:green/models/initial_data_model.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/screens/home/dashboard_screen.dart';
import 'package:green/screens/onboarding/splash_screen.dart';
import 'package:phone_input/phone_input_package.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../design_system/repo/home.dart';
import '../../service/language_service.dart';
import '../../utils/utils.dart';

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
  PhoneController mobileController = PhoneController(PhoneNumber(nsn:  '', isoCode: IsoCode.US));
  TextEditingController countryCodeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController _textEditingController = TextEditingController();

  String _selectedCountryCode = '+1';

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
  Companies? selectedCompany;
  String companyName = '';
  String companyId = "";

  String _selectedAdminCountryCode = '+1';

  //bool isNewUser = false;

  @override
  void initState() {
    super.initState();
    _selectedOption = SignUpOptions.individual;
   /* if(widget.userCredential!=null&&widget.userCredential?.user!=null && widget.userCredential!.additionalUserInfo!=null && widget.userCredential!.additionalUserInfo!.isNewUser) {
      setState(() {
        isNewUser = true;
      });
    }*/
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
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
                                LanguageService.getTranslated(context, "login_image_text"),
                            style: CustomTypography.H5_Regular,
                          )),
                        ),
                      ],
                    ),
                    authNotifier.isNewUser
                        ? _almostThereForm()
                    // Create Account Form
                    :_createAccountForm(),
                    // Create Account Button
                    //SizedBox(height: CustomSpacing.four),

                    /*Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RecaptchaV2(
                              apiKey: "6LfXp1UpAAAAAEku9BSeBt6JJxXrlvtYjh--X4D7",
                              apiSecret: "6LfXp1UpAAAAAIFVynIPkooVWZi5qN8u16SYJTVt",
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
                    SizedBox(height: CustomSpacing.eight),
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
                                          if(authNotifier.isNewUser) {
                                            String result = await authNotifier
                                                .signUpIndividualWithGoogle(
                                              widget.userCredential!,
                                              mobileController.value?.nsn??"",
                                              mobileController.value?.countryCode??"",
                                              _selectedRoles,
                                              context,
                                            );
                                            if(result == 'role_assigned') {
                                              /*Navigator.push(context, MaterialPageRoute(builder: (context) => *//*Home(
                                                useLightMode: false,
                                                useMaterial3: true,
                                                colorSelected: ColorSeed.baseColor,
                                                imageSelected: ColorImageProvider.leaves,
                                                handleBrightnessChange: handleBrightnessChange,
                                                handleMaterialVersionChange: handleMaterialVersionChange,
                                                handleColorSelect: handleColorSelect,
                                                handleImageSelect: handleImageSelect,
                                                colorSelectionMethod: ColorSelectionMethod.colorSeed,
                                              )*//*HomeScreen()));*/
                                              FirebaseAuth.instance.signOut();

                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      LanguageService.getTranslated(context,"register_non_corporate_success_status_title"),


                                                      style: CustomTypography.ButtonLarge,),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => App()));
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.arrow_back),
                                                            SizedBox(width: CustomSpacing.four),
                                                            Text('Back to Login'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          }
                                          else if (_selectedOption ==
                                              SignUpOptions.individual) {
                                            print('Individual Account');
                                            print('Name: ${nameController.text}');
                                            print(
                                                'Display Name: ${displayNameController.text}');
                                            print('Email: ${emailController.text}');
                                            print(
                                                'Mobile: $_selectedCountryCode ${mobileController.value?.nsn??""}');
                                            print('Roles: $_selectedRoles');
                                            print('Account Type: $_selectedOption');
                                            authNotifier
                                                .signUpIndividualWithEmailAndPassword(
                                              emailController.text,
                                              passwordController.text,
                                              nameController.text,
                                              displayNameController.text,
                                              mobileController.value?.nsn??"",
                                              mobileController.value?.countryCode??"",
                                              _selectedRoles,
                                              context,
                                            );
                                          }
                                          else {
                                            print('Corporate Account');
                                            print(
                                                'Company Legal Name: ${companyName}');
                                            print(
                                                'Company Type: $selectedCompanyType');
                                            print(
                                                'Company Display Name: ${companyDisplayNameController.text}');
                                            print('Admin Email: ${adminEmailController.text}');
                                            print(
                                                'Admin Mobile: $_selectedAdminCountryCode ${adminMobileController.text}');
                                            print('Roles: $_selectedRoles');
                                            print('Account Type: $_selectedOption');
                                            authNotifier
                                                .signUpCorporateWithEmailAndPassword(
                                              companyId,
                                              companyName,
                                              selectedCompanyType!,
                                              companyDisplayNameController.text,
                                              adminNameController.text,
                                              adminEmailController.text,
                                              mobileController.value?.countryCode??"",

                                              mobileController.value?.nsn??"",
                                              adminPasswordController.text,
                                              !_enableCompanyTypeDropdown?selectedCompanyRole: Roles(isForIndividual: true, isApplicableForTrial: false, role: "admin", name: "Admin", isMultipleRoleEnabled: false, id: ""),
                                              context,
                                              selectedCompany,
                                            );

                                          }
                                        }
                                      },
                                      child: Text(
                                        // If selected roles contains a role with trial period, show 'Start Trial' else 'Create Account'
                                        _selectedRoles.any(
                                                (role) => role.isApplicableForTrial)
                                            ? LanguageService.getTranslated(context,"register_non_corporate_freetrail_btn")
                                            : LanguageService.getTranslated(context,"usermanagement_cuser_create_account_btn"),
                                        style:
                                            CustomTypography.ButtonLarge.copyWith(
                                                color: Colors.black),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }

  _createAccountForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              _selectedOption == SignUpOptions.individual
                  ? LanguageService.getTranslated(context,"register_non_corporate_create_user_account_title")
                  :
              LanguageService.getTranslated(context,"register_corporate_create_corporate_act_title"),
              style: CustomTypography.H5_Regular.copyWith(
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
                  title:  Text(
                      LanguageService.getTranslated(context,"register_non_corporate_radio_Individual")
                  ),
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
                  title:  Text(
                      LanguageService.getTranslated(context,"register_non_corporate_radio_Corporate")
                      ),
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
          SizedBox(height: CustomSpacing.eight),
          _selectedOption == SignUpOptions.individual
              ? _individualAccountUI()
              : _corporateAccountUI(),
        ],
      ),
    );
  }

  _almostThereForm() {
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
              style: CustomTypography.H5_Regular.copyWith(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Social Media Buttons
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return SocialMediaButton(
              onPressed: () async {
                // Add your onPressed function here
                await authNotifier.signInWithGoogle(context: context);
              },
              buttonText:
              LanguageService.getTranslated(context,"login_googlebutton"),
              iconPath: 'assets/images/googleLogo.svg',
            );
          }
        ),
        SizedBox(
          height: CustomSpacing.one,
        ),
        SocialMediaButton(
          onPressed: () {
            // Add your onPressed function here
          },
          buttonText: LanguageService.getTranslated(context,"login_microsoft_button"),
          iconPath: 'assets/images/microsoftLogo.svg',
        ),
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
              LanguageService.getTranslated(context,"register_non_corporate_register_manually"),
              style: CustomTypography.Subtitle1.copyWith(
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
            labelText:

            LanguageService.getTranslated(context,"user_profile_user_management_name_filed_label"),

            hintText:   LanguageService.getTranslated(context,"user_profile_user_management_name_placeholder"),

            hintStyle: CustomTypography.Body1,
            labelStyle: CustomTypography.Body1,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.contains(RegExp(r'[0-9]'))) {
              return 'Name is required and should not be empty or contain numbers';
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
            labelText:   LanguageService.getTranslated(context,"usermanagement_display_name_field_label"),

            hintText:  LanguageService.getTranslated(context,"usermanagement_display_name_placeholder"),
            hintStyle: CustomTypography.Body1,
            labelStyle: CustomTypography.Body1,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.startsWith(RegExp(r'[0-9]')) ||
                value.contains(RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%0-9]'))) {
              return 'Display name is required, should not start with a number and should not contain special characters';
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
            labelText: LanguageService.getTranslated(context,"register_non_corporate_emailfield_label"),

            hintText: LanguageService.getTranslated(context,"register_non_corporate_emailfield_placeholder"),

            hintStyle: CustomTypography.Body1,
            labelStyle: CustomTypography.Body1,
            border: const OutlineInputBorder(),
          ),
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
              child: PhoneInput(
                key: const Key('phone-field'),
                controller: mobileController,
                shouldFormat: true,
                defaultCountry: IsoCode.US,
                decoration: InputDecoration(
                  labelText: LanguageService.getTranslated(context, "register_mobile_number"),
                  hintText: LanguageService.getTranslated(context, "register_non_corporate_mobilefield_placeholder"),
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
                  if(p==null)
                    return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
                onSaved: (PhoneNumber? p) {
                  if(p==null)
                    return;
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
        // Password
        TextFormField(
          decoration: InputDecoration(
            labelText:LanguageService.getTranslated(context,"register_non_corporate_passwordfield_label"),

            hintText: LanguageService.getTranslated(context,"register_corporate_password_field_placeholder"),

            border: const OutlineInputBorder(),
          ),
          obscureText: true,
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
            labelText:  LanguageService.getTranslated(context,"register_corporate_confirm_password_field_label"),

            hintText:LanguageService.getTranslated(context,"register_corporate_confirm_password_field_placeholder"),

            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            // You can add more specific password validation here if needed
            return null;
          },
          controller: confirmPasswordController,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Text(
              LanguageService.getTranslated(context,"categorymanagement_category_role_field_label"),

              style: CustomTypography.Subtitle1.copyWith(
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
                      showCorporateSwitch: true,
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
                labelText:  LanguageService.getTranslated(context,"register_non_corporate_role_field_label"),

                hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
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
                          showCorporateSwitch: true,
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
                              label: Text(value.name),
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

  _signUpAdditionFields() {
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
                  labelText: LanguageService.getTranslated(context, "register_mobile_number"),
                  hintText: LanguageService.getTranslated(context, "register_non_corporate_mobilefield_placeholder"),
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
                  if(p==null)
                    return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
                onSaved: (PhoneNumber? p) {
                  if(p==null)
                    return;
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
              LanguageService.getTranslated(context,"register_non_corporate_role_field_label"),

              style: CustomTypography.Subtitle1.copyWith(
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
                labelText:   LanguageService.getTranslated(context,"usermanagement_roles_label"),
                hintText: _selectedRoles.isEmpty ?  LanguageService.getTranslated(context,"usermanagement_cuser_roles_placeholder") : "",
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
                          label: Text(value.name),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Company Legal Name
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<Companies>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty || authNotifier.companyList == null) {
                      return const Iterable<Companies>.empty();
                    }
                    return authNotifier.companyList!.where((Companies option) {
                      return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
                        ),
                        child: Container(
                          height: 52.0 * options.length,
                          width: MediaQuery.of(context).size.width, // Adjust the width to fit your needs
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: false,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option.name, style: CustomTypography.Subtitle1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (Companies selection) {
                    setState(() {
                      selectedCompany = selection;
                      companyName = selection.name;
                      companyId = selection.id;
                      selectedCompanyType = authNotifier.companyTypeList?.firstWhere((element) => element.id == selection.companyTypeId);
                      companyDisplayNameController.text = selection.displayName;
                      _enableCompanyTypeDropdown = false;
                      _customRoles = true;
                    });
                  },
                  displayStringForOption: (Companies option) => option.name,
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onFieldSubmitted: (_) {},
                      onChanged: (value) {
                        setState(() {
                          companyId = "";
                          _showRoles = false;
                          _showCompanyType = false;
                          selectedCompany = null;
                          selectedCompanyType = null;
                          _enableCompanyTypeDropdown = true;
                          _customRoles = false;
                          companyName = value;
                        });
                        Future.delayed(Duration(milliseconds: 1), () {
                          setState(() {
                            _showCompanyType = true;
                            _showRoles = true;
                          });
                        });
                      },
                      decoration: InputDecoration(
                        labelText:   LanguageService.getTranslated(context,"register_corporate_legalname_field_label"),

                        hintText:   LanguageService.getTranslated(context,"register_corporate_legalname_filed_placeholder"),

                        border: const OutlineInputBorder(),
                      ),
                    );
                  },
                );

              },
            );
          },
        ),

        SizedBox(height: CustomSpacing.four),
        // Company Type
        Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return FormField<String>(
              builder: (FormFieldState<String> state) {
                return _showCompanyType?IgnorePointer(
                  ignoring: !_enableCompanyTypeDropdown,
                  child: DropdownButtonFormField<CompanyType>(
                    value: selectedCompanyType, // Provide the currently selected value

                    onChanged: (CompanyType? newValue) {
                      setState(() {
                        _showRoles = false;
                        selectedCompanyRole = null;
                        selectedCompanyType = newValue; // Update the selected value
                        state.didChange(null); // Reset validation state
                      });
                      Future.delayed(Duration(milliseconds: 1), () {
                        setState(() {
                          _showRoles = true;
                        });
                      });
                    },
                    items: authNotifier.companyTypeList?.map((CompanyType companyType) {
                      return DropdownMenuItem<CompanyType>(
                        value: companyType,
                        child: Text(companyType.name),
                      );
                    }).toList() ?? [],
                    decoration: InputDecoration(
                      enabled: _enableCompanyTypeDropdown,
                      labelText:   LanguageService.getTranslated(context,"register_corporate_company_type_field_label"),
                      hintText:  LanguageService.getTranslated(context,"register_corporate_company_type_field_placeholder"),

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
                ):Center(
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
            labelText:   LanguageService.getTranslated(context,"register_corporate_company_displayname_field_label"),
            hintText:   LanguageService.getTranslated(context,"register_corporate_comapny_displayname_field_placeholder"),

            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.contains(RegExp(r'[0-9]'))) {
              return 'Company display name is required and should not be empty or contain numbers';
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
              _enableCompanyTypeDropdown?'Admin':'User & Role(s)',
              style: CustomTypography.Subtitle1.copyWith(
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
        !_enableCompanyTypeDropdown?Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {

            return FormField<String>(
              builder: (FormFieldState<String> state) {
                return _showRoles ? DropdownButtonFormField<Roles>(
                  onChanged: (Roles? newValue) {
                    setState(() {
                      selectedCompanyRole = newValue;
                      state.didChange(newValue?.name); // Notify form field state
                    });
                  },
                  items: (_customRoles?selectedCompany?.roles:selectedCompanyType?.roles)?.map((Roles companyTypeRoles) {
                    return DropdownMenuItem<Roles>(
                      value: companyTypeRoles,
                      child: Text(companyTypeRoles.name),
                    );
                  }).toList() ?? [],
                  decoration: InputDecoration(
                    labelText: 'Role(s)',
                    labelStyle: CustomTypography.Subtitle1,
                    hintText: 'Select Role',
                    hintStyle: CustomTypography.Body1,
                    border: const OutlineInputBorder(),
                    errorText: state.errorText, // Display validation error message
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Role(s) is required'; // Add your validation logic here
                    }
                    return null;
                  },
                ) : Center(child: CircularProgressIndicator());
              },
            );
          },
        ):SizedBox(),
        SizedBox(height: CustomSpacing.four),
        // Admin Email
        TextFormField(
          decoration: InputDecoration(
            labelText:   LanguageService.getTranslated(context,"usermanagement_name_field_label"),
            hintText:   LanguageService.getTranslated(context,"usermanagemet_cuser_name_place_holder"),

            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.contains(RegExp(r'[0-9]'))) {
              return 'Name is required and should not be empty or contain numbers';
            }
            // You can add more specific email validation here if needed
            return null;
          },
          controller: adminNameController,
        ),
        SizedBox(height: CustomSpacing.four),
        // Admin Email
        TextFormField(
          decoration: InputDecoration(
            labelText:   LanguageService.getTranslated(context,"connections_user_connection_email_filter"),

            hintText:  LanguageService.getTranslated(context,"user_profile_user_management_email_placeholer"),

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
              child: PhoneInput(
                key: const Key('phone-field'),
                controller: mobileController,
                shouldFormat: true,
                defaultCountry: IsoCode.US,
                decoration: InputDecoration(
                  labelText: LanguageService.getTranslated(context, "register_mobile_number"),
                  hintText: LanguageService.getTranslated(context, "register_non_corporate_mobilefield_placeholder"),
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
                  if(p==null)
                    return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
                onSaved: (PhoneNumber? p) {
                  if(p==null)
                    return;
                  setState(() {
                    _selectedCountryCode = p.countryCode;
                  });
                  print('changed ${p.countryCode}');
                },
              ),
            ),
          ],
        ),
        // Admin Password
        SizedBox(height: CustomSpacing.four),
        TextFormField(
          decoration: InputDecoration(
            labelText:   LanguageService.getTranslated(context,"emailsetup_field_password"),

            hintText:   LanguageService.getTranslated(context,"register_corporate_password_field_placeholder"),

            border: const OutlineInputBorder(),
          ),
          obscureText: true,
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
            labelText:   LanguageService.getTranslated(context,"register_corporate_password_field_placeholder"),
            hintText:   LanguageService.getTranslated(context,"register_corporate_confirm_password_field_placeholder"),

            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            // You can add more specific password validation here if needed
            return null;
          },
          controller: adminConfirmPasswordController,
        ),
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

  void handleBrightnessChange(bool useLightMode) {
  }

  void handleMaterialVersionChange() {
  }

  void handleColorSelect(int value) {
  }

  void handleImageSelect(int value) {
  }

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
          pattern = r'^01(?:0|1|[6-9])-(?:\d{3}|\d{4})-\d{4}$'; // South Korea phone number format
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

}


