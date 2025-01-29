import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/providers/email_provider.dart';
import 'package:green/providers/feature_provider.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/components/roles_bottom_sheet.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../design_system/repo/constants.dart';
import '../../models/feature_list_model.dart';
import '../../models/initial_data_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/role_provider.dart' as role;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
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

  EmailOptions _selectedEmailOption = EmailOptions.notifications;
  TabController? _emailTabController;

  // Create Feature
  List<SubFeatures> subFeatures = [];
  TextEditingController featureNameController = TextEditingController();
  TextEditingController featureTagController = TextEditingController();
  TextEditingController subFeatureNameController = TextEditingController();
  TextEditingController subFeatureTagController = TextEditingController();

  GlobalKey<FormState> _formFeatureKey = GlobalKey<FormState>();
  GlobalKey<FormState> _formSubFeatureKey = GlobalKey<FormState>();

  //Email
  TextEditingController emailNotificationController = TextEditingController();
  TextEditingController passwordNotificationController =
      TextEditingController();
  TextEditingController smtpNotificationController = TextEditingController();
  TextEditingController portNotificationController = TextEditingController();
  TextEditingController emailHelpDeskController = TextEditingController();
  TextEditingController passwordHelpDeskController = TextEditingController();
  TextEditingController smtpHelpDeskController = TextEditingController();
  TextEditingController portHelpDeskController = TextEditingController();
  TextEditingController passwordAdminController = TextEditingController();
  TextEditingController smtpAdminController = TextEditingController();
  TextEditingController portAdminController = TextEditingController();
  TextEditingController emailAdminController = TextEditingController();
  TextEditingController passwordSupportController = TextEditingController();
  TextEditingController smtpSupportController = TextEditingController();
  TextEditingController portSupportController = TextEditingController();
  TextEditingController emailSupportController = TextEditingController();
  String notificationEmailId = "";
  String helpDeskEmailId = "";
  String adminEmailId = "";
  String supportEmailId = "";


  //role
  int selectedRole = 0;

  //sub feature
  int selectedSubFeature = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedScreen = Screens.featureList;
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        setState(() {
          _selectedScreen = Screens.featureList;
        });
      } else if (_tabController?.index == 1) {
        setState(() {
          _selectedScreen = Screens.roleList;
        });
      } else if (_tabController?.index == 2) {
        setState(() {
          _selectedScreen = Screens.chatList;
          isLoading = true;
        });
        Future.delayed(Duration(seconds: 2), () {
          Provider.of<FeatureProvider>(context, listen: false)
              .getSubFeatures(context, "chat");
        });
      } else if (_tabController?.index == 3) {
        setState(() {
          _selectedScreen = Screens.networkList;
        });
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
    _emailTabController = TabController(length: 4, vsync: this);
    _emailTabController?.addListener(() {
      setState(() {
        _selectedEmailOption = EmailOptions.values[_emailTabController!.index];
      });
    });
    getData();
  }

  getData() async {
    Provider.of<FeatureProvider>(context, listen: false)
        .getAllFeatures(context);
    Provider.of<RoleProvider>(context, listen: false).getAllRoles(context);
    Provider.of<EmailProvider>(context, listen: false)
        .getAllEmails(context,)
        .then((value) {
          for(int i = 0; i < value.length; i++) {
            if (value[i].emailType == "notification") {
              notificationEmailId = value[i].id ?? "";
              emailNotificationController.text = value[i].email ?? "";
              passwordNotificationController.text = value[i].password ?? "";
              smtpNotificationController.text = value[i].host ?? "";
              if (value[i].port != null) {
                portNotificationController.text =
                    value[i].port.toString() ?? "";
              }
            }
            if (value[i].emailType == "helpdesk") {
              helpDeskEmailId = value[i].id ?? "";
              emailHelpDeskController.text = value[i].email ?? "";
              passwordHelpDeskController.text = value[i].password ?? "";
              smtpHelpDeskController.text = value[i].host ?? "";
              if (value[i].port != null) {
                portHelpDeskController.text = value[i].port.toString() ?? "";
              }
            }
            if (value[i].emailType == "admin") {
              adminEmailId = value[i].id ?? "";
              emailAdminController.text = value[i].email ?? "";
              passwordAdminController.text = value[i].password ?? "";
              smtpAdminController.text = value[i].host ?? "";
              if (value[i].port != null) {
                portAdminController.text = value[i].port.toString();
              }
            }
            if (value[i].emailType == "contactus") {
              supportEmailId = value[i].id ?? "";
              emailSupportController.text = value[i].email ?? "";
              passwordSupportController.text = value[i].password ?? "";
              smtpSupportController.text = value[i].host ?? "";
              if (value[i].port != null) {
                portSupportController.text = value[i].port.toString();
              }
            }
          }
    });
  }

  getSubFeatureData(String tag) async {
    Provider.of<FeatureProvider>(context, listen: false)
        .getSubFeatures(context, tag);
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
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
        floatingActionButtonLocation: _selectedScreen == Screens.roleAdd
            ? FloatingActionButtonLocation.centerDocked
            : FloatingActionButtonLocation.endFloat,
        floatingActionButton: _selectedScreen == Screens.featureList ||
                _selectedScreen == Screens.roleList
            ? FloatingActionButton(
                onPressed: () {
                  if (_selectedScreen == Screens.featureList) {
                    setState(() {
                      _selectedScreen = Screens.addFeature;
                    });
                  } else if (_selectedScreen == Screens.roleList) {
                    setState(() {
                      _selectedScreen = Screens.roleAdd;
                    });
                  }
                  print('Selected Screen: $_selectedScreen');
                },
                child: Icon(Icons.add),
              )
            : _selectedScreen == Screens.roleAdd
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                            child: Text(
                              'Cancel',
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
                              'Save',
                              style: typography.ButtonLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(),
        body: PopScope(
          canPop: _selectedScreen == Screens.featureList,
          onPopInvoked: (canPop) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
            if (_selectedScreen == Screens.addFeature) {
              setState(() {
                _selectedScreen = Screens.featureList;
              });
            }
            if (_selectedScreen == Screens.roleAdd) {
              setState(() {
                _selectedScreen = Screens.roleList;
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
                  Expanded(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            isScrollable: true,
                            controller: _tabController,
                            labelStyle:
                                typography.BottomNavigationActiveLabel,
                            tabs: [
                              Tab(
                                child: InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(0);
                                    _selectedScreen = Screens.featureList;
                                  },
                                  child: Tab(
                                    text: 'Features',
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(1);
                                  _selectedScreen = Screens.roleList;
                                },
                                child: Tab(
                                  text: 'Role',
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(2);
                                  _selectedScreen = Screens.chatList;
                                },
                                child: Tab(
                                  text: 'Categories',
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(3);
                                  _selectedScreen = Screens.networkList;
                                },
                                child: Tab(
                                  text: 'Email',
                                ),
                              ),
                            ],
                          ),

                          // Add 3 tab views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Features
                                _selectedScreen == Screens.addFeature
                                    ? _addFeaturesUI()
                                    : _getFeaturesUI(),
                                // Roles
                                _selectedScreen == Screens.roleAdd
                                    ? _addRoleUI()
                                    : _getRolesUI(),
                                // Chats
                                _getChatsUI(),
                                // Email
                                _getEmailUI(),
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
                        labelText: 'Email',
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
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child:Container(),
                              // CountryListPicker(
                              //   initialCountry: Countries.United_States,
                              //   border: InputBorder.none,
                              //   flagSize: Size(35, 30),
                              //   onChanged: (code) {
                              //     setState(() {
                              //       _selectedCountryCode = code;
                              //     });
                              //   },
                              //   diallingCodeStyle: typography.Body1,
                              //   isShowInputField: false,
                              //   // dialogTheme: DialogThemeData(
                              //   //   style: typography.Body1,
                              //   //   isShowFloatButton: false,
                              //   // ),
                              //   countryNameStyle: typography.Body1,
                              //   isShowCountryName: false,
                              //   onCountryChanged: (country) {
                              //     print('This is the country code: $country');
                              //     setState(() {
                              //       _selectedCountryCode = country.dialing_code;
                              //     });
                              //   },
                              // ),
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
                              'Add Filter',
                              style: typography.ButtonLarge,
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

  _getFeaturesUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: CustomSpacing.four),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Consumer<FeatureProvider>(
                    builder: (context, featureProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      Text('Feature Management',
                          style: typography.H5_Regular),
                      featureProvider.isLoading
                          ? Container(
                              height: MediaQuery.of(context).size.height,
                              child: Center(child: CircularProgressIndicator()))
                          : Column(
                              children: [
                                SizedBox(height: CustomSpacing.four),
                                for (int i = 0;
                                    i < featureProvider.features.length;
                                    i++)
                                  Column(
                                    children: [
                                      ExpansionTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        collapsedShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        trailing: PopupMenuButton(
                                          itemBuilder: (context) {
                                            return [
                                              PopupMenuItem(
                                                child: Row(
                                                  children: [
                                                    Text('Enable'),
                                                    Spacer(),
                                                    Switch(
                                                      value: true,
                                                      onChanged: (value) {
                                                        // Handle switch change
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                onTap: () {
                                                  // Handle configure button
                                                  featureTagController.text =
                                                      featureProvider
                                                          .features[i]!.id??"";
                                                  featureNameController.text =
                                                      featureProvider
                                                          .features[i]!.name??"";
                                                  subFeatureNameController.text =
                                                      "";
                                                  subFeatureTagController.text =
                                                      "";
                                                  getSubFeatureData(
                                                      featureProvider
                                                          .features[i]!.id??"");
                                                  setState(() {
                                                    _selectedScreen =
                                                        Screens.addFeature;
                                                  });

                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.settings),
                                                    SizedBox(
                                                        width:
                                                            CustomSpacing.two),
                                                    Text('Configure'),
                                                  ],
                                                ),
                                              ),
                                            ];
                                          },
                                        ),
                                        initiallyExpanded: i == 0,
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: CustomSpacing.two),
                                            Text(
                                                featureProvider
                                                        .features[i]?.name ??
                                                    "",
                                                style: typography.Body1),
                                          ],
                                        ),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        collapsedBackgroundColor:
                                            Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant,
                                        subtitle: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                SizedBox(
                                                    height: CustomSpacing.two),
                                                Chip(
                                                  label: Text(featureProvider
                                                          .features[i]?.id ??
                                                      ""),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        children: <Widget>[
                                          if (featureProvider.features !=
                                                  null &&
                                              featureProvider.features[i]!
                                                      .subFeatures !=
                                                  null)
                                            for (int j = 0;
                                                j <
                                                    featureProvider.features[i]!
                                                        .subFeatures!.length;
                                                j++)
                                              Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                        width:
                                                            CustomSpacing.four),
                                                    Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                            featureProvider
                                                                    .features[
                                                                        i]!
                                                                    .subFeatures?[
                                                                        j]
                                                                    .name ??
                                                                "",
                                                            style:
                                                                typography
                                                                    .Subtitle1)),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Chip(
                                                        label: Text(
                                                            featureProvider
                                                                    .features[
                                                                        i]!
                                                                    .subFeatures?[
                                                                        j]
                                                                    .tag ??
                                                                ""),
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          SizedBox(height: CustomSpacing.two),
                                        ],
                                      ),
                                      SizedBox(height: CustomSpacing.four),
                                    ],
                                  ),
                              ],
                            ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _addFeaturesUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.paperElavation25
            : AppColors.paperElavation25Light,
        child: Consumer<FeatureProvider>(builder: (_, featureProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              featureProvider.getSubFeatures(
                  context, featureTagController.text);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: CustomSpacing.four),
                Card(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Configure Feature',
                            style: typography.H5_Regular),
                        Form(
                          key: _formFeatureKey,
                          child: Column(
                            children: [
                              SizedBox(height: CustomSpacing.four),
                              // Feature Name, Tag, Save Button
                              TextFormField(
                                controller: featureNameController,
                                decoration: InputDecoration(
                                  labelText: 'Feature Name',
                                  labelStyle: typography.Body1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a feature name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: CustomSpacing.four),
                              TextFormField(
                                controller: featureTagController,
                                decoration: InputDecoration(
                                  labelText: 'Feature Tag',
                                  labelStyle: typography.Body1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a feature tag';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Save Button
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
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
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.two),
                                  featureProvider.isCreateFeatureLoading
                                      ? Expanded(
                                          child: Container(
                                              width: 20,
                                              height: 20,
                                              child: Center(
                                                  child:
                                                      SizedBox(
                                                          width: 20,
                                                          height: 20,child: CircularProgressIndicator()))))
                                      : Expanded(
                                          child: CustomButton(
                                            onPressed: () {
                                              if (_formFeatureKey.currentState!
                                                  .validate()) {
                                                featureProvider
                                                    .createFeature(
                                                        context,
                                                        featureNameController
                                                            .text,
                                                        featureTagController
                                                            .text)
                                                    .then((value) {
                                                  getSubFeatureData(
                                                      featureTagController
                                                          .text);
                                                });
                                              }
                                            },
                                            type: ButtonType.filled,
                                            child: Text(
                                              'Save',
                                              style:
                                                  typography.ButtonLarge,
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
                SizedBox(height: CustomSpacing.two),
                Card(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Form(
                      key: _formSubFeatureKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: CustomSpacing.four),
                          Text('Add sub-feature(s)',
                              style: typography.H7),
                          SizedBox(height: CustomSpacing.six),
                          // Sub-feature Name, Tag, Add Button
                          TextFormField(
                            controller: subFeatureNameController,
                            decoration: InputDecoration(
                              labelText: 'Sub feature Name',
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a sub-feature name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: CustomSpacing.four),
                          TextFormField(
                            controller: subFeatureTagController,
                            decoration: InputDecoration(
                              labelText: 'Sub feature Tag',
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a sub-feature tag';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: CustomSpacing.four),
                          // Add Button
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Handle cancel button
                                    Navigator.pop(context);
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
                                    style: typography.ButtonLarge,
                                  ),
                                ),
                              ),
                              SizedBox(width: CustomSpacing.two),
                              featureProvider.isCreateSubFeatureLoading
                                  ? Expanded(
                                  child: Container(
                                      width: 20,
                                      height: 20,
                                      child: Center(
                                          child:
                                          SizedBox(
                                              width: 20,
                                              height: 20,child: CircularProgressIndicator()))))
                                  : Expanded(
                                child: CustomButton(
                                  onPressed: () {
                                    if (_formFeatureKey.currentState!
                                        .validate()&& _formSubFeatureKey.currentState!.validate()) {
                                      featureProvider
                                          .createSubFeature(
                                          context,
                                          featureNameController
                                              .text,
                                          featureTagController
                                              .text, subFeatureNameController.text, subFeatureTagController.text)
                                          .then((value) {
                                        getSubFeatureData(
                                            featureTagController
                                                .text);
                                      });
                                    }
                                  },
                                  type: ButtonType.filled,
                                  child: Text(
                                    'Add',
                                    style: typography.ButtonLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: CustomSpacing.six),
                featureProvider.isSubFeatureListLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                        height: 20,
                        width: 20,
                        child: Center(child: CircularProgressIndicator())),
                      ],
                    )
                    : _featuresSwitchCardUI(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _featuresSwitchCardUI() {
    var typography = CustomTypography(context);
    // Title, Subtitle is a Chip, Switch
    return Consumer<FeatureProvider>(builder: (_, featureProvider, child) {
      return Container(
        margin: EdgeInsets.only(bottom: CustomSpacing.two),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                for (int i = 0; i < featureProvider.subFeatures.length; i++)
                  Column(
                    children: [
                      ListTile(
                        title: Text(featureProvider.subFeatures[i]?.name ?? "",
                            style: typography.Body1),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                SizedBox(height: CustomSpacing.two),
                                Chip(
                                  label: Text(featureProvider.subFeatures[i]?.tag ?? ""),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {
                            // Handle switch change
                          },
                        ),
                      ),
                      i == (featureProvider.subFeatures.length - 1)
                          ? SizedBox()
                          : Divider(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  _getRolesUI() {
    var typography = CustomTypography(context);
    return Consumer<role.RoleProvider>(builder: (context, roleProvider, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: CustomSpacing.four),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Role Manager', style: typography.H5_Regular)),
          SizedBox(height: CustomSpacing.four),
          Expanded(
            child: ListView.builder(
              itemCount: roleProvider.roles.length,
              itemBuilder: (context, index) {
                return _roleCardUI(index);
              },
            ),
          ),
        ],
      );
    });
  }

  _addRoleUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: CustomSpacing.four),
          Text('Configure Role', style: typography.H5_Regular),
          SizedBox(height: CustomSpacing.four),
          // Role Name, Description, Tag, Save Button
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Role Name',
              labelStyle: typography.Body1,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: typography.Body1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Feature Tag',
              labelStyle: typography.Body1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),

          SizedBox(height: CustomSpacing.six),
          Text('Add sub-feature(s)', style: typography.H7),
          SizedBox(height: CustomSpacing.six),
          // Sub-feature Name, Tag, Add Button
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Sub feature Name',
              labelStyle: typography.Body1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Sub feature Tag',
              labelStyle: typography.Body1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          // Add Button
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
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: Text(
                    'Cancel',
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
                    'Add',
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.six),
          _featuresSwitchCardUI(),
        ],
      ),
    );
  }

  Widget _roleCardUI(int index) {
    var typography = CustomTypography(context);
    return Consumer<role.RoleProvider>(builder: (context, roleProvider, child) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.paperElavation25
            : AppColors.paperElavation25Light,
        padding: EdgeInsets.all(8),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(roleProvider.roles[index].name ?? "",
                    style: typography.Body1),
                Row(
                  children: [
                    // configure icon and status switch
                    roleProvider.isStatusLoading && selectedRole == index
                        ? Center(
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator()),
                          )
                        : Switch(
                            value: roleProvider.roles[index].status ?? false,
                            onChanged: (value) {
                              // Handle switch change
                              setState(() {
                                selectedRole = index;
                              });
                              roleProvider
                                  .changeRoleStatus(context,
                                      roleProvider.roles[index].id ?? "", value)
                                  .then((value) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() {
                                    roleProvider.roles[index].status =
                                        value;
                                  });
                                });
                              });
                            },
                          ),
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        // Handle configure button
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  _getChatsUI() {
    var typography = CustomTypography(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
            child: Center(
                child: Text('API Error',
                    style: typography.Subtitle1.copyWith(
                        color: Theme.of(context).colorScheme.error)))),
      ],
    );
  }

  _getEmailUI() {
    var typography = CustomTypography(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.four),
        Text('Email Setup', style: typography.H5_Regular),
        SizedBox(height: CustomSpacing.four),
        // TabBar for Notifications, Help Desk, Admin and Contact Us
        TabBar(
          isScrollable: true,
          controller: _emailTabController,
          labelStyle: typography.BottomNavigationActiveLabel,
          tabs: [
            Tab(
              text: 'Notifications',
            ),
            Tab(
              text: 'Help Desk',
            ),
            Tab(
              text: 'Admin',
            ),
            Tab(
              text: 'Contact Us',
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: TabBarView(
            controller: _emailTabController,
            children: [
              _getEmailNotificationFieldsUI(),
              _getEmailHelpDeskFieldsUI(),
              _getEmailAdminFieldsUI(),
              _getEmailSupportFieldsUI(),
            ],
          ),
        ),
        /**/
        /*// Navigation Rail for Notifications, Help Desk, Admin and Contact Us and on the right side Fields for email id, password, smtp server and port number
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: CustomSpacing.four),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: NavigationRail(
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          indicatorColor: AppColors.primaryMain,
                          groupAlignment: 0.0,
                          //No Shape
                          selectedIndex: _selectedEmailOption.index,
                          onDestinationSelected: (int index) {
                            setState(() {
                              _selectedEmailOption = EmailOptions.values[index];
                            });
                          },
                          selectedLabelTextStyle: typography.Subtitle1.copyWith(color: AppColors.primaryMain),
                          useIndicator: false,
                          labelType: NavigationRailLabelType.all,
                          destinations: EmailOptions.values
                              .map(
                                (option) => NavigationRailDestination(

                              indicatorColor: Colors.transparent,
                              icon: SizedBox.shrink(),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedEmailOption = option;
                                    });
                                  },
                                  child: Text(
                                    _getName(option),
                                    style: typography.Subtitle1,
                                  ),
                                ),
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Email Fields
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email ID',
                            labelStyle: typography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: CustomSpacing.two),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: typography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: CustomSpacing.two),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'SMTP Server',
                            labelStyle: typography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: CustomSpacing.two),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Port Number',
                            labelStyle: typography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: CustomSpacing.two),
                        // Save Button
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                type: ButtonType.filled, child: Text('Save', style: typography.ButtonLarge,),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),*/
      ],
    );
  }

  _getEmailNotificationFieldsUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Consumer<EmailProvider>(builder: (context, emailProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: CustomSpacing.four),
            TextFormField(
              controller: emailNotificationController,
              decoration: InputDecoration(
                labelText: 'Email ID',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: passwordNotificationController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: smtpNotificationController,
              decoration: InputDecoration(
                labelText: 'SMTP Server',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: portNotificationController,
              decoration: InputDecoration(
                labelText: 'Port Number',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              maxLength: 6,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: CustomSpacing.four),
            // Save Button
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: typography.ButtonLarge,
                    ),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                Expanded(
                  child: emailProvider.isUpdateLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomButton(
                          onPressed: () {
                            //if fields are empty we create else update
                            if (notificationEmailId == "") {
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "email_type": "notification",
                                  "email": emailNotificationController.text,
                                  "password": passwordNotificationController.text,
                                  "port": int.parse(portNotificationController.text),
                                  "host": smtpNotificationController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .createEmail(context, emailData);
                            } else {
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "id": notificationEmailId,
                                  "email_type": "notification",
                                  "email": emailNotificationController.text,
                                  "password": passwordNotificationController.text,
                                  "port": int.parse(portNotificationController.text),
                                  "host": smtpNotificationController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .updateEmail(context, emailData);
                            }
                            Map<String, dynamic> emailData = {
                              "data": {
                                "id": notificationEmailId,
                                "email_type": "notification",
                                "email": emailNotificationController.text,
                                "password": passwordNotificationController.text,
                                "port":
                                    int.parse(portNotificationController.text),
                                "host": smtpNotificationController.text
                              }
                            };
                            Provider.of<EmailProvider>(context, listen: false)
                                .updateEmail(context, emailData);
                          },
                          type: ButtonType.filled,
                          child: Text(
                            'Save',
                            style: typography.ButtonLarge,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  _getEmailHelpDeskFieldsUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Consumer<EmailProvider>(builder: (context, emailProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: CustomSpacing.four),
            TextFormField(
              controller: emailHelpDeskController,
              decoration: InputDecoration(
                labelText: 'Email ID',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: passwordHelpDeskController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: smtpHelpDeskController,
              decoration: InputDecoration(
                labelText: 'SMTP Server',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: portHelpDeskController,
              decoration: InputDecoration(
                labelText: 'Port Number',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: CustomSpacing.four),
            // Save Button
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: typography.ButtonLarge,
                    ),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                Expanded(
                  child: emailProvider.isUpdateLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomButton(
                          onPressed: () {
                            if(helpDeskEmailId==""){
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "email_type": "helpdesk",
                                  "email": emailHelpDeskController.text,
                                  "password": passwordHelpDeskController.text,
                                  "port": int.parse(portHelpDeskController.text),
                                  "host": smtpHelpDeskController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .createEmail(context, emailData);
                            }else {
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "id": helpDeskEmailId,
                                  "email_type": "helpdesk",
                                  "email": emailHelpDeskController.text,
                                  "password": passwordHelpDeskController.text,
                                  "port": int.parse(
                                      portHelpDeskController.text),
                                  "host": smtpHelpDeskController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .updateEmail(context, emailData);
                            }
                          },
                          type: ButtonType.filled,
                          child: Text(
                            'Save',
                            style: typography.ButtonLarge,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  _getEmailAdminFieldsUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Consumer<EmailProvider>(builder: (context, emailProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: CustomSpacing.four),
            TextFormField(
              controller: emailAdminController,
              decoration: InputDecoration(
                labelText: 'Email ID',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: passwordAdminController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: smtpAdminController,
              decoration: InputDecoration(
                labelText: 'SMTP Server',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: portAdminController,
              decoration: InputDecoration(
                labelText: 'Port Number',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: CustomSpacing.four),
            // Save Button
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: typography.ButtonLarge,
                    ),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                Expanded(
                  child: emailProvider.isUpdateLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomButton(
                          onPressed: () {
                            if(adminEmailId==""){
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "email_type": "admin",
                                  "email": emailAdminController.text,
                                  "password": passwordAdminController.text,
                                  "port": int.parse(portAdminController.text),
                                  "host": smtpAdminController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .createEmail(context, emailData);
                            }else {
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "id": adminEmailId,
                                  "email_type": "admin",
                                  "email": emailAdminController.text,
                                  "password": passwordAdminController.text,
                                  "port": int.parse(portAdminController.text),
                                  "host": smtpAdminController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .updateEmail(context, emailData);
                            }
                          },
                          type: ButtonType.filled,
                          child: Text(
                            'Save',
                            style: typography.ButtonLarge,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  _getEmailSupportFieldsUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Consumer<EmailProvider>(builder: (context, emailProvider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: CustomSpacing.four),
            TextFormField(
              controller: emailSupportController,
              decoration: InputDecoration(
                labelText: 'Email ID',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: passwordSupportController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: smtpSupportController,
              decoration: InputDecoration(
                labelText: 'SMTP Server',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: CustomSpacing.two),
            TextFormField(
              controller: portSupportController,
              decoration: InputDecoration(
                labelText: 'Port Number',
                labelStyle: typography.Body1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: CustomSpacing.four),
            // Save Button
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: typography.ButtonLarge,
                    ),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                Expanded(
                  child: emailProvider.isUpdateLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomButton(
                          onPressed: () {
                            if(supportEmailId==""){
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "email_type": "contactus",
                                  "email": emailSupportController.text,
                                  "password": passwordSupportController.text,
                                  "port": int.parse(portSupportController.text),
                                  "host": smtpSupportController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .createEmail(context, emailData);
                            }else {
                              Map<String, dynamic> emailData = {
                                "data": {
                                  "id": supportEmailId,
                                  "email_type": "contactus",
                                  "email": emailSupportController.text,
                                  "password": passwordSupportController.text,
                                  "port": int.parse(portSupportController.text),
                                  "host": smtpSupportController.text
                                }
                              };
                              Provider.of<EmailProvider>(context, listen: false)
                                  .updateEmail(context, emailData);
                            }
                          },
                          type: ButtonType.filled,
                          child: Text(
                            'Save',
                            style: typography.ButtonLarge,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _networkingCardUI() {
    var typography = CustomTypography(context);
    //profile avatar, role, company, rating out of 5, actions are in popupmenu (send message, connections, remove connection)
    return Container(
      margin: EdgeInsets.only(bottom: CustomSpacing.two),
      child: Card(
        child: Column(
          children: [
            // Stack with request pending container top left
            Column(
              children: [
                SizedBox(height: CustomSpacing.two),
                Row(
                  children: [
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
                        Text('Amit Didwania', style: typography.Body1),
                        SizedBox(height: CustomSpacing.two),
                        Text('Risk Manager', style: typography.Body2),
                        Text('Green', style: typography.Body2),
                        SizedBox(height: CustomSpacing.two),
                        RatingBar(rating: 4, maxRating: 5),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),
              ],
            ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: //change to custom button
                        CustomButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: _addNetworkDialogUI(),
                            );
                          },
                        );
                      },
                      type: ButtonType.filled,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: CustomSpacing.two),
                          Text(
                            'Connect',
                            style: typography.ButtonLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),
          ],
        ),
      ),
    );
  }

  _addNetworkDialogUI() {
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Avatar of user to connect, name, role, company, rating, below it textbox with title message above it as Personalized Message(Optional), hint as Say something nice!, below it two cuttons for cancel and Send Request
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundImage: AssetImage('assets/images/loginImage.png'),
          ),
          SizedBox(height: CustomSpacing.four),
          Text('Amit Didwania', style: typography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          Text('Risk Manager', style: typography.Body2),
          Text('Green', style: typography.Body2),
          SizedBox(height: CustomSpacing.two),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingBar(rating: 4, maxRating: 5),
            ],
          ),
          SizedBox(height: CustomSpacing.four),
          // Personalized Message make it bigger in size
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Personalized Message (Optional)',
                  style: typography.Body2),
            ],
          ),
          TextFormField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Say something nice!',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          // Cancel and Send Request Buttons
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
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: Text(
                    'Cancel',
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
                    'Send',
                    style: typography.ButtonLarge,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.two),
        ],
      ),
    );
  }

  _getBlockedUI() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Blocked $index'),
        );
      },
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

  String _getName(EmailOptions option) {
    switch (option) {
      case EmailOptions.notifications:
        return 'Notifications';
      case EmailOptions.helpDesk:
        return 'Help Desk';
      case EmailOptions.admin:
        return 'Admin';
      case EmailOptions.contactUs:
        return 'Contact Us';
    }
  }

  IconData? _getIcon(EmailOptions option) {
    switch (option) {
      case EmailOptions.notifications:
        return Icons.notifications;
      case EmailOptions.helpDesk:
        return Icons.help;
      case EmailOptions.admin:
        return Icons.admin_panel_settings;
      case EmailOptions.contactUs:
        return Icons.contact_page;
    }
  }
}
