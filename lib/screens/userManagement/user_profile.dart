import 'dart:async';
import 'dart:io';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/components/expandable_card_container.dart';
import 'package:green/models/networking_model.dart';
import 'package:green/service/language_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_input/phone_input_package.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/custom_flexible_roles_bottom_sheet.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../models/initial_data_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/shared_preference_service.dart';import 'package:image/image.dart' as img;

import '../../utils/utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.connectionList;
  List<Categories> _selectedRoles = [];
  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();
  PhoneController phoneController = PhoneController(PhoneNumber(isoCode: IsoCode.US, nsn: ''));

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // form key
  final _formKey = GlobalKey<FormState>();

  bool isEdit = false;

  bool showAssignDeleteManager = true;
  bool showAddDelegate = true;
  bool showRevokeDelegate = true;
  bool showAddReportee = true;
  bool showEditUser = true;
  bool showMyTeams = true;
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;

  // General Info
  String userImageUrl = '';
  TextEditingController _nameGeneralInfoController = TextEditingController();
  TextEditingController _displayNameGeneralInfoController =
      TextEditingController();
  TextEditingController _emailGeneralInfoController = TextEditingController();
  TextEditingController _phoneGeneralInfoController = TextEditingController();
  String nameLabelText = "";
  String displayNameLabelText = "";
  String emailLabelText = "";
  String phoneLabelText = "";
  String selectedAvatar = "";
  String selectedCountryCode = "+1";

  // My Team
  Timer? deBouncer;
  List<NetworkingUsers> _managerList = [];
  NetworkingUsers? _selectedManager;

  bool _tabsLoading = true;
  int _tabLength = 3;

  void debounce(
      VoidCallback callback, {
        Duration duration = const Duration(seconds: 1),
      }) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  @override
  void initState() {
    super.initState();
    _setClaims();
    _getData();
  }
  
  _setClaims() async {
    _selectedScreen = Screens.generalInfo;
    /*isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.IS_PG_ADMIN)??false;
    isAdmin = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.IS_ADMIN)??false;
    isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.IS_SUPER_ADMIN)??false;*/
    isPgAdmin = false;
    isAdmin = true;
    isSuperAdmin = true;
    showAssignDeleteManager = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMAM)?? false;
    showAddDelegate = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMDA)??false;
    showRevokeDelegate = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMRD)??false;
    showAddReportee = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMRE)??false;
    //showEditUser = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CAMVC)??false;
    print('1st claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMEU)?? false}');
    print('2nd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMEU)??false}');
    print('3rd claim: ${await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPEU)??false}');
    showEditUser = (await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMEU)??false)||((await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.CUMEU)??false)||(await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPEU)??false));
    bool showNonCorporateMyTeams = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.NCMMT)??false;
    bool showEmployeeMyTeams = await SharedPreferenceService.getClaimForSubfeature(SharedPreferenceService.EMPMT)??false;
    User user = FirebaseAuth.instance.currentUser!;
    await user.getIdTokenResult().then((value) {
      if (value.claims != null) {
        if(value.claims!['isIndividual'] == true) {
          showMyTeams = showNonCorporateMyTeams;
          print('isIndividual: $showMyTeams');
        } else if(value.claims!['internal'] == true) {
          showMyTeams = showEmployeeMyTeams;
          print('isInternal: $showMyTeams');
      } else {
          showMyTeams = true;
         print('external: $showMyTeams');
        }
    }});


    if(!showMyTeams) {
      _tabLength = 2;
    }

    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController?.addListener(() {
      if(_tabLength == 3) {
        if (_tabController?.index == 0) {
          setState(() {
            _selectedScreen = Screens.generalInfo;
          });
        } else if (_tabController?.index == 1) {
          setState(() {
            _selectedScreen = Screens.teamsScreen;
          });
        } else if (_tabController?.index == 2) {
          setState(() {
            _selectedScreen = Screens.securityScreen;
          });
        }
      } else if(_tabLength == 2) {
        if (_tabController?.index == 0) {
          setState(() {
            _selectedScreen = Screens.generalInfo;
          });
        } else if (_tabController?.index == 1) {
          setState(() {
            _selectedScreen = Screens.securityScreen;
          });
        }
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
    setState(() {
      _tabsLoading = false;
    });

  }

  _getData() {
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAllUserData(context, '', '')
        .then((value) {
      if (value != null) {
        setState(() {
          userImageUrl = value.displayImageUrl ?? "";
          nameLabelText = value.name ?? "";
          _nameGeneralInfoController.text = value.name ?? "";
          displayNameLabelText = value.displayName ??  value.name ?? "";
          _displayNameGeneralInfoController.text = value.displayName ?? value.name ?? "";
          emailLabelText = value.email ?? "";
          _emailGeneralInfoController.text = value.email ?? "";
          phoneLabelText = value.phone ?? "";
          _phoneGeneralInfoController.text = value.phone ?? "";
          print('Country Code: ${value.countryCode}');
          // remove '+' from country code
          _selectedCountryCode = value.countryCode?.replaceAll('+', '') ?? "1";
          print('Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
          phoneController.value = PhoneNumber(isoCode:countryCodeToIsoCode[_selectedCountryCode]?.first??IsoCode.US, nsn: phoneLabelText??"");
          // Set roles and assign from List<Roles> to List<Categories>
          _selectedRoles = (value.role ?? []).map((role) => Categories(
              id: role.id ?? "",
              name: role.name ?? "",
              role: role.role ?? "", isForIndividual: role.isForIndividual ?? false,
              isMultipleRoleEnabled: role.isMultipleRoleEnabled ?? false,
              isApplicableForTrial: role.isApplicableForTrial ?? false,

          )).toList();
          _selectedCountryCode = value.countryCode ?? "+1";

        });
      }
    });
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAvatarUrls(context);
    Provider.of<UserProfileProvider>(context, listen: false)
        .getUserTeamMembers(context);
  }

  Future<List<NetworkingUsers>> searchNetworks(String query) async => Provider.of<UserProfileProvider>(context, listen: false)
        .getUserSuggestions(context, query);

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: themeProvider.getTheme.colorScheme.background,
          appBar: CustomAppBar(
            isExpanded: _isExpanded,
            showNotificationDot: _showNotificationDot,
            onExpandPressed: (isExpanded) {
              setState(() {
                _isExpanded = isExpanded;
              });
            },
            onSearchPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            stopNavigateToProfile: _selectedScreen == Screens.generalInfo,
          ),
          drawer: CustomDrawer(),
          body: _tabsLoading?Column(children: [
            SizedBox(height: CustomSpacing.four,),
            Center(child: CircularProgressIndicator(),)
          ],):PopScope(
            canPop: _selectedScreen == Screens.generalInfo,
            onPopInvoked: (canPop) {
              print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
              if (_selectedScreen != Screens.generalInfo) {
                setState(() {
                  _selectedScreen = Screens.generalInfo;
                  _tabController?.animateTo(0);
                });
              }
            },
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/mesh.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: CustomSpacing.four),
                    Expanded(
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(LanguageService.getTranslated(context, "user_profile_user_management_title"),
                                  style: typography.H5_Regular),
                            ),
                            // Add 3 tabs
                            SizedBox(
                              height: CustomSpacing.two,
                            ),
                            TabBar(
                              controller: _tabController,
                              labelStyle:
                                  typography.BottomNavigationActiveLabel,
                              tabs: _tabLength == 3?[
                                Tab(
                                  child: InkWell(
                                    onTap: () {
                                      _tabController?.animateTo(0);
                                      _selectedScreen = Screens.connectionList;
                                    },
                                    child: Tab(
                                      text: LanguageService.getTranslated(
                                          context, "user_profile_app_user_management_general_info_tab"),
                                    ),
                                  ),
                                ),
                                !showMyTeams?SizedBox():InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(1);
                                    _selectedScreen = Screens.requestList;
                                  },
                                  child: Tab(
                                    text: LanguageService.getTranslated(
                                        context, "user_profile_app_user_management_my_team_tab"),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(2);
                                    _selectedScreen = Screens.chatList;
                                  },
                                  child: Tab(
                                    text: LanguageService.getTranslated(
                                        context, "user_profile_app_user_management_security_tab"),
                                  ),
                                ),
                              ]:[
                                Tab(
                                  child: InkWell(
                                    onTap: () {
                                      _tabController?.animateTo(0);
                                      _selectedScreen = Screens.connectionList;
                                    },
                                    child: Tab(
                                      text: LanguageService.getTranslated(
                                          context, "user_profile_app_user_management_general_info_tab"),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(1);
                                    _selectedScreen = Screens.chatList;
                                  },
                                  child: Tab(
                                    text: LanguageService.getTranslated(
                                        context, "user_profile_app_user_management_security_tab"),
                                  ),
                                ),
                              ],
                            ),

                            // Add 3 tab views
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: _tabLength == 3?[
                                  // General Info
                                  _getGeneralInfoUI(),
                                  // My Team
                                  !showMyTeams?SizedBox():_getMyTeamUI(),
                                  // Security
                                  _getSecurityUI(),
                                ]:[
                                  // General Info
                                  _getGeneralInfoUI(),
                                  // Security
                                  _getSecurityUI(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          endDrawer: Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: CustomSpacing.two),
                    // Circular elevated icon for filter
                    Center(
                        child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.filter_alt_outlined,
                          size: 32,
                        ),
                      ),
                    )),
                    SizedBox(height: CustomSpacing.six),
                    // name, phone, email, company, role dropdown, status,
                Form(
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_name"),
                          labelStyle: typography.Body1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      // Email
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_email"),
                          labelStyle: typography.Body1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      // Phone
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
                                  diallingCodeStyle: typography.Body1,
                                  isShowInputField: false,
                                  dialogTheme: DialogThemeData(
                                    style: typography.Body1,
                                    isShowFloatButton: false,
                                  ),
                                  countryNameStyle: typography.Body1,
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
                                FilteringTextInputFormatter.digitsOnly
                                // Only allows digits
                              ],
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_phone"),
                                hintText: LanguageService.getTranslated(context, "usermanagement_app_filter_phone_hint"),
                                border: const OutlineInputBorder(),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                                  return LanguageService.getTranslated(context, "usermanagement_app_filter_phone_validation");
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
                      // Company
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_company"),
                          labelStyle: typography.Body1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: CustomSpacing.two),
                      // Role Dropdown
                      Stack(
                        children: [
                          TextField(
                            readOnly: true,
                            onTap: () {
                              showBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return RolesBottomSheet(
                                    showCorporateSwitch: true,
                                    isUserProfile: true,
                                    options: roles,
                                    selectedRoles: _selectedRoles,
                                    addChip: _addChip,
                                    removeChip: _removeChip,
                                    removeAllChips: _removeAllChips,
                                    selectedOption: SignUpOptions.corporate,
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
                              labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_roles"),
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
                                        isUserProfile: true,
                                        options: roles,
                                        selectedRoles: _selectedRoles,
                                        addChip: _addChip,
                                        removeChip: _removeChip,
                                        removeAllChips: _removeAllChips,
                                        selectedOption: SignUpOptions.corporate,
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
                      SizedBox(height: CustomSpacing.two),
                      // Status
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context, "usermanagement_app_filter_status"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Active', 'Inactive'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          // Handle status change
                        },
                      ),
                      SizedBox(height: CustomSpacing.two),
                      // Cancel and Submit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Handle cancel button
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                              ),
                              child: Text(
                                LanguageService.getTranslated(context, "usermanagement_app_filter_cancel"),
                                style: typography.ButtonLarge,
                              ),
                            ),
                          ),
                          SizedBox(width: CustomSpacing.two),
                          Expanded(
                            child: CustomButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              type: ButtonType.filled,
                              child: Text(
                                LanguageService.getTranslated(context, "usermanagement_app_filter_submit"),
                                style: typography.ButtonLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    // show modal bottom sheet using scaffold key
    /*showAdaptiveDialog(
      */ /*shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),*/ /*
      context: context,
      builder: (context) {
        return ;
      },
    );*/
    Scaffold.of(context).openEndDrawer();
  }

  _getGeneralInfoUI() {
    var typography = CustomTypography(context);
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      return !userProfileProvider.isLoading
          ? SingleChildScrollView(
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.paperElavation25
                    : AppColors.paperElavation25Light,
                child: Column(
                  children: [
                    // Profile Pic
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.paperElavation25
                                      : AppColors.paperElavation25Light,
                                  child: Column(
                                    children: [
                                      // If company image is not uploaded, show default image
                                      userImageUrl == ''
                                          ? CircleAvatar(
                                              foregroundImage: AssetImage(
                                                  'assets/images/loginImage.png'),
                                              backgroundColor: AppColors
                                                  .avatarBackground,
                                              radius: 40,
                                            )
                                          : CircleAvatar(
                                        backgroundColor: AppColors.avatarBackground,
                                        radius: 40,
                                        child: ClipOval(
                                          child: Image.network(
                                            userImageUrl,
                                            fit: BoxFit.cover,
                                            width: 80, // Adjust to match the CircleAvatar's size
                                            height: 80, // Adjust to match the CircleAvatar's size
                                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child; // Image loaded
                                              } else {
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                        (loadingProgress.expectedTotalBytes ?? 1)
                                                        : null,
                                                    color: AppColors.primaryMain,
                                                  ),
                                                );
                                              }
                                            },
                                            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                              return Icon(
                                                Icons.error,
                                                size: 40,
                                                color: Colors.red,
                                              ); // Display error icon if image fails to load
                                            },
                                          ),
                                        ),
                                      ),

                                      SizedBox(
                                        width: CustomSpacing.four,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),
                                          Text(
                                            LanguageService.getTranslated(context, "user_profile_user_managemt_uploadimage_text"),
                                            style:
                                                typography.Body1,
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),
                                          Text(
                                            LanguageService.getTranslated(context, "usermanagement_app_image_size"),
                                            style: typography
                                                .BottomNavigationActiveLabel,
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),

                                          // Add button
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Consumer<UserProfileProvider>(builder:
                                                  (_, userProfileProvider, child) {
                                                return userProfileProvider
                                                        .isImageUploadLoading
                                                    ? Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      )
                                                    : CustomButton(
                                                        type: ButtonType.filled,
                                                  onPressed: !isEdit ? null : () async {
                                                    // Show image picker
                                                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                                    if (pickedFile != null) {
                                                      File file = File(pickedFile.path);

                                                      // Load image to check its dimensions and format
                                                      final img.Image? image = img.decodeImage(file.readAsBytesSync());
                                                      if (image != null) {
                                                        if ((image.width >= 400 && image.height >= 400) &&
                                                            (pickedFile.path.endsWith('.png') || pickedFile.path.endsWith('.jpg') || pickedFile.path.endsWith('.jpeg'))) {

                                                          // Valid image, proceed with the upload
                                                          userProfileProvider.uploadImage(context, file).then((value) {
                                                            if (value != '') {
                                                              setState(() {
                                                                userImageUrl = value;
                                                              });
                                                            }
                                                          });
                                                        } else {
                                                          // Show an error if the image does not meet the requirements
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Image must be at least 400x400 pixels and in PNG or JPEG format.'),
                                                            ),
                                                          );
                                                        }
                                                      } else {
                                                        // Show an error if the image could not be loaded
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Could not load the image. Please try again.'),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                        child: Text(
                                                          LanguageService.getTranslated(context, "user_profile_user_management_upload_imamge_btn"),
                                                          style: typography
                                                              .ButtonLarge,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                              }),
                                              // or upload avatar
                                              SizedBox(
                                                height: CustomSpacing.three,
                                              ),
                                              Text(
                                                LanguageService.getTranslated(context, "user_profile_user_management_upload_or"),
                                                style: typography.Body1,
                                                textAlign: TextAlign.center,
                                              ),

                                              CustomButton(
                                                type: ButtonType.text,
                                                onPressed: !isEdit?null:() {
                                                  // Show Bottom Sheet with a main avatar in top center (it will have a background) and a grid of avatars from avatars, on avatar click update the selected avatar from grid to central avatar.
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    useSafeArea: true,
                                                    builder: (BuildContext
                                                        context) {
                                                      return SingleChildScrollView(
                                                        physics:
                                                            ClampingScrollPhysics(),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Container(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            16),
                                                                    color: Theme.of(context).brightness == Brightness.dark
                                                                        ? AppColors.paperElavation25
                                                                        : AppColors.paperElavation25Light,
                                                                    child: Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          width: CustomSpacing.four,
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                Text(
                                                                                  LanguageService.getTranslated(context, "user_profile_user_management_select_avatar_btn"),
                                                                                  style: typography
                                                                                      .H6
                                                                                      .copyWith(
                                                                                          color:
                                                                                              Colors.white),
                                                                                  textAlign:
                                                                                      TextAlign
                                                                                          .center,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            Spacer(),
                                                                            IconButton(
                                                                              icon: Icon(
                                                                                  Icons.close),
                                                                              onPressed:
                                                                                  () {
                                                                                Navigator.pop(
                                                                                    context);
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                      16),

                                                              child: Column(
                                                                children: [
                                                                  GridView.builder(
                                                                    scrollDirection: Axis.vertical,
                                                                    shrinkWrap: true,
                                                                    itemCount: userProfileProvider.avatars.length,
                                                                    physics: NeverScrollableScrollPhysics(),
                                                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                                      crossAxisCount: 5,
                                                                      crossAxisSpacing: 16,
                                                                      mainAxisSpacing: 16,
                                                                    ),
                                                                    itemBuilder: (context, index) {
                                                                      return GestureDetector(
                                                                        onTap: () {
                                                                          // Update selected avatar
                                                                          setState(() {
                                                                            userImageUrl = userProfileProvider.avatars[index]?.url ?? "";
                                                                          });
                                                                          Navigator.pop(context);
                                                                        },
                                                                        child: SizedBox(
                                                                          width: 40,
                                                                          height: 40,
                                                                          child: CircleAvatar(
                                                                            backgroundImage: NetworkImage(
                                                                              userProfileProvider.avatars[index]?.url ?? "",
                                                                            ),
                                                                            backgroundColor: AppColors.avatarBackground,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),


                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  CustomSpacing.two,
                                                            ),

                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: CustomButton(
                                                                    type: ButtonType.text,
                                                                    onPressed: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Text(
                                                                      LanguageService.getTranslated(context, "user_profile_user_management_ cancel_btn"),
                                                                      style: typography
                                                                          .ButtonLarge,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );

                                                },
                                                child: Text(
                                                  LanguageService.getTranslated(context, "user_profile_app_user_management_upload_avatar_button"),
                                                  style: typography.ButtonLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),
                                          // If edit is enables user can edit else its disabled fields: Name, Display Name, Roles with bottom sheet selection, Email and phone with country code
                                          // Edit button
                                          !showEditUser?SizedBox():!isEdit
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    CustomButton(
                                                      type: ButtonType.text,
                                                      onPressed: () {
                                                        switchEdit();
                                                      },
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.edit),
                                                          SizedBox(
                                                              width:
                                                                  CustomSpacing
                                                                      .two),
                                                          Text(
                                                            isEdit
                                                                ? LanguageService.getTranslated(context, "user_profile_app_user_management_profile_save_text")
                                                                : LanguageService.getTranslated(context, "user_profile_app_user_management_edit_profile_text"),
                                                            style:
                                                                typography
                                                                    .ButtonLarge,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : SizedBox(),
                                          !isEdit
                                              ? SizedBox(
                                                  height: CustomSpacing.two,
                                                )
                                              : SizedBox(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextFormField(
                            enabled: isEdit,
                            style: typography.Body1,
                            controller: _nameGeneralInfoController,
                            initialValue: null, // Remove initialValue since we'll use controller
                            readOnly: !isEdit, // Add readOnly instead of disabled for better value visibility
                            //controller: nameGeneralInfoController, // Always use the controller
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: LanguageService.getTranslated(
                                  context, "user_profile_user_management_name_filed_label"),
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).textTheme.labelMedium!.color!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return LanguageService.getTranslated(context, "user_profile_user_management_name_field_error");
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: CustomSpacing.four),
                          // Display Name
                          TextFormField(
                            readOnly: !isEdit,
                            style: typography.Body1,
                            controller: _displayNameGeneralInfoController,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText:
                              isEdit ? 'Display Name' : 'Display Name',//displayNameLabelText,
                              labelStyle: isEdit
                                  ? typography.Body1
                                  : typography.Body1.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                  !.color!,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Display Name is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: CustomSpacing.four),
                          // Role Dropdown
                          Stack(
                            children: [
                              TextField(
                                readOnly: true,
                                enabled: isEdit&&!isSuperAdmin&&!isPgAdmin&&!isAdmin,

                                onTap: isEdit&&!isSuperAdmin&&!isPgAdmin&&!isAdmin
                                    ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    useSafeArea: true,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      List<Map<String, dynamic>> acceptedRoles = userProfileProvider.userData.acceptedRole?.map((role) => role.toJson())?.toList() ?? [];
                                      print("Accepted Roles: $acceptedRoles");
                                      print("useCheckboxes: ${(userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false)}");

                                      return CustomFlexibleRolesBottomSheet(
                                        showCorporateSwitch: true,
                                        options: acceptedRoles,
                                        selectedRoles: _selectedRoles,
                                        addChip: _addChip,
                                        removeChip: _removeChip,
                                        removeAllChips: _removeAllChips,
                                        useCheckboxes: (userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false),
                                        // Assuming you want to use checkboxes for selection
                                      );
                                    },
                                  );

                                }
                                    : null,
                                controller: _textEditingController,
                                onChanged: (value) {
                                  // Handle input changes
                                },
                                decoration: InputDecoration(
                                  labelText: isEdit&&!isSuperAdmin&&!isPgAdmin&&!isAdmin ? '' : '',
                                  labelStyle: isEdit&&!isSuperAdmin&&!isPgAdmin&&!isAdmin
                                      ? typography.Body1
                                      : typography.Body1.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.color),
                                  hintText: _selectedRoles.isEmpty &&
                                      _textEditingController.text.isEmpty
                                      ? 'Select Roles'
                                      : '',
                                  border: OutlineInputBorder(),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                      !.color!,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        useSafeArea: true,
                                        isScrollControlled: true,
                                        builder: (BuildContext context) {
                                          List<Map<String, dynamic>> acceptedRoles = userProfileProvider.userData.acceptedRole?.map((role) => role.toJson())?.toList() ?? [];
                                          return CustomFlexibleRolesBottomSheet(
                                            showCorporateSwitch: true,
                                            options: acceptedRoles,
                                            selectedRoles: _selectedRoles,
                                            addChip: _addChip,
                                            removeChip: _removeChip,
                                            removeAllChips: _removeAllChips,
                                            useCheckboxes: (userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.0,
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
                                            deleteIcon: isEdit&&!isSuperAdmin&&!isPgAdmin ? Icon(Icons.cancel) : null,
                                            onDeleted: isEdit&&!isSuperAdmin&&!isPgAdmin ? () => _removeChip(value) : null,
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
                          SizedBox(height: CustomSpacing.four),
                          // Email
                          TextFormField(
                            readOnly: true,
                            style: typography.Body1,
                            controller: _emailGeneralInfoController,

                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              labelText: isEdit
                                  ? LanguageService.getTranslated(context, "user_profile_user_management_email_field_label")
                              //: emailLabelText,
                                  : LanguageService.getTranslated(context, "user_profile_user_management_email_field_label"),
                              labelStyle: isEdit
                                  ? typography.Body1.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color)
                                  : typography.Body1.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color),

                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                  !.color!,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(height: CustomSpacing.four),
                          // Phone
                          FormField(
                              enabled: isEdit,
                              builder: (FormFieldState<dynamic> state) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: PhoneInput(
                                        style: typography.Body1,

                                        enabled: isEdit,
                                        key: const Key('phone-field'),
                                        controller: phoneController,
                                        shouldFormat: true,
                                        // set _selectedCountryCode to your country code if not null
                                        defaultCountry: IsoCode.US,
                                        decoration: InputDecoration(
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                          labelText: !isEdit
                                              ? LanguageService.getTranslated(context, "user_profile_user_management_mobile_field")
                                          //: phoneLabelText,
                                              : LanguageService.getTranslated(context, "user_profile_user_management_mobile_field"),

                                          labelStyle: isEdit
                                              ? typography.Body1
                                              : typography.Body1.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.color),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                              !.color!,
                                            ),
                                          ),
                                          hintText: LanguageService.getTranslated(context, "user_profile_user_management_mobile_placeholder"),
                                          /* hintStyle: isEdit
                                  ? typography.Body1
                                      : typography.Body1.copyWith(
                                      color: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.color),*/
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
                                );
                              }),
                          SizedBox(height: CustomSpacing.four),
                    ]),
                    ),

                    // Cancel and Submit Buttons
                    isEdit
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () {
                                        // validate
                                        if (!_formKey.currentState!.validate()) {
                                          return;
                                        }
                                        // Atleat one selected role:
                                        if (_selectedRoles.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Please select at least one role.', style: typography.Body1),
                                            ),
                                          );
                                          return;
                                        }
                                        // Update Body
                                        var body = {
                                          "current_user": true,
                                          "userdata": {
                                            "rating": userProfileProvider
                                                    .userData.rating ??
                                                0,
                                            "email": userProfileProvider.userData.email ?? "",
                                            "request_sent": [],
                                            "is_external": true,
                                            "display_image_url": userImageUrl,
                                            "display_name": _displayNameGeneralInfoController.text,
                                            "is_verified": false,
                                            "user_id": userProfileProvider.userData.userId ?? "",
                                            "referral_code": "",
                                            "status": true,
                                            "username": "",
                                            "company_id": userProfileProvider.userData.companyId ?? "",
                                            "isIndividual": (userProfileProvider.userData.isIndividual ?? false) && (userProfileProvider.userData.isExternal ?? false),
                                            "displayName": _displayNameGeneralInfoController.text,
                                            "phone": phoneController.value?.nsn??"",
                                            "my_assignee": [""],
                                            "roles": _selectedRoles.map((role) => role.toJson()).toList(),
                                            "selectedCountryCode": _selectedCountryCode,
                                            "country_code": _selectedCountryCode,
                                            "name": _nameGeneralInfoController.text,
                                            "accepted_role": userProfileProvider.userData.acceptedRole?.map((role) => role.toJson())?.toList() ?? []
                                          }
                                        };
                                        userProfileProvider.updateUserData(context, body).then((value) {
                                          if (value) {
                                            setState(() {
                                              nameLabelText = _nameGeneralInfoController.text;
                                              displayNameLabelText = _displayNameGeneralInfoController.text;
                                              emailLabelText = _emailGeneralInfoController.text;
                                              phoneLabelText = phoneController.value?.nsn??"";
                                              isEdit = false;
                                            });
                                          }
                                        });



                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        LanguageService.getTranslated(context, "user_profile_user_management_btn_submit"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: CustomSpacing.two),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Handle submit button
                                        switchEdit();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 8),
                                      ),
                                      child: Text(
                                        LanguageService.getTranslated(context, "user_profile_user_management_btn_cancel"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Center(
                      child: Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )),
                ),
              ],
            );
    });
  }

  void switchEdit() {
    setState(() {
      isEdit = !isEdit;
      if (isEdit) {
        _nameGeneralInfoController.text = nameLabelText;
        _displayNameGeneralInfoController.text = displayNameLabelText;
        _emailGeneralInfoController.text = emailLabelText;
        _phoneGeneralInfoController.text = phoneLabelText;
      } else {
        _nameGeneralInfoController.text = nameLabelText;
        _displayNameGeneralInfoController.text = displayNameLabelText;
        _emailGeneralInfoController.text = emailLabelText;
        _phoneGeneralInfoController.text = phoneLabelText;
      }
    });
  }

  _getMyTeamUI() {
    return SingleChildScrollView(
      child: Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          return userProfileProvider.isUserTeamLoading? Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Center(
                  child: Container(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )),
            ],
          )  : Column(
            children: [
              SizedBox(height: CustomSpacing.two),
              Container(
                child: _managerCardUI(userProfileProvider),
              ),
              SizedBox(height: CustomSpacing.two),
              Container(
                child: _delegateCardUI(userProfileProvider),
              ),
              SizedBox(height: CustomSpacing.two),
              Container(
                child: _reporteesCardUI(userProfileProvider),
              ),
              SizedBox(height: CustomSpacing.two),
            ],
          );
        }
      ),
    );
  }

  _managerCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(
                        context, "user_profile_user_management_row_name_manager"),
                    style: typography.Body1,
                  ),
                ),
                !showAssignDeleteManager?SizedBox():Builder(
                  builder: (context) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        userProfileProvider.myManager.isNotEmpty&&userProfileProvider.myManager[0] != null?SizedBox(height: 48,): IconButton(
                          onPressed: () {
                            showAdaptiveDialog(
                              context: context,
                              builder: (localContext) {
                                return AlertDialog(
                                  content: _addMemberDialogUI(localContext, "add_manager"),
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.add,
                            color: AppColors.primaryMain,
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          userProfileProvider.myManager.isEmpty||userProfileProvider.myManager[0] == null?SizedBox(): Container(
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                SizedBox(height: CustomSpacing.four),
                Container(
                    child: Row(
                  children: [
                    // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 24,
                        child: userProfileProvider.myManager[0]?.
                            displayImageUrl !=
                            null &&
                            userProfileProvider.myManager[0]?.
                            displayImageUrl !=
                                ''
                            ? ClipOval(
                          child: Image.network(
                            userProfileProvider.myManager[0]!.displayImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Text(
                          userProfileProvider.myManager[0]?.name
                              ?.substring(0, 1)
                              .toUpperCase() ??
                              "",
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userProfileProvider.myManager[0]?.name??"", style: typography.Body1),
                        Text(userProfileProvider.myManager[0]?.email??"", style: typography.Body2),
                      ],
                    ),

                    Spacer(),
                    // Actions
                    !showAssignDeleteManager?SizedBox():PopupMenuButton<PopupMenuItem<dynamic>>(
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<PopupMenuItem<dynamic>>> items = [];

                        /*if (userProfileProvider.myManager.isEmpty || userProfileProvider.myManager[0] == null) {
                          items.add(
                            PopupMenuItem(
                              onTap: () {
                                // Handle search
                                showDialog(
                                  context: context,
                                  builder: (context) => _addMemberDialogUI(context, "add_manager"),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.search),
                                  SizedBox(width: CustomSpacing.two),
                                  Text('Search'),
                                ],
                              ),
                            ),
                          );
                        }*/

                        if(showAssignDeleteManager) {
                          items.add(
                          PopupMenuItem(
                            onTap: () {
                              // Show delete dialog and pop off the menu also on ok
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Are you sure you want to delete this manager?'),
                                        SizedBox(height: CustomSpacing.two),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            SizedBox(width: CustomSpacing.two),
                                            TextButton(
                                              onPressed: () {
                                                // Handle delete
                                                userProfileProvider.deleteTeamMember(context, userProfileProvider.myManager[0]!.id??"", "add_manager");
                                                Navigator.pop(context);
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  );
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: CustomSpacing.two),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        );
                        }

                        return items;
                      },
                    ),
                  ],
                )),
                // Role Chip
                userProfileProvider.myManager[0]?.role == null?SizedBox(): Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(userProfileProvider.myManager[0]?.role??""
                      ),
                    ),
                    ),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _delegateCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(
                        context, "user_profile_user_management_row_name_Delegate"),
                    style: typography.Body1,
                  ),
                ),
                !showAddDelegate?SizedBox():userProfileProvider.myReportee.isEmpty?SizedBox(
                  height: 40,
                ):Builder(
                  builder: (context) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        userProfileProvider.myDeligate.isNotEmpty&&userProfileProvider.myDeligate[0] != null?SizedBox(height: 48,): IconButton(
                          onPressed: () {
                            // Handle submit button
                            showDialog(
                              context: context,
                              builder: (localContext) {
                                return AlertDialog(
                                  content: _addMemberDialogUI(localContext, "add_delegate"),
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.add,
                            color: AppColors.primaryMain,
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          userProfileProvider.myDeligate.isEmpty||userProfileProvider.myDeligate[0] == null?SizedBox(): Container(
            color: Theme.of(context).colorScheme.background,
            child: Column(
              children: [
                SizedBox(height: CustomSpacing.four),
                Container(
                    child: Row(
                  children: [
                    // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 24,
                        child: userProfileProvider.myDeligate[0]?.
                        displayImageUrl !=
                            null &&
                            userProfileProvider.myDeligate[0]?.
                            displayImageUrl !=
                                ''
                            ? ClipOval(
                          child: Image.network(
                            userProfileProvider.myDeligate[0]!.displayImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Text(
                          userProfileProvider.myDeligate[0]?.name
                              ?.substring(0, 1)
                              .toUpperCase() ??
                              "",
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userProfileProvider.myDeligate[0]?.name??"", style: typography.Body1),
                        Text(userProfileProvider.myDeligate[0]?.email??"", style: typography.Body2),
                      ],
                    ),

                    Spacer(),
                    // Actions
                    PopupMenuButton<PopupMenuEntry<dynamic>>(
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<PopupMenuEntry<dynamic>>> items = [];

                        /*if (userProfileProvider.myDeligate.isNotEmpty && userProfileProvider.myDeligate[0] != null) {
                          items.add(
                            PopupMenuItem(
                              onTap: () {
                                // Handle search
                                showDialog(
                                  context: context,
                                  builder: (context) => _addMemberDialogUI(context, "add_deligate"),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.search),
                                  SizedBox(width: CustomSpacing.two),
                                  Text('Search'),
                                ],
                              ),
                            ),
                          );
                        }*/

                        if(showRevokeDelegate) {
                          items.add(
                          PopupMenuItem(
                            onTap: () {
                              // Show delete dialog and pop off the menu also on ok
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Are you sure you want to delete this delegate?'),
                                        SizedBox(height: CustomSpacing.two),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            SizedBox(width: CustomSpacing.two),
                                            TextButton(
                                              onPressed: () {
                                                // Handle delete
                                                userProfileProvider.deleteTeamMember(context, userProfileProvider.myDeligate[0]!.id??"", "add_deligate");
                                                Navigator.pop(context);
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  );
                                },
                              );
                            },
                            child: Row(

                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: CustomSpacing.two),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        );
                        }

                        return items;
                      },
                    ),




                  ],
                )),
                // Role Chip
                userProfileProvider.myDeligate[0]?.role == null?SizedBox(): Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(userProfileProvider.myDeligate[0]?.role??""),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _reporteesCardUI(UserProfileProvider userProfileProvider) {
    var typography = CustomTypography(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    LanguageService.getTranslated(
                        context, "user_profile_user_management_row_name_reportee"),
                    style: typography.Body1,
                  ),
                ),
                !showAddReportee?SizedBox():Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle submit button
                        showAdaptiveDialog(
                          context: context,
                          builder: (localContext) {
                            return AlertDialog(
                              content: _addMemberDialogUI(localContext, "add_reportee"),
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.add,
                        color: AppColors.primaryMain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          userProfileProvider.myReportee.isEmpty||userProfileProvider.myReportee[0] == null?SizedBox():SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: userProfileProvider.myReportee.length,
                itemBuilder: (context, index) {
                  return _reporteesListCardUI(userProfileProvider, index);
                }),
          ),
        ],
      ),
    );
  }

  _reporteesListCardUI(UserProfileProvider userProfileProvider, int index) {
    var typography = CustomTypography(context);
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          SizedBox(height: CustomSpacing.four),
          Row(
            children: [
              // Manager Image Avatar, Name and email as column, role chip, actions as search and delete
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 24,
                  child: userProfileProvider.myReportee[index]?.
                  displayImageUrl !=
                      null &&
                      userProfileProvider.myReportee[index]?.
                      displayImageUrl !=
                          ''
                      ? ClipOval(
                    child: Image.network(
                      userProfileProvider.myReportee[index]!.displayImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Text(
                    userProfileProvider.myReportee[index]?.name
                        ?.substring(0, 1)
                        .toUpperCase() ??
                        "",
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( userProfileProvider.myReportee[index]?.name??"" , style: typography.Body1),
                  Text(userProfileProvider.myReportee[index]?.email??"" , style: typography.Body2),
                ],
              ),

              Spacer(),
              // Actions
              !showAddReportee?SizedBox():PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    /*PopupMenuItem(
                      onTap: () {
                        // Handle search
                        showDialog(
                          context: context,
                          builder: (context) => _addMemberDialogUI(context, "add_reportee"),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: CustomSpacing.two),
                          Text('Search'),
                        ],
                      ),
                    ),*/
                    PopupMenuItem(
                      onTap: () {
                        // Show delete dialog and pop off the menu also on ok
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Are you sure you want to delete this reportee?'),
                                  SizedBox(height: CustomSpacing.two),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      SizedBox(width: CustomSpacing.two),
                                      TextButton(
                                        onPressed: () {
                                          // Handle delete
                                          userProfileProvider.deleteTeamMember(context, userProfileProvider.myReportee[index]!.id??"", "add_reportee");
                                          Navigator.pop(context);
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            );
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: CustomSpacing.two),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          // Role Chip
          userProfileProvider.myReportee[index]?.role == null?SizedBox(): Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(userProfileProvider.myReportee[index]?.role??"" ),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.two),
        ],
      ),
    );
  }

  _addMemberDialogUI(BuildContext localContext, String type) {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: CustomSpacing.two),
          Text(type == "add_manager" ? LanguageService.getTranslated(context, "user_profile_user_management_add_manager_btn") : type == 'add_delegate' ? LanguageService.getTranslated(context, "user_profile_user_management_add_delegate_btn") : LanguageService.getTranslated(context, "user_profile_user_management_add_reportee"),
              style: typography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          // Search Box with Autocomplete
          Autocomplete<NetworkingUsers>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<NetworkingUsers>.empty();
              } else {
                return Future.delayed(Duration.zero, () async {
                  _managerList = await searchNetworks(textEditingValue.text);
                  print("Manager List: $_managerList");
                  return _managerList;
                });
              }
            },
            onSelected: (NetworkingUsers selection) {
              setState(() {
                _selectedManager = selection;
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return SizedBox(
                height: 50,
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      onPressed: onFieldSubmitted,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              );
            },
            displayStringForOption: (NetworkingUsers option) {
              // Assuming _searchResults is a list of User objects
              NetworkingUsers user = _managerList.firstWhere((user) => user.id == option.id);
              return '${user.name} (${user.email})';
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<NetworkingUsers> onSelected, Iterable<NetworkingUsers> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      NetworkingUsers option = options.elementAt(index);
                      NetworkingUsers user = _managerList.firstWhere((user) => user.id == option.id);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: ListTile(
                          leading:CircleAvatar(
                            child: user.
                            displayImageUrl !=
                                null &&
                                user.
                                displayImageUrl !=
                                    ''
                                ? ClipOval(
                              child: Image.network(
                                user.displayImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Text(
                              user.name
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                                  "",
                            ),
                          ),
                          title: Text(user.name??"", style: typography.Body1.copyWith(color: Theme.of(context).textTheme.labelMedium?.color)),
                          subtitle: Text(user.email??"", style: typography.Subtitle1.copyWith(color: Theme.of(context).textTheme.labelMedium?.color)),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SizedBox(height: CustomSpacing.two),
          // Cancel and Submit Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(localContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: Text(
                    LanguageService.getTranslated(context, "user_profile_user_management_btn_cancel"),
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
              SizedBox(width: CustomSpacing.two),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    // Handle submit button
                    switch (type) {
                      case 'add_manager':
                        Provider.of<UserProfileProvider>(localContext, listen: false).addTeamMember(context, _selectedManager?.id??"", "add_manager").then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context, listen: false).getUserTeamMembers(context);
                            });
                          }
                        });
                        break;
                      case 'add_delegate':
                        Provider.of<UserProfileProvider>(localContext, listen: false).addTeamMember(context, _selectedManager?.id??"", "add_delegate").then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context, listen: false).getUserTeamMembers(context);
                            });
                          }
                        });
                        break;
                        case 'add_reportee':
                        Provider.of<UserProfileProvider>(localContext, listen: false).addTeamMember(context, _selectedManager?.id??"", "add_reportee").then((value) {
                          Navigator.pop(localContext);
                          if (value) {
                            Future.delayed(Duration(seconds: 1), () {
                              Provider.of<UserProfileProvider>(context, listen: false).getUserTeamMembers(context);
                            });
                          }
                        });
                    }
                  },
                  type: ButtonType.filled,
                  child: Text(
                    LanguageService.getTranslated(context, "user_profile_user_management_btn_submit"),
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _getSecurityUI() {
    var typography = CustomTypography(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Expanded(
                    child: Text(
                        LanguageService.getTranslated(
                            context, 'coming_soon_title'),
                        style: typography.H4),
                  ),
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
                  Text(
                      LanguageService.getTranslated(
                          context, 'coming_soon_subtitle'),
                      style: typography.Body1),
                ],
              ),
            ),
          ),
        ],
      ),
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
}
