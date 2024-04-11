import 'package:country_list_picker/country_list_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autocomplete_label/autocomplete_label.dart';
import 'package:flutter_recaptcha_v2_compat/flutter_recaptcha_v2_compat.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/initial_data_model.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/screens/home/home_screen.dart';
import 'package:green/screens/onboarding/splash_screen.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../design_system/repo/home.dart';
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
  TextEditingController mobileController = TextEditingController();
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
                            "Manage your Risk Profile",
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
                                            print('Individual Account');
                                            String result = await authNotifier
                                                .signUpIndividualWithGoogle(
                                              widget.userCredential!,
                                              mobileController.text,
                                              _selectedCountryCode,
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
                                                    title: Text('Your account has been successfully activated.', style: CustomTypography.ButtonLarge,),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
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
                                                'Mobile: $_selectedCountryCode ${mobileController.text}');
                                            print('Roles: $_selectedRoles');
                                            print('Account Type: $_selectedOption');
                                            authNotifier
                                                .signUpIndividualWithEmailAndPassword(
                                              emailController.text,
                                              passwordController.text,
                                              nameController.text,
                                              displayNameController.text,
                                              mobileController.text,
                                              _selectedCountryCode,
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
                                              companyName,
                                              selectedCompanyType!,
                                              companyDisplayNameController.text,
                                              adminNameController.text,
                                              adminEmailController.text,
                                              _selectedAdminCountryCode,

                                              adminMobileController.text,
                                              adminPasswordController.text,
                                              !_enableCompanyTypeDropdown?selectedCompanyRole:null,
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
                                            ? 'Start your 7-day free trial'
                                            : 'Create Account',
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
                  ? 'Create a user account'
                  : 'Do you want to create a corporate account?',
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
                  title: const Text('Individual'),
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
                  title: const Text('Corporate'),
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
              buttonText: 'Continue with Google',
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
          buttonText: 'Continue with Microsoft',
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
              'Or register manually',
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
            labelText: 'Name',
            hintText: 'Enter your name',
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
            labelText: 'Display Name',
            hintText: 'Enter display name',
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
            labelText: 'Email',
            hintText: 'Enter your email address',
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
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CountryListPicker(
                    initialCountry: Countries.United_States,
                    border: InputBorder.none,
                    flagSize: Size(35, 30),
                    onChanged: (code) {
                      setState(() {
                        _selectedCountryCode = code;
                      });
                    },
                    diallingCodeStyle: CustomTypography.Body1,
                    isShowInputField: false,
                    dialogTheme: DialogThemeData(
                      style: CustomTypography.Body1,
                      isShowFloatButton: false,
                    ),
                    countryNameStyle: CustomTypography.Body1,
                    isShowCountryName: false,
                    onCountryChanged: (country) {
                      print('This is the country code: $country');
                      setState(() {
                        _selectedCountryCode = country.dialing_code;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: CustomSpacing.two),

            // Mobile Number TextFormField
            Expanded(
              flex: 7,
              child: TextFormField(
                keyboardType: TextInputType.number,
                maxLength: 10,
                // Numeric keyboard
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly // Only allows digits
                ],
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                    return 'Mobile number can only contain digits';
                  }
                  return null;
                },
                controller: mobileController,
              ),
            ),
            // Dropdown Icon Suffix
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        // Password
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter new password',
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
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password to confirm',
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
              "Roles",
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
                labelText: 'Role(s)',
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
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CountryListPicker(
                    initialCountry: Countries.United_States,
                    border: InputBorder.none,
                    flagSize: Size(35, 30),
                    onChanged: (code) {
                      setState(() {
                        _selectedCountryCode = code;
                      });
                    },
                    diallingCodeStyle: CustomTypography.Body1,
                    isShowInputField: false,
                    dialogTheme: DialogThemeData(
                      style: CustomTypography.Body1,
                      isShowFloatButton: false,
                    ),
                    countryNameStyle: CustomTypography.Body1,
                    isShowCountryName: false,
                    onCountryChanged: (country) {
                      print('This is the country code: $country');
                      setState(() {
                        _selectedCountryCode = country.dialing_code;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: CustomSpacing.two),

            // Mobile Number TextFormField
            Expanded(
              flex: 7,
              child: TextFormField(
                keyboardType: TextInputType.number,
                maxLength: 10,
                // Numeric keyboard
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly // Only allows digits
                ],
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                    return 'Mobile number can only contain digits';
                  }
                  return null;
                },
                controller: mobileController,
              ),
            ),
            // Dropdown Icon Suffix
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Text(
              "Roles",
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
                labelText: 'Role(s)',
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
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
                      ),
                      child: Container(
                        height: 52.0 * options.length,
                        width: constraints.biggest.width + 100, // <-- Right here !
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
                  ),
                  onSelected: (Companies selection) {
                    setState(() {
                      selectedCompany = selection;
                      companyName = selection.name;
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
                      onFieldSubmitted: (_) {

                      },
                      onChanged: (value) {
                        setState(() {
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
                        labelText: 'Company Legal Name',
                        hintText: 'Enter the legal name of your company',
                        border: const OutlineInputBorder(),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),

        SizedBox(height: CustomSpacing.two),
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
                      labelText: 'Company Type',
                      hintText: 'Select company type',
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



        SizedBox(height: CustomSpacing.two),
        // Company Display Name
        TextFormField(
          decoration: InputDecoration(
            enabled: _enableCompanyTypeDropdown,
            labelText: 'Company Display Name',
            hintText: 'Enter the display name of your company',
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
        SizedBox(height: CustomSpacing.eight),
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
        SizedBox(height: CustomSpacing.eight),
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
        SizedBox(height: CustomSpacing.two),
        // Admin Email
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter user name',
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
        SizedBox(height: CustomSpacing.two),
        // Admin Email
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
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
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [

            Expanded(
              flex: 4,
              child:
                  Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CountryListPicker(
                    initialCountry: Countries.United_States,
                    border: InputBorder.none,
                    flagSize: Size(35, 30),
                    onChanged: (code) {
                      setState(() {
                        _selectedAdminCountryCode = code;
                      });
                    },
                    diallingCodeStyle: CustomTypography.Body1,
                    isShowInputField: false,
                    dialogTheme: DialogThemeData(
                      style: CustomTypography.Body1,
                      isShowFloatButton: false,
                    ),
                    countryNameStyle: CustomTypography.Body1,
                    isShowCountryName: false,
                    onCountryChanged: (country) {
                      print('This is the country code: $country');
                      setState(() {
                        _selectedAdminCountryCode = country.dialing_code;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: CustomSpacing.two),

            // Mobile Number TextFormField
            Expanded(
              flex: 7,
              child: TextFormField(
                keyboardType: TextInputType.number,
                // Numeric keyboard
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly // Only allows digits
                ],
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter your mobile number',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Mobile number can only contain digits';
                  }
                  return null;
                },
                controller: adminMobileController,
              ),
            ),
            // Dropdown Icon Suffix
          ],
        ),
        // Admin Password
        SizedBox(height: CustomSpacing.two),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter new password',
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
        SizedBox(height: CustomSpacing.two),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password to confirm',
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
}


