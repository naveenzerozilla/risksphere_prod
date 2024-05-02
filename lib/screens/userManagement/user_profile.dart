import 'dart:io';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/components/expandable_card_container.dart';
import 'package:image_picker/image_picker.dart';
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

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isEdit = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        setState(() {
          _selectedScreen = Screens.connectionList;
        });
      } else if (_tabController?.index == 1) {
        setState(() {
          _selectedScreen = Screens.requestList;
        });
      } else if (_tabController?.index == 2) {
        setState(() {
          _selectedScreen = Screens.chatList;
        });
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });

    _getData();
  }

  _getData() {
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAllUserData(context, '', '')
        .then((value) {
      if (value != null) {
        setState(() {
          userImageUrl = value.displayImageUrl ?? "";
          nameLabelText = value.name ?? "";
          displayNameLabelText = value.displayName ?? "";
          emailLabelText = value.email ?? "";
          phoneLabelText = value.phone ?? "";
          // Set roles and assign from List<Roles> to List<Categories>
          _selectedRoles = (value.role ?? []).map((role) => Categories(
              id: role.id ?? "",
              name: role.name ?? "",
              role: role.role ?? "", isForIndividual: role.isForIndividual ?? false,
              isMultipleRoleEnabled: role.isMultipleRoleEnabled ?? false,
              isApplicableForTrial: role.isApplicableForTrial ?? false,

          )).toList();

        });
      }
    });
    Provider.of<UserProfileProvider>(context, listen: false)
        .getAvatarUrls(context);
  }

  @override
  Widget build(BuildContext context1) {
    return Consumer<ThemeProvider>(
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
        ),
        drawer: CustomDrawer(),
        body: PopScope(
          canPop: _selectedScreen == Screens.connectionList,
          onPopInvoked: (canPop) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
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
                            child: Text('User Management',
                                style: CustomTypography.H5_Regular),
                          ),
                          // Add 3 tabs
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          TabBar(
                            controller: _tabController,
                            labelStyle:
                                CustomTypography.BottomNavigationActiveLabel,
                            tabs: [
                              Tab(
                                child: InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(0);
                                    _selectedScreen = Screens.connectionList;
                                  },
                                  child: Tab(
                                    text: 'Info',
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(1);
                                  _selectedScreen = Screens.requestList;
                                },
                                child: Tab(
                                  text: 'My Team',
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(2);
                                  _selectedScreen = Screens.chatList;
                                },
                                child: Tab(
                                  text: 'Security',
                                ),
                              ),
                            ],
                          ),

                          // Add 3 tab views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // General Info
                                _getGeneralInfoUI(),
                                // My Team
                                _getMyTeamUI(),
                                // Security
                                _getChatsUI(),
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
                      child: Column(children: [
                    // Name
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: CustomTypography.Body1,
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
                        labelText: 'Email',
                        labelStyle: CustomTypography.Body1,
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
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
                              FilteringTextInputFormatter.digitsOnly
                              // Only allows digits
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
                    // Company
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        labelStyle: CustomTypography.Body1,
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
                            labelText: 'Role(s)',
                            hintText:
                                _selectedRoles.isEmpty ? 'Select Roles' : "",
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
                                      selectedOption: SignUpOptions.corporate,
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
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
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
                        labelText: 'Status',
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
                              // Handle submit button
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 8),
                            ),
                            child: Text(
                              'Cancel',
                              style: CustomTypography.ButtonLarge,
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
                              'Add Filter',
                              style: CustomTypography.ButtonLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]))
                ],
              ),
            ),
          ),
        ),
      );
    });
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
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      return !userProfileProvider.isLoading
          ? SingleChildScrollView(
              child: Card(
                color: AppColors.paperElavation25,
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
                                  color: AppColors.paperElavation25,
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
                                              foregroundImage:
                                                  NetworkImage(userImageUrl),
                                              backgroundColor: AppColors
                                                  .avatarBackground,
                                              radius: 40,
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
                                            "Upload Image",
                                            style:
                                                CustomTypography.Body1.copyWith(
                                                    color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),
                                          Text(
                                            "Min 400x400px\nPNG or JPEG",
                                            style: CustomTypography
                                                .BottomNavigationActiveLabel,
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),

                                          // Add button
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                                                        onPressed: !isEdit?null:() {
                                                          // Show image picker
                                                          ImagePicker()
                                                              .pickImage(
                                                                  source:
                                                                      ImageSource
                                                                          .gallery)
                                                              .then((value) {
                                                            if (value != null) {
                                                              // Handle image upload
                                                              File v =
                                                                  File(value.path);
                                                              userProfileProvider
                                                                  .uploadImage(
                                                                      context, v)
                                                                  .then((value) {
                                                                if (value != '') {
                                                                  // Handle image upload response
                                                                  setState(() {
                                                                    userImageUrl =
                                                                        value;
                                                                  });
                                                                }
                                                              });
                                                            }
                                                          });
                                                        },
                                                        child: Text(
                                                          "Upload Image",
                                                          style: CustomTypography
                                                              .ButtonLarge,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      );
                                              }),
                                              // or upload avatar
                                              SizedBox(
                                                width: CustomSpacing.four,
                                              ),
                                              Text(
                                                "or",
                                                style: CustomTypography.Body1,
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
                                                                    color: AppColors
                                                                        .paperElavation25,
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
                                                                                  "Select Avatar",
                                                                                  style: CustomTypography
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
                                                                      crossAxisCount: 3,
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
                                                                      "Cancel",
                                                                      style: CustomTypography
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
                                                  "Upload Avatar",
                                                  style: CustomTypography.ButtonLarge,
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
                                          !isEdit
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
                                                                ? "Save"
                                                                : "Edit Profile",
                                                            style:
                                                                CustomTypography
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
                    // Name
                    TextFormField(
                      enabled: isEdit,
                      controller: _nameGeneralInfoController,
                      decoration: InputDecoration(
                        labelText: isEdit ? 'Name' : nameLabelText,
                        labelStyle: isEdit
                            ? CustomTypography.Body1
                            : CustomTypography.Body1.copyWith(
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
                    // Display Name
                    TextFormField(
                      enabled: isEdit,
                      controller: _displayNameGeneralInfoController,
                      decoration: InputDecoration(
                        labelText:
                            isEdit ? 'Display Name' : displayNameLabelText,
                        labelStyle: isEdit
                            ? CustomTypography.Body1
                            : CustomTypography.Body1.copyWith(
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
                    // Role Dropdown
                    Stack(
                      children: [
                        TextField(
                          readOnly: true,
                          enabled: isEdit,

                          onTap: isEdit
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
                            labelText: isEdit ? '' : '',
                            labelStyle: isEdit
                                ? CustomTypography.Body1
                                : CustomTypography.Body1.copyWith(
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
                                          deleteIcon: isEdit ? Icon(Icons.cancel) : null,
                                          onDeleted: isEdit ? () => _removeChip(value) : null,
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
                      enabled: false,
                      controller: _emailGeneralInfoController,

                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'Email'
                            : emailLabelText,
                        labelStyle: isEdit
                            ? CustomTypography.Body1.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.color)
                            : CustomTypography.Body1.copyWith(
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
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child: CountryListPicker(
                                      initialCountry: Countries.United_States,
                                      border: InputBorder.none,
                                      flagSize: Size(35, 30),
                                      onChanged: isEdit
                                          ? (code) {
                                              setState(() {
                                                _selectedCountryCode = code;
                                              });
                                            }
                                          : null,
                                      diallingCodeStyle: CustomTypography.Body1,
                                      isShowInputField: false,
                                      dialogTheme: DialogThemeData(
                                        style: CustomTypography.Body1,
                                        isShowFloatButton: false,
                                      ),
                                      countryNameStyle: CustomTypography.Body1,
                                      isShowCountryName: false,
                                      onCountryChanged: isEdit
                                          ? (country) {
                                              print(
                                                  'This is the country code: $country');
                                              setState(() {
                                                _selectedCountryCode =
                                                    country.dialing_code;
                                              });
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: CustomSpacing.four),

                              // Mobile Number TextFormField
                              Expanded(
                                flex: 7,
                                child: TextFormField(
                                  enabled: isEdit,

                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  // Numeric keyboard
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                    // Only allows digits
                                  ],
                                  decoration: InputDecoration(
                                    labelText: isEdit
                                        ? 'Mobile number'
                                        : phoneLabelText,
                                    labelStyle: isEdit
                                        ? CustomTypography.Body1
                                        : CustomTypography.Body1.copyWith(
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
                                  controller: _phoneGeneralInfoController,
                                ),
                              ),
                              // Dropdown Icon Suffix
                            ],
                          );
                        }),
                    SizedBox(height: CustomSpacing.four),
                    // Cancel and Submit Buttons
                    isEdit
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: () {
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
                                            "phone": _phoneGeneralInfoController.text,
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
                                              phoneLabelText = _phoneGeneralInfoController.text;
                                              isEdit = false;
                                            });
                                          }
                                        });



                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        'Save',
                                        style: CustomTypography.ButtonLarge,
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
                                        'Cancel',
                                        style: CustomTypography.ButtonLarge,
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
        _nameGeneralInfoController.text = "";
        _displayNameGeneralInfoController.text = "";
        _emailGeneralInfoController.text = "";
        _phoneGeneralInfoController.text = "";
      }
    });
  }

  _getMyTeamUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: CustomSpacing.two),
          Container(
            child: _managerCardUI(),
          ),
          SizedBox(height: CustomSpacing.two),
          Container(
            child: _delegateCardUI(),
          ),
          SizedBox(height: CustomSpacing.two),
          Container(
            child: _reporteesCardUI(),
          ),
          SizedBox(height: CustomSpacing.two),
        ],
      ),
    );
  }

  _managerCardUI() {
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
                Text(
                  'My Manager',
                  style: CustomTypography.Body1,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: _addDialogUI(),
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
          Container(
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
                        backgroundImage:
                            AssetImage('assets/images/loginImage.png'),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vinay Angadi', style: CustomTypography.Body1),
                        Text('vinay@devias.io', style: CustomTypography.Body2),
                      ],
                    ),

                    Spacer(),
                    // Actions
                    PopupMenuButton(
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.search),
                                SizedBox(width: CustomSpacing.two),
                                Text('Search'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
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
                )),
                // Role Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Under Writer'),
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

  _delegateCardUI() {
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
                Text(
                  'My Delegation',
                  style: CustomTypography.Body1,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle submit button
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
          Container(
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
                        backgroundImage:
                            AssetImage('assets/images/loginImage.png'),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vinay Angadi', style: CustomTypography.Body1),
                        Text('vinay@devias.io', style: CustomTypography.Body2),
                      ],
                    ),

                    Spacer(),
                    // Actions
                    PopupMenuButton(
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.search),
                                SizedBox(width: CustomSpacing.two),
                                Text('Search'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
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
                )),
                // Role Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Under Writer'),
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

  _reporteesCardUI() {
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
                Text(
                  'My Reportee(s)',
                  style: CustomTypography.Body1,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle submit button
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _reporteesListCardUI();
                }),
          ),
        ],
      ),
    );
  }

  _reporteesListCardUI() {
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
                  backgroundImage: AssetImage('assets/images/loginImage.png'),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vinay Angadi', style: CustomTypography.Body1),
                  Text('vinay@devias.io', style: CustomTypography.Body2),
                ],
              ),

              Spacer(),
              // Actions
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: CustomSpacing.two),
                          Text('Search'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text('Under Writer'),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.two),
        ],
      ),
    );
  }

  _addDialogUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // add manager text, below it search box with search icon and submit button
        children: [
          SizedBox(height: CustomSpacing.two),
          Text('Add Manager',
              style: CustomTypography.H5_Regular.copyWith(color: Colors.white)),
          SizedBox(height: CustomSpacing.two),
          // Search Box
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  // Handle submit button
                },
                icon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          // Cancel and Submit Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Handle submit button
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: Text(
                    'Cancel',
                    style: CustomTypography.ButtonLarge,
                  ),
                ),
              ),
              SizedBox(width: CustomSpacing.two),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    // Handle submit button
                  },
                  type: ButtonType.filled,
                  child: Text(
                    'Submit',
                    style: CustomTypography.ButtonLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _getChatsUI() {
    return Container();
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
