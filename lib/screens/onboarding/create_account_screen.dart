import 'package:country_list_picker/country_list_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autocomplete_label/autocomplete_label.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/initial_data_model.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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

  /// Corporate account UI
  TextEditingController companyLegalNameController = TextEditingController();
  TextEditingController companyTypeController = TextEditingController();
  TextEditingController companyDisplayNameController = TextEditingController();
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
  Comapnies? selectedCompany;
  String companyName = '';

  String _selectedAdminCountryCode = '+1';

  bool isNewUser = false;

  @override
  void initState() {
    super.initState();
    _selectedOption = SignUpOptions.individual;
    if(widget.userCredential!=null&&widget.userCredential?.user!=null && widget.userCredential!.additionalUserInfo!=null && widget.userCredential!.additionalUserInfo!.isNewUser) {
      setState(() {
        isNewUser = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
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
                isNewUser
                    ? _almostThereForm()
                // Create Account Form
                :_createAccountForm(),
                // Create Account Button
                SizedBox(height: CustomSpacing.eight),
                Consumer<AuthNotifier>(builder: (context, authNotifier, child) {
                  return Row(
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
                                      if(isNewUser) {
                                        print('Individual Account');
                                        String result = await authNotifier
                                            .signUpIndividualWithGoogle(
                                          widget.userCredential!,
                                          mobileController.text,
                                          _selectedCountryCode,
                                          _selectedRoles,
                                        );
                                        if(result == 'role_assigned') {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => Home(
                                            useLightMode: false,
                                            useMaterial3: true,
                                            colorSelected: ColorSeed.baseColor,
                                            imageSelected: ColorImageProvider.leaves,
                                            handleBrightnessChange: handleBrightnessChange,
                                            handleMaterialVersionChange: handleMaterialVersionChange,
                                            handleColorSelect: handleColorSelect,
                                            handleImageSelect: handleImageSelect,
                                            colorSelectionMethod: ColorSelectionMethod.colorSeed,
                                          )));
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
                                          adminEmailController.text,
                                          _selectedAdminCountryCode,
                                          adminMobileController.text,
                                          adminPasswordController.text,
                                          !_enableCompanyTypeDropdown?selectedCompanyRole:null,
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
                  );
                }),
              ],
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
            // Country Code Dropdown
            /* DropdownMenu<IconLabel>(
                initialSelection: IconLabel.smile,
                controller: iconController,
                leadingIcon: const Icon(Icons.search),
                label: const Text('Icon'),
                dropdownMenuEntries: iconEntries,
                onSelected: (icon) {
                  setState(() {
                    selectedIcon = icon;
                  });
                },
              ),*/
            Expanded(
              flex: 4,
              child: /*Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // Filter the countryCodes based on the input text
                  return countryCodes.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String value) {
                  setState(() {
                    _selectedCountryCode = value;
                  });
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      labelText: 'Code',
                      hintText: '+ 1',
                      border: const OutlineInputBorder(),
                    ),
                  );
                },

              ),*/
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
                    return OptionsBottomSheet(
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
                        return OptionsBottomSheet(
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
                    return OptionsBottomSheet(
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
                        return OptionsBottomSheet(
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
                return Autocomplete<Comapnies>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty || authNotifier.companyList == null) {
                      return const Iterable<Comapnies>.empty();
                    }
                    return authNotifier.companyList!.where((Comapnies option) {
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
                  onSelected: (Comapnies selection) {
                    setState(() {
                      selectedCompany = selection;
                      companyName = selection.name;
                      selectedCompanyType = authNotifier.companyTypeList?.firstWhere((element) => element.id == selection.companyTypeId);
                      companyDisplayNameController.text = selection.displayName;
                      _enableCompanyTypeDropdown = false;
                      _customRoles = true;
                    });

                  },
                  displayStringForOption: (Comapnies option) => option.name,
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

class OptionsBottomSheet extends StatefulWidget {
  final List<String> options;
  final List<Categories> selectedRoles;
  final Function(Categories) addChip;
  final Function(Categories) removeChip;
  final Function() removeAllChips;
  final SignUpOptions selectedOption;
  final Function(SignUpOptions) onOptionChanged;
  final bool showCorporateSwitch;

  const OptionsBottomSheet({super.key,
    required this.options,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.removeAllChips,
    required this.showCorporateSwitch,
  });

  @override
  OptionsBottomSheetState createState() => OptionsBottomSheetState();
}

class OptionsBottomSheetState extends State<OptionsBottomSheet> {
  Set<String> _selectedOptions = Set<String>();

  late final List<Map<String, dynamic>> filteredOptionsIndividual;
  late final List<Map<String, dynamic>> filteredOptionsCorporate;

  @override
  void initState() {
    super.initState();
    // Extract individual and corporate options from JSON data
    // Accessing AuthNotifier using Provider.of
    // Accessing AuthNotifier using Provider.of
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    // Filtering role list for individual and corporate options
    filteredOptionsIndividual = (authNotifier.roleList ?? [])
        .where((role) => role.accountType == 'individual')
        .expand((role) =>
            (role.categories ?? []).map((category) => category.toJson()))
        .toList();

    filteredOptionsCorporate = (authNotifier.roleList ?? [])
        .where((role) => role.accountType == 'corporate')
        .expand((role) =>
            (role.categories ?? []).map((category) => category.toJson()))
        .toList();

    _updateSelectedOptions();
  }

  void _updateSelectedOptions() {
    setState(() {
      _selectedOptions.clear();
      final selectedOptionsList =
          widget.selectedOption == SignUpOptions.individual
              ? filteredOptionsIndividual
              : filteredOptionsCorporate;
      print("Selected options: $selectedOptionsList");
      _selectedOptions.addAll(
        widget.selectedRoles.map((role) {
          print(role);
          final option = selectedOptionsList.firstWhere(
            (option) => option['name'] == role.name,
            orElse: () => {'name': role.name, 'id': null},
          );
          return option?['role'];
        }).whereType<String>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> allOptions =
        widget.selectedOption == SignUpOptions.individual
            ? filteredOptionsIndividual
            : filteredOptionsCorporate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, top: 24),
              child: Text('Select Account Roles',
                  style: CustomTypography.Subtitle1.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Container(
              margin: const EdgeInsets.only(right: 24, top: 24),
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allOptions.length,
                itemBuilder: (context, index) {
                  final option = allOptions[index];
                  final accountType = option['name'];
                  final id = option['role'];
                  final bool isSelected = _selectedOptions.contains(id);

                  return ListTile(
                    title: Text(accountType),
                    leading: widget.selectedOption == SignUpOptions.individual
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected!) {
                                  _selectedOptions.add(id);
                                  widget.addChip(Categories.fromJson(option));
                                } else {
                                  _selectedOptions.remove(id);
                                  widget
                                      .removeChip(Categories.fromJson(option));
                                }
                              });
                            },
                          )
                        : Radio<String>(
                            value: id,
                            groupValue: _selectedOptions.isNotEmpty
                                ? _selectedOptions.first
                                : null,
                            onChanged: (value) {
                              setState(() {
                                if (_selectedOptions.isNotEmpty) {
                                  final previousSelection =
                                      _selectedOptions.first;
                                  final previousRole = allOptions.firstWhere(
                                      (option) =>
                                          option['id'] ==
                                          previousSelection)['role'];
                                  widget.removeChip(
                                      Categories.fromJson(previousRole));
                                }
                                _selectedOptions.clear();
                                if (value != null) {
                                  _selectedOptions.add(value);
                                  widget.addChip(Categories.fromJson(option));
                                }
                              });
                            },
                          ),
                  );
                },
              ),
              widget.showCorporateSwitch?const Divider():SizedBox(),
              widget.showCorporateSwitch?Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        widget.onOptionChanged(
                            widget.selectedOption == SignUpOptions.individual
                                ? SignUpOptions.corporate
                                : SignUpOptions.individual);
                        widget.removeAllChips(); // Clear all chips
                        Navigator.pop(context);
                        /*showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (BuildContext context) {
                            return OptionsBottomSheet(
                              options: roles,
                              selectedRoles: [], // Pass an empty list to reset the chips
                              addChip: widget.addChip,
                              removeChip: widget.removeChip,
                              removeAllChips: widget.removeAllChips,
                              selectedOption: widget.selectedOption == SignUpOptions.individual
                                  ? SignUpOptions.corporate
                                  : SignUpOptions.individual,
                              onOptionChanged: widget.onOptionChanged,
                            );
                          },
                        );*/
                      },
                      child: Text(
                        widget.selectedOption == SignUpOptions.individual
                            ? 'SWITCH TO CORPORATE'
                            : 'SWITCH TO INDIVIDUAL',
                        style: CustomTypography
                            .Subtitle1, // Adjust text color if needed
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${widget.selectedOption != SignUpOptions.individual ? 'Individual' : 'Corporate'} account roles",
                          style: CustomTypography.Subtitle1,
                        ),
                        SvgPicture.asset(
                          'assets/images/down_icon.svg',
                        )
                      ],
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
              ):SizedBox(),
              widget.showCorporateSwitch?const Divider():SizedBox(),
              widget.showCorporateSwitch? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedOption == SignUpOptions.individual
                    ? filteredOptionsCorporate.length
                    : filteredOptionsIndividual.length,
                itemBuilder: (context, index) {
                  final option =
                      widget.selectedOption == SignUpOptions.individual
                          ? filteredOptionsCorporate[index]
                          : filteredOptionsIndividual[index];
                  final accountType = option['name'];
                  final id = option['role'];

                  return ListTile(
                    title: Text(accountType),
                    leading: widget.selectedOption == SignUpOptions.individual
                        ? Radio<String>(
                            value: id,
                            groupValue: null,
                            onChanged: null,
                          )
                        : Checkbox(
                            value: false,
                            onChanged: null,
                          ),
                  );
                },
              ):SizedBox(),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('SUBMIT', style: CustomTypography.Subtitle1),
        ),
      ],
    );
  }
}
