import 'dart:developer';
import 'dart:io';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/corporate_type_roles_bottom_sheet.dart';
import 'package:green/design_system/components/custom_chip.dart';
import 'package:green/design_system/components/roles_bottom_sheet.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/models/company_type_model.dart';
import 'package:green/providers/company_provider.dart';
import 'package:green/providers/employee_provider.dart';
import 'package:green/providers/verification_provider.dart';
import 'package:green/screens/userManagement/connections_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/repo/constants.dart';
import '../../models/initial_data_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/company_type_model.dart' as companyType;
import '../../utils/utils.dart';
import 'package:green/models/role_model.dart' as roleModel;

class UserManagementScreen extends StatefulWidget {
  final Screens? initialScreen;
  final int initialIndex;
  final int subIndex;

  const UserManagementScreen(
      {super.key,
      this.initialScreen,
      this.initialIndex = 0,
      this.subIndex = 0});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  TabController? _tabNonCorporateController;
  TabController? _tabEmployeeController;
  TabController? _tabVerificationController;

  Screens _selectedScreen = Screens.corporateList;

  bool showCheckbox = false;

  // Create Company Form
  List<Categories> _selectedRoles = [];
  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();
  int selectedCompanyListIndex = 0;
  String? companyImageUrl;
  CorporateType? selectedCompanyType;
  bool _enableDomainCheck = false;
  List<companyType.Roles> selectedCorporateTypeRole = [];

  TextEditingController _domainListController = TextEditingController();
  TextEditingController _companyLegalNameController = TextEditingController();
  TextEditingController _companyDisplayNameController = TextEditingController();
  TextEditingController _adminNameController = TextEditingController();
  TextEditingController _adminDisplayNameController = TextEditingController();

  TextEditingController _adminEmailController = TextEditingController();
  TextEditingController _adminMobileController = TextEditingController();

  // Form key
  GlobalKey<FormState> _createCompanyFormKey = GlobalKey<FormState>();

  // Employee
  int selectedEmployeeListIndex = 0;
  String employeeImageUrl = '';
  TextEditingController _employeeNameController = TextEditingController();
  TextEditingController _employeeDisplayNameController =
      TextEditingController();
  TextEditingController _employeeEmailController = TextEditingController();
  TextEditingController _employeeMobileController = TextEditingController();
  GlobalKey<FormState> _createEmployeeFormKey = GlobalKey<FormState>();
  List<companyType.Roles> selectedEmployeeRoles = [];

  // Verification
  int selectedCorporateVerificationAcceptListIndex = 0;
  int selectedCorporateVerificationRejectListIndex = 0;
  int selectedUserVerificationAcceptListIndex = 0;
  int selectedUserVerificationRejectListIndex = 0;
  List<roleModel.Roles> allRoles = [];
  roleModel.Roles? selectedRole;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        setState(() {
          _selectedScreen = Screens.corporateList;
        });
      } else if (_tabController?.index == 1) {
        setState(() {
          _selectedScreen = Screens.nonCorporateList;
        });
      } else if (_tabController?.index == 2) {
        setState(() {
          _selectedScreen = Screens.employeeList;
        });
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
    _tabNonCorporateController = TabController(length: 3, vsync: this);
    _tabEmployeeController = TabController(length: 3, vsync: this);
    _tabVerificationController = TabController(length: 2, vsync: this);

    _getData();

    if (widget.initialIndex == 0) {
      _tabController?.animateTo(0);
      if (widget.initialScreen == Screens.verificationList) {
        _selectedScreen = Screens.verificationList;
        //Future.delayed(Duration(seconds: 1), () {
          if (widget.subIndex == 0) {
            _tabVerificationController?.animateTo(0);
          } else if (widget.subIndex == 1) {
            _tabVerificationController?.animateTo(1);
          }
       // });
      }
    } else if (widget.initialIndex == 1) {
      _tabController?.animateTo(1);
    } else if (widget.initialIndex == 2) {
      _tabController?.animateTo(2);
    }
    super.initState();
  }

  Future<void> _getData() async {
    Provider.of<CompanyProvider>(context, listen: false)
        .getAllCompanies(context, "searchText", "filter");
    Provider.of<CompanyProvider>(context, listen: false)
        .getCorporateType(context);
    Provider.of<EmployeeProvider>(context, listen: false)
        .getAllEmployees(context, "searchText", "filter");
    Provider.of<VerificationProvider>(context, listen: false)
        .getAllCorporateRequests(context);
    Provider.of<VerificationProvider>(context, listen: false)
        .getAllUserRequests(context);
    allRoles = await Provider.of<RoleProvider>(context, listen: false)
        .getAllRoles(context);
    selectedEmployeeRoles =
        await Provider.of<EmployeeProvider>(context, listen: false)
            .getRoles(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
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
        floatingActionButton: _selectedScreen != Screens.corporateEdit &&
                _selectedScreen != Screens.corporateAdd &&
                _selectedScreen != Screens.corporateEmployeeAdd &&
                _selectedScreen != Screens.employeeAdd &&
                _selectedScreen != Screens.nonCorporateList &&
                _selectedScreen != Screens.verificationList
            ? FloatingActionButton(
                onPressed: () {
                  if (_selectedScreen == Screens.corporateList) {
                    setState(() {
                      _selectedScreen = Screens.corporateAdd;
                    });
                  } else if (_selectedScreen == Screens.corporateEmployeeList) {
                    setState(() {
                      _selectedScreen = Screens.corporateEmployeeAdd;
                    });
                  } else if (_selectedScreen == Screens.employeeList) {
                    setState(() {
                      _selectedScreen = Screens.employeeAdd;
                    });
                  }
                },
                child: Icon(Icons.add),
              )
            : SizedBox(),
        body: PopScope(
          canPop: _selectedScreen == Screens.corporateList && !showCheckbox,
          onPopInvoked: (canPop) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
            if (showCheckbox) {
              setState(() {
                showCheckbox = false;
              });
              return;
            }
            if (_selectedScreen == Screens.corporateAdd) {
              setState(() {
                _selectedScreen = Screens.corporateList;
              });
            } else if (_selectedScreen == Screens.corporateEdit) {
              setState(() {
                _selectedScreen = Screens.corporateList;
              });
            } else if (_selectedScreen == Screens.corporateEmployeeList) {
              setState(() {
                _selectedScreen = Screens.corporateList;
              });
            } else if (_selectedScreen == Screens.corporateEmployeeAdd) {
              setState(() {
                _selectedScreen = Screens.corporateEmployeeList;
              });
            } else if (_selectedScreen == Screens.employeeAdd) {
              setState(() {
                _selectedScreen = Screens.employeeList;
              });
            } else if (_selectedScreen == Screens.employeeEdit) {
              setState(() {
                _selectedScreen = Screens.employeeList;
              });
            } else if (_selectedScreen == Screens.verificationList) {
              setState(() {
                _selectedScreen = Screens.corporateList;
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
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: CustomTypography.H5_Regular.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
                          ),
                          // Add 3 tabs
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          TabBar(
                            isScrollable: true,
                            controller: _tabController,
                            labelStyle:
                                CustomTypography.BottomNavigationActiveLabel,
                            tabs: [
                              Tab(
                                child: DropdownButton(
                                  underline: SizedBox(),
                                  value: 'Corporate',
                                  items: [
                                    DropdownMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(Icons.apartment),
                                          SizedBox(width: CustomSpacing.two),
                                          Text(
                                            'Corporate Management',
                                            style: CustomTypography
                                                .BottomNavigationActiveLabel,
                                          ),
                                        ],
                                      ),
                                      value: 'Corporate',
                                    ),
                                    DropdownMenuItem(
                                      child: Text(
                                        'Companies',
                                        style: CustomTypography
                                            .BottomNavigationActiveLabel,
                                      ),
                                      value: 'Companies',
                                    ),
                                    DropdownMenuItem(
                                      child: Text(
                                        'Users',
                                        style: CustomTypography
                                            .BottomNavigationActiveLabel,
                                      ),
                                      value: 'Users',
                                    ),
                                    DropdownMenuItem(
                                      child: Text(
                                        'Company Profiles',
                                        style: CustomTypography
                                            .BottomNavigationActiveLabel,
                                      ),
                                      value: 'Company Profiles',
                                    ),
                                    DropdownMenuItem(
                                      child: Text(
                                        'Verification Requests',
                                        style: CustomTypography
                                            .BottomNavigationActiveLabel,
                                      ),
                                      value: 'Verification Requests',
                                    ),
                                  ],
                                  onChanged: (value) {
                                    // Handle dropdown item selection
                                    if (value == 'Corporate') {
                                      setState(() {
                                        _selectedScreen = Screens.corporateList;
                                      });
                                    } else if (value == 'Companies') {
                                      setState(() {
                                        _selectedScreen = Screens.corporateList;
                                      });
                                    } else if (value == 'Users') {
                                      setState(() {
                                        _selectedScreen =
                                            Screens.corporateEmployeeList;
                                      });
                                    } else if (value == 'Company Profiles') {
                                      // Handle company profiles option
                                    } else if (value ==
                                        'Verification Requests') {
                                      // Handle verification requests option
                                      setState(() {
                                        _selectedScreen =
                                            Screens.verificationList;
                                      });
                                    } else if (value == 'AnotherOption') {
                                      // Handle another option
                                    }
                                    _tabController?.animateTo(0);
                                  },
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(1);
                                  _selectedScreen = Screens.nonCorporateList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
                                    Tab(text: 'Non Corporate Management'),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(2);
                                  _selectedScreen = Screens.employeeList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_circle),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
                                    Tab(text: 'Employee Management'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Add 3 tab views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Corporate Management
                                //_corporateManagement(),
                                _getCorporateManagementUI(),
                                // Non Corporate Management
                                _getNonCorporateManagementUI(),
                                // Employee Management
                                _getEmployeeManagementUI(),
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
        endDrawer: Drawer(
          child: ListView(
            children: [
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  // Handle settings
                },
              ),
              ListTile(
                title: Text('Logout'),
                onTap: () {},
              ),
            ],
          ),
        ),
      );
    });
  }

  _corporateManagement() {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<CompanyProvider>(context, listen: false)
            .getAllCompanies(context, "searchText", "filter");
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CustomSpacing.four,
          ),
          Text('Companies',
              style: CustomTypography.H6.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.black)),
          SizedBox(
            height: CustomSpacing.four,
          ),
          Text('Manage companies from this place',
              style: CustomTypography.Body2),
          SizedBox(
            height: CustomSpacing.four,
          ),
          // Add Search and filter dropdown in a row
          Row(
            children: [
              Expanded(
                flex: 7,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Name, email or mobile ...',
                    label: Text('Search', style: CustomTypography.Body1),
                    hintStyle: CustomTypography.Body1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: CustomSpacing.four,
              ),
              GestureDetector(
                onTap: () {
                  // Open bottom sheet here
                  /* showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                          // Build your filter bottom sheet UI here
                          );
                    },
                  );*/
                  //Show end drawer
                  Scaffold.of(context).openEndDrawer();
                },
                child: Icon(
                  Icons.filter_list,
                  size: 30,
                ),
              ),
            ],
          ),
          SizedBox(
            height: CustomSpacing.four,
          ),
          // select all checkbox
          showCheckbox
              ? Consumer<CompanyProvider>(builder: (_, companyProvider, child) {
                  return Row(
                    children: [
                      Checkbox(
                        value: companyProvider.companies
                            .every((element) => element.isSelected!),
                        onChanged: (value) {
                          // Handle select all checkbox value change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            companyProvider.companies.forEach((element) {
                              setState(() {
                                element.isSelected = value;
                              });
                            });
                          });
                        },
                      ),
                      Text('Select All', style: CustomTypography.Body1),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Handle delete selected companies
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Companies',
                                    style: CustomTypography.H7),
                                content: Text(
                                    'Are you sure you want to delete selected companies?',
                                    style: CustomTypography.Body2),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      companyProvider
                                          .deleteMultipleCompanies(
                                              context,
                                              companyProvider.companies
                                                  .where((element) =>
                                                      element.isSelected ==
                                                      true)
                                                  .map((e) => e.id ?? '')
                                                  .toList())
                                          .then((value) {
                                        if (value) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            setState(() {
                                              companyProvider.companies
                                                  .removeWhere((element) =>
                                                      element.isSelected ==
                                                      true);
                                            });
                                          });
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            setState(() {
                                              showCheckbox = false;
                                            });
                                          });
                                        }
                                      });
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                })
              : SizedBox(),

          // Add Company List
          Expanded(
            child: Consumer<CompanyProvider>(
                builder: (context, companyProvider, child) {
              return companyProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : companyProvider.companies.isEmpty
                      ? Center(
                          child: Text('No companies',
                              style: CustomTypography.Body1),
                        )
                      : ListView.builder(
                          itemCount: companyProvider.companies.length,
                          itemBuilder: (context, index) {
                            return _companyListItem(index, companyProvider);
                          },
                        );
            }),
          ),
        ],
      ),
    );
  }

  _companyListItem(int index, CompanyProvider companyProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: () {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          selectedCompanyListIndex = index;
          setState(() {
            companyProvider.companies[index].isSelected =
                !companyProvider.companies[index].isSelected!;
          });
        },
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: CustomSpacing.two,
              ),
              Row(
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  showCheckbox
                      ? Checkbox(
                          value: companyProvider.companies[index].isSelected!,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                companyProvider.companies[index].isSelected =
                                    value;
                              });
                            });
                          },
                        )
                      : SizedBox(),
                  CircleAvatar(
                    child: companyProvider.companies[index].companyImageUrl !=
                                null &&
                            companyProvider.companies[index].companyImageUrl !=
                                ''
                        ? ClipOval(
                            child: Image.network(
                              companyProvider.companies[index].companyImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            companyProvider.companies[index].displayName
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                "",
                          ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (companyProvider.companies[index].displayName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (companyProvider.companies[index].displayName
                                      ?.substring(1) ??
                                  ""),
                          style: CustomTypography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                            companyProvider.companies[index].companyTypeName ??
                                "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  companyProvider.isStatusLoading &&
                          selectedCompanyListIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Switch(
                          value: companyProvider.companies[index].isEnabled ??
                              false,
                          onChanged: (value) {
                            // Handle switch value change
                            selectedCompanyListIndex = index;
                            companyProvider
                                .changeCompanyStatus(
                                    context,
                                    companyProvider.companies[index].id ?? '',
                                    value)
                                .then((value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  companyProvider.companies[index].isEnabled =
                                      value;
                                });
                              });
                            });
                          },
                        ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      Text(
                        (companyProvider.companies[index].admins?.name
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                "") +
                            (companyProvider.companies[index].admins?.name
                                    ?.substring(1) ??
                                ""),
                        style: CustomTypography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black),
                      ),
                      Text(companyProvider.companies[index].admins?.email ?? '',
                          style: CustomTypography.Caption),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  // bottom left and right corners curved
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        setState(() {
                          _selectedScreen = Screens.corporateEmployeeList;
                        });
                      },
                      icon: Icon(Icons.people),
                      label: Text('View Employees',
                          style: CustomTypography.Caption.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit),
                      color: AppColors.primaryMain,
                      onPressed: () async {
                        /// Handle edit company
                        await companyProvider.viewCompany(
                            context, companyProvider.companies[index].id ?? '');
                        log(companyProvider.company.toJson().toString());
                        // Prefill values
                        companyImageUrl =
                            companyProvider.company.companyImageUrl;
                        selectedCompanyType = CorporateType(
                          name: companyProvider.company.companyTypeName,
                          type: companyProvider.company.companyType,
                        );
                        _enableDomainCheck =
                            companyProvider.company.enableDomainCheck ?? false;
                        selectedCorporateTypeRole = [
                          companyType.Roles(
                            name: "Admin",
                            role: "admin",
                          )
                        ];
                        _domainListController.text =
                            companyProvider.company.domainList?.join(",") ?? '';
                        _companyLegalNameController.text =
                            companyProvider.company.name ?? '';
                        if (companyProvider.company.displayName != null) {
                          _companyDisplayNameController.text = companyProvider
                                      .company.displayName!
                                      .substring(0, 1)
                                      .toUpperCase() +
                                  companyProvider.company.displayName!
                                      .substring(1) ??
                              '';
                        }

                        _adminNameController.text =
                            companyProvider.company.admins?.name ?? "";
                        _adminDisplayNameController.text =
                            companyProvider.company.admins?.displayName ?? '';
                        _adminEmailController.text =
                            companyProvider.company.admins?.email ?? '';
                        _selectedCountryCode = _adminMobileController.text =
                            companyProvider.company.admins?.mobile ?? '';
                        _enableDomainCheck =
                            companyProvider.company.enableDomainCheck ?? false;
                        // Set screen to edit

                        setState(() {
                          _selectedScreen = Screens.corporateEdit;
                        });
                      },
                    ),
                    companyProvider.isDeleteLoading &&
                            selectedCompanyListIndex == index
                        ? Center(
                            child: Container(
                                height: 20,
                                width: 20,
                                margin: EdgeInsets.only(right: 8),
                                child: CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: Icon(Icons.delete),
                            color: AppColors.primaryMain,
                            onPressed: () {
                              selectedCompanyListIndex = index;
                              // Handle delete by showing dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  // delete company name
                                  return AlertDialog(
                                    title: Text('Delete Company',
                                        style: CustomTypography.H6),
                                    content: Text(
                                        'Are you sure you want to delete ${companyProvider.companies[index].displayName}?',
                                        style: CustomTypography.Body1),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          companyProvider.deleteCompany(
                                              context, [
                                            companyProvider
                                                    .companies[index].id ??
                                                ''
                                          ]).then((value) {
                                            if (value) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                setState(() {
                                                  companyProvider.companies
                                                      .removeAt(index);
                                                });
                                              });
                                            }
                                          });
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _corporateEmployeeManagement() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: CustomSpacing.four,
        ),
        // Add Search and filter dropdown in a row
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Name, email or mobile ...',
                  label: Text('Search', style: CustomTypography.Body1),
                  hintStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: CustomSpacing.four,
            ),
            GestureDetector(
              onTap: () {
                // Open bottom sheet here
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        // Build your filter bottom sheet UI here
                        );
                  },
                );
              },
              child: Icon(
                Icons.filter_list,
                size: 30,
              ),
            ),
          ],
        ),
        // Add Company List
        SizedBox(
          height: CustomSpacing.four,
        ),
        Expanded(
          child: Consumer<EmployeeProvider>(
              builder: (context, employeeProvider, child) {
            return ListView.builder(
              itemCount: employeeProvider.employeeList?.length,
              itemBuilder: (context, index) {
                return _companyEmployeeListItem(index, employeeProvider);
              },
            );
          }),
        ),
      ],
    );
  }

  _createCompany() {
    // Add Company
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: 8),
        child: Card(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Text('Create new corporate account',
                          style: CustomTypography.H7.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Text(
                          'Please provide the necessary information to establish a new corporate account.',
                          style: CustomTypography.Body2),
                      SizedBox(
                        height: CustomSpacing.three,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.one,
                      ),
                      // Add Company Form
                      // Profile Pic
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // If company image is not uploaded, show default image
                            companyImageUrl == null || companyImageUrl == ''
                                ? CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/images/loginImage.png'),
                                    radius: 40,
                                  )
                                : CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(companyImageUrl!),
                                    radius: 40,
                                  ),
                            SizedBox(
                              width: CustomSpacing.four,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: CustomSpacing.two,
                                ),
                                Text(
                                  "Upload Image",
                                  style: CustomTypography.Body1.copyWith(
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
                                Consumer<CompanyProvider>(
                                    builder: (_, companyProvider, child) {
                                  return companyProvider.isImageUploadLoading
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : CustomButton(
                                          type: ButtonType.filled,
                                          onPressed: () {
                                            // Show image picker
                                            ImagePicker()
                                                .pickImage(
                                                    source: ImageSource.gallery)
                                                .then((value) {
                                              if (value != null) {
                                                // Handle image upload
                                                File v = File(value.path);
                                                Provider.of<CompanyProvider>(
                                                        context,
                                                        listen: false)
                                                    .uploadImage(context, v)
                                                    .then((value) {
                                                  if (value != '') {
                                                    // Handle image upload response
                                                    setState(() {
                                                      companyImageUrl = value;
                                                    });
                                                  }
                                                });
                                              }
                                            });
                                          },
                                          child: Text(
                                            "Upload Image",
                                            style: CustomTypography.ButtonLarge,
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: CustomSpacing.four),
                      Form(
                          key: _createCompanyFormKey,
                          child: Column(children: [
                            // Company Type
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Company Type',
                                        labelStyle: CustomTypography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: companyProvider.corporateType
                                          .map((corporateType) {
                                        return DropdownMenuItem(
                                          child: Text(
                                            corporateType.name ?? "",
                                            // Assuming 'name' is the property that holds the role name
                                            style: CustomTypography.Body1,
                                          ),
                                          value: corporateType
                                              .id, // Assuming 'id' is the property that uniquely identifies the role
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        // Handle dropdown value change
                                        if (value != null) {
                                          setState(() {
                                            selectedCompanyType =
                                                companyProvider.corporateType
                                                    .firstWhere((element) =>
                                                        element.id == value);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),

                            SizedBox(height: CustomSpacing.four),

                            // Switch for Enable/Disable Domain
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Enable Domain Check?',
                                    style: CustomTypography.Body1,
                                  ),
                                  Switch(
                                    value: _enableDomainCheck,
                                    onChanged: (value) {
                                      // Handle switch value change
                                      setState(() {
                                        _enableDomainCheck = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: CustomSpacing.four),
                            // Domain List
                            _enableDomainCheck
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: _domainListController,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Domain List (Separated by commas)',
                                          labelStyle: CustomTypography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == "" ||
                                              !RegExp(r'@(?:[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)(?:,@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)*')
                                                  .hasMatch(value!)) {
                                            return 'Please select a domain';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: CustomSpacing.four),
                                    ],
                                  )
                                : SizedBox(),
                            // Company Legal Name
                            TextFormField(
                              controller: _companyLegalNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Legal Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return 'Please enter a legal name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Company Display Name
                            TextFormField(
                              controller: _companyDisplayNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Display Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'Display name cannot contain digits';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // User & Role(s) divider
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'User & Role(s)',
                                  style: CustomTypography.Subtitle1.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                                SizedBox(width: CustomSpacing.three),
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: Colors.white
                                        .withOpacity(0.11999999731779099),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Role Dropdown
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              print(
                                  'Selected Company Type: $selectedCorporateTypeRole');
                              return Stack(
                                children: [
                                  TextField(
                                    readOnly: true,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        useSafeArea: true,
                                        isScrollControlled: true,
                                        builder: (BuildContext context) {
                                          return CorporateTypeRolesBottomSheet(
                                            selectedRoles:
                                                selectedCorporateTypeRole,
                                            addChip: _addCorporateChip,
                                            removeChip: _removeCorporateChip,
                                            removeAllChips:
                                                _removeAllCorporateChips,
                                            roles: selectedCompanyType?.roles ??
                                                [],
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
                                      hintText: _selectedRoles.isEmpty
                                          ? 'Select Roles'
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
                                              return CorporateTypeRolesBottomSheet(
                                                selectedRoles:
                                                    selectedCorporateTypeRole,
                                                addChip: _addCorporateChip,
                                                removeChip:
                                                    _removeCorporateChip,
                                                removeAllChips:
                                                    _removeAllCorporateChips,
                                                roles: selectedCompanyType
                                                        ?.roles ??
                                                    [],
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
                                      margin:
                                          const EdgeInsets.only(right: 32.0),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: selectedCorporateTypeRole
                                              .map(
                                                (value) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Chip(
                                                    label:
                                                        Text(value.name ?? ''),
                                                    deleteIcon:
                                                        Icon(Icons.cancel),
                                                    onDeleted: () =>
                                                        _removeCorporateChip(
                                                            value),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            SizedBox(height: CustomSpacing.four),
                            // Name
                            TextFormField(
                              controller: _adminNameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Display Name
                            TextFormField(
                              controller: _adminDisplayNameController,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'Display name cannot contain digits';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0),
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
                                        diallingCodeStyle:
                                            CustomTypography.Body1,
                                        isShowInputField: false,
                                        dialogTheme: DialogThemeData(
                                          style: CustomTypography.Body1,
                                          isShowFloatButton: false,
                                        ),
                                        countryNameStyle:
                                            CustomTypography.Body1,
                                        isShowCountryName: false,
                                        onCountryChanged: (country) {
                                          print(
                                              'This is the country code: $country');
                                          setState(() {
                                            _selectedCountryCode =
                                                country.dialing_code;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.four),

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
                                      if (!RegExp(r'^[0-9]+$')
                                          .hasMatch(value!)) {
                                        return 'Mobile number can only contain digits';
                                      }
                                      return null;
                                    },
                                    controller: _adminMobileController,
                                  ),
                                ),
                                // Dropdown Icon Suffix
                              ],
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Email
                            TextFormField(
                              controller: _adminEmailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    regextest(value) == false) {
                                  return 'Enter a valid email address';
                                }
                                // You can add more specific email validation here if needed
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Cancel and Submit Buttons
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: companyProvider.isLoading
                                            ? Center(
                                                child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(),
                                              ))
                                            : CustomButton(
                                                type: ButtonType.filled,
                                                onPressed: () {
                                                  _createCompanyFormKey
                                                      .currentState
                                                      ?.validate();
                                                  // validate
                                                  if (_adminNameController
                                                          .text.isEmpty ||
                                                      _adminEmailController
                                                          .text.isEmpty ||
                                                      _companyLegalNameController
                                                          .text.isEmpty ||
                                                      selectedCompanyType ==
                                                          null ||
                                                      selectedCorporateTypeRole
                                                          .isEmpty) {
                                                    // Show snackbar with name of field empty
                                                    if (_adminNameController
                                                        .text.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'User Name cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (_adminEmailController
                                                        .text.isEmpty) {
                                                      // check regex for email
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'User Email cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (_companyLegalNameController
                                                        .text.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Company Legal Name cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (selectedCompanyType ==
                                                        null) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Company Type cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (selectedCorporateTypeRole
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Role(s) cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  // Create body
                                                  /* Sample
                                                {
                      "data": {
                          "action": "create_company",
                          "userdata": {
                              "name": "new company pro",
                              "displayName": "dfgfdfgdf",
                              "email": "projectgreendev@gmail.com",
                              "phone": "9999988888",
                              "country_code": "+91",
                              "accountType": "individual",
                              "isIndividual": false,
                              "roles": [
                                  {
                    "name": "Admin",
                    "role": "admin"
                                  }
                              ],
                              "company_type_id": "project_green",
                              "company_type_name": "Project Green",
                              "company_type": "project_green",
                              "company_name": "Project Green Pvt Ltd",
                              "company_display_name": "Greens",
                              "enable_domain_check": false,
                              "domain_list": [],
                              "is_pgsupport": true, // true or false
                              "is_email_password": true
                          }
                      }
                  }
                                                */
                                                  Map<String, dynamic> body = {
                                                    "action": "create_company",
                                                    "userdata": {
                                                      "name":
                                                          _adminNameController
                                                              .text,
                                                      "displayName":
                                                          _adminDisplayNameController
                                                              .text,
                                                      "email":
                                                          _adminEmailController
                                                              .text,
                                                      "phone":
                                                          _adminMobileController
                                                              .text,
                                                      "country_code":
                                                          _selectedCountryCode,
                                                      "roles":
                                                          selectedCorporateTypeRole
                                                              .map((e) => {
                                                                    "name":
                                                                        e.name,
                                                                    "role":
                                                                        e.role
                                                                  })
                                                              .toList(),
                                                      "company_type_id":
                                                          selectedCompanyType
                                                              ?.id,
                                                      "company_type_name":
                                                          selectedCompanyType
                                                              ?.name,
                                                      "company_type":
                                                          selectedCompanyType
                                                              ?.type,
                                                      "company_name":
                                                          _companyLegalNameController
                                                              .text,
                                                      "company_display_name":
                                                          _companyDisplayNameController
                                                              .text,
                                                      "enable_domain_check":
                                                          _enableDomainCheck,
                                                      "domain_list":
                                                          _domainListController
                                                              .text
                                                              .split(','),
                                                      "is_pgsupport": false,
                                                      "isIndividual": false,
                                                      "company_image_url":
                                                          companyImageUrl,
                                                    }
                                                  };
                                                  companyProvider
                                                      .createCompany(
                                                          context, body)
                                                      .then((value) {
                                                    if (value) {
                                                      // Handle success
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        setState(() {
                                                          _selectedScreen =
                                                              Screens
                                                                  .corporateList;
                                                        });
                                                        //Clear all fields
                                                        _adminNameController
                                                            .clear();
                                                        _adminDisplayNameController
                                                            .clear();
                                                        _adminEmailController
                                                            .clear();
                                                        _adminMobileController
                                                            .clear();
                                                        _companyLegalNameController
                                                            .clear();
                                                        _companyDisplayNameController
                                                            .clear();
                                                        _domainListController
                                                            .clear();
                                                        _selectedRoles.clear();
                                                        _textEditingController
                                                            .clear();
                                                        selectedCorporateTypeRole
                                                            .clear();
                                                        companyImageUrl = '';
                                                        // get data to update the list

                                                        companyProvider
                                                            .getAllCompanies(
                                                                context,
                                                                "",
                                                                "");
                                                      });
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                  'Submit',
                                                  style: CustomTypography
                                                      .ButtonLarge,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Handle cancel button
                                            setState(() {
                                              _selectedScreen =
                                                  Screens.corporateList;
                                            });
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
                              );
                            }),
                          ]))
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  _editCompany() {
    // Add Company
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: 8),
        child: Card(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Text('Edit corporate account',
                          style: CustomTypography.H7.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Row(
                        children: [
                          Text('Please provide the necessary information.',
                              style: CustomTypography.Body2),
                        ],
                      ),
                      SizedBox(
                        height: CustomSpacing.three,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.one,
                      ),
                      // Add Company Form
                      // Profile Pic
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // If company image is not uploaded, show default image
                            companyImageUrl == null || companyImageUrl == ''
                                ? CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/images/loginImage.png'),
                                    radius: 40,
                                  )
                                : CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(companyImageUrl!),
                                    radius: 40,
                                  ),
                            SizedBox(
                              width: CustomSpacing.four,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: CustomSpacing.two,
                                ),
                                Text(
                                  "Upload Image",
                                  style: CustomTypography.Body1.copyWith(
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
                                Consumer<CompanyProvider>(
                                    builder: (_, companyProvider, child) {
                                  return companyProvider.isImageUploadLoading
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : CustomButton(
                                          type: ButtonType.filled,
                                          onPressed: () {
                                            // Show image picker
                                            ImagePicker()
                                                .pickImage(
                                                    source: ImageSource.gallery)
                                                .then((value) {
                                              if (value != null) {
                                                // Handle image upload
                                                File v = File(value.path);
                                                Provider.of<CompanyProvider>(
                                                        context,
                                                        listen: false)
                                                    .uploadImage(context, v)
                                                    .then((value) {
                                                  if (value != '') {
                                                    // Handle image upload response
                                                    setState(() {
                                                      companyImageUrl = value;
                                                    });
                                                  }
                                                });
                                              }
                                            });
                                          },
                                          child: Text(
                                            "Upload Image",
                                            style: CustomTypography.ButtonLarge,
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: CustomSpacing.four),
                      Form(
                          key: _createCompanyFormKey,
                          child: Column(children: [
                            // Company Type
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      value: selectedCompanyType?.type,
                                      decoration: InputDecoration(
                                        labelText: 'Company Type',
                                        labelStyle: CustomTypography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          child: Text(
                                            selectedCompanyType?.name ?? "",
                                            style: CustomTypography.Body1,
                                          ),
                                          value: selectedCompanyType?.type,
                                        ),
                                      ],
                                      onChanged: null,
                                    ),
                                  ),
                                ],
                              );
                            }),

                            SizedBox(height: CustomSpacing.four),

                            // Switch for Enable/Disable Domain
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Enable Domain Check?',
                                    style: CustomTypography.Body1,
                                  ),
                                  Switch(
                                    value: _enableDomainCheck,
                                    onChanged: (value) {
                                      // Handle switch value change
                                      setState(() {
                                        _enableDomainCheck = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: CustomSpacing.four),
                            // Domain List
                            _enableDomainCheck
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: _domainListController,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Domain List (Separated by commas)',
                                          labelStyle: CustomTypography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == "" ||
                                              !RegExp(r'@(?:[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)(?:,@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)*')
                                                  .hasMatch(value!)) {
                                            return 'Please select a domain';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: CustomSpacing.four),
                                    ],
                                  )
                                : SizedBox(),
                            // Company Legal Name
                            TextFormField(
                              controller: _companyLegalNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Legal Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return 'Please enter a legal name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Company Display Name
                            TextFormField(
                              controller: _companyDisplayNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Display Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'Display name cannot contain digits';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // User & Role(s) divider
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'User & Role(s)',
                                  style: CustomTypography.Subtitle1.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                                SizedBox(width: CustomSpacing.three),
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: Colors.white
                                        .withOpacity(0.11999999731779099),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Role Dropdown
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              print(
                                  'Selected Company Type: $selectedCorporateTypeRole');
                              return Stack(
                                children: [
                                  TextField(
                                    readOnly: true,
                                    onTap: null,
                                    onChanged: (value) {
                                      // Handle input changes
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Role(s)',
                                      hintText: _selectedRoles.isEmpty
                                          ? 'Select Roles'
                                          : "",
                                      border: OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.arrow_drop_down),
                                        onPressed: null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10.0,
                                    left: 10.0,
                                    right: 10.0,
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(right: 32.0),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: selectedCorporateTypeRole
                                              .map(
                                                (value) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Chip(
                                                    label:
                                                        Text(value.name ?? ''),
                                                    deleteIcon:
                                                        Icon(Icons.cancel),
                                                    onDeleted: null,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            SizedBox(height: CustomSpacing.four),
                            // Name
                            TextFormField(
                              readOnly: true,
                              controller: _adminNameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Display Name
                            TextFormField(
                              readOnly: true,
                              controller: _adminDisplayNameController,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return 'Display name cannot contain digits';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0),
                                    child: Center(
                                      child: CountryListPicker(
                                        initialCountry: Countries.United_States,
                                        border: InputBorder.none,
                                        flagSize: Size(35, 30),
                                        onChanged: null,
                                        diallingCodeStyle:
                                            CustomTypography.Body1,
                                        isShowInputField: false,
                                        dialogTheme: DialogThemeData(
                                          style: CustomTypography.Body1,
                                          isShowFloatButton: false,
                                        ),
                                        countryNameStyle:
                                            CustomTypography.Body1,
                                        isShowCountryName: false,
                                        onCountryChanged: null,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.four),

                                // Mobile Number TextFormField
                                Expanded(
                                  flex: 7,
                                  child: TextFormField(
                                    readOnly: true,
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
                                      if (!RegExp(r'^[0-9]+$')
                                          .hasMatch(value!)) {
                                        return 'Mobile number can only contain digits';
                                      }
                                      return null;
                                    },
                                    controller: _adminMobileController,
                                  ),
                                ),
                                // Dropdown Icon Suffix
                              ],
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Email
                            TextFormField(
                              readOnly: true,
                              controller: _adminEmailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: CustomTypography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    regextest(value) == false) {
                                  return 'Enter a valid email address';
                                }
                                // You can add more specific email validation here if needed
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Cancel and Submit Buttons
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: companyProvider.isLoading
                                            ? Center(
                                                child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(),
                                              ))
                                            : CustomButton(
                                                type: ButtonType.filled,
                                                onPressed: () {
                                                  if (!_createCompanyFormKey
                                                      .currentState!
                                                      .validate()) {
                                                    return;
                                                  }
                                                  // validate
                                                  if (_adminNameController
                                                          .text.isEmpty ||
                                                      _adminEmailController
                                                          .text.isEmpty ||
                                                      _companyLegalNameController
                                                          .text.isEmpty ||
                                                      selectedCompanyType ==
                                                          null ||
                                                      selectedCorporateTypeRole
                                                          .isEmpty) {
                                                    // Show snackbar with name of field empty
                                                    if (_adminNameController
                                                        .text.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'User Name cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (_adminEmailController
                                                        .text.isEmpty) {
                                                      // check regex for email
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'User Email cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (_companyLegalNameController
                                                        .text.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Company Legal Name cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (selectedCompanyType ==
                                                        null) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Company Type cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    } else if (selectedCorporateTypeRole
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Role(s) cannot be empty',
                                                              style:
                                                                  CustomTypography
                                                                      .Body1),
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  // Edit body

                                                  Map<String, dynamic> body = {
                                                    "action": "create_company",
                                                    "userdata": {
                                                      "company_id":
                                                          companyProvider
                                                              .company.id,
                                                      "company_name":
                                                          _companyLegalNameController
                                                              .text,
                                                      "company_display_name":
                                                          _companyDisplayNameController
                                                              .text,
                                                      "enable_domain_check":
                                                          _enableDomainCheck,
                                                      "domain_list":
                                                          _domainListController
                                                              .text
                                                              .split(','),
                                                      "company_image_url":
                                                          companyImageUrl,
                                                    }
                                                  };
                                                  companyProvider
                                                      .updateCompany(
                                                          context, body)
                                                      .then((value) {
                                                    if (value) {
                                                      // Handle success
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        setState(() {
                                                          _selectedScreen =
                                                              Screens
                                                                  .corporateList;
                                                        });
                                                        //Clear all fields
                                                        _adminNameController
                                                            .clear();
                                                        _adminDisplayNameController
                                                            .clear();
                                                        _adminEmailController
                                                            .clear();
                                                        _adminMobileController
                                                            .clear();
                                                        _companyLegalNameController
                                                            .clear();
                                                        _companyDisplayNameController
                                                            .clear();
                                                        _domainListController
                                                            .clear();
                                                        _selectedRoles.clear();
                                                        _textEditingController
                                                            .clear();
                                                        selectedCorporateTypeRole
                                                            .clear();
                                                        companyImageUrl = '';
                                                        // get data to update the list

                                                        companyProvider
                                                            .getAllCompanies(
                                                                context,
                                                                "",
                                                                "");
                                                      });
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                  'Submit',
                                                  style: CustomTypography
                                                      .ButtonLarge,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Handle cancel button
                                            setState(() {
                                              _selectedScreen =
                                                  Screens.corporateList;
                                            });
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
                              );
                            }),
                          ]))
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  _companyEmployeeListItem(int index, EmployeeProvider employeeProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: () {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          selectedCompanyListIndex = index;
          setState(() {
            employeeProvider.employeeList?[index].isSelected =
                !employeeProvider.employeeList![index].isSelected;
          });
        },
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: CustomSpacing.two,
              ),
              Row(
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  showCheckbox
                      ? Checkbox(
                          value:
                              employeeProvider.employeeList?[index].isSelected!,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                employeeProvider
                                    .employeeList?[index].isSelected = value!;
                              });
                            });
                          },
                        )
                      : SizedBox(),
                  CircleAvatar(
                    child:
                        employeeProvider.employeeList?[index].displayImageUrl !=
                                    null &&
                                employeeProvider
                                        .employeeList?[index].displayImageUrl !=
                                    ''
                            ? ClipOval(
                                child: Image.network(
                                  employeeProvider
                                      .employeeList![index].displayImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                employeeProvider.employeeList?[index].name
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    "",
                              ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (employeeProvider.employeeList?[index].name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (employeeProvider.employeeList?[index].name
                                      ?.substring(1) ??
                                  ""),
                          style: CustomTypography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(employeeProvider.employeeList?[index].email ?? "",
                            style: CustomTypography.Caption),
                        Text(employeeProvider.employeeList?[index].phone ?? "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  employeeProvider.isStatusLoading &&
                          selectedEmployeeListIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Switch(
                          value: employeeProvider.employeeList?[index].status ??
                              false,
                          onChanged: (value) {
                            // Handle switch value change
                            selectedCompanyListIndex = index;
                            employeeProvider
                                .changeEmployeeStatus(
                                    context,
                                    employeeProvider.employeeList?[index].id ??
                                        '',
                                    value)
                                .then((value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  employeeProvider.employeeList?[index].status =
                                      value;
                                });
                              });
                            });
                          },
                        ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      CustomChip(
                          label: Text(
                              employeeProvider.employeeList?[index].role ??
                                  '')),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  // bottom left and right corners curved
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        setState(() {
                          _selectedScreen = Screens.corporateEmployeeList;
                        });
                      },
                      icon: Icon(Icons.people),
                      label: Text('View Connections',
                          style: CustomTypography.Caption.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit),
                      color: AppColors.primaryMain,
                      onPressed: () async {
                        /// Handle edit company
                        await employeeProvider.viewEmployee(context,
                            employeeProvider.employeeList?[index].id ?? '');
                        log(employeeProvider.employees.toJson().toString());
                        // Prefill values
                        companyImageUrl =
                            employeeProvider.employees.displayImageUrl ?? '';

                        // Set screen to edit

                        setState(() {
                          _selectedScreen = Screens.corporateEdit;
                        });
                      },
                    ),
                    employeeProvider.isDeleteLoading &&
                            selectedCompanyListIndex == index
                        ? Center(
                            child: Container(
                                height: 20,
                                width: 20,
                                margin: EdgeInsets.only(right: 8),
                                child: CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: Icon(Icons.delete),
                            color: AppColors.primaryMain,
                            onPressed: () {
                              selectedEmployeeListIndex = index;
                              // Handle delete by showing dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  // delete company name
                                  return AlertDialog(
                                    title: Text('Delete Employee',
                                        style: CustomTypography.H6),
                                    content: Text(
                                        'Are you sure you want to delete ${employeeProvider.employeeList?[index].name}?',
                                        style: CustomTypography.Body1),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          employeeProvider.deleteCompany(
                                              context, [
                                            employeeProvider
                                                    .employeeList?[index].id ??
                                                ''
                                          ]).then((value) {
                                            if (value) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                setState(() {
                                                  employeeProvider.employeeList
                                                      ?.removeAt(index);
                                                });
                                              });
                                            }
                                          });
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*  _companyEmployeeListItem() {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (value) {
            // Handle checkbox value change
          },
        ),
        title: Text('Employee Name', style: CustomTypography.Body1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee Email', style: CustomTypography.Body1),
            Text('Employee Phone', style: CustomTypography.Body1),
            Chip(
              label: Text('Role Name'),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry>[
                PopupMenuItem(
                  child: ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/connectionIcon.svg',
                      width: 24,
                      height: 24,
                    ),
                    title: Text('View Connections'),
                    onTap: () {
                      // Handle view connections
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ConnectionsScreen()));
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Employee'),
                    onTap: () {
                      // Handle edit employee
                      Navigator.pop(context);
                      setState(() {
                        _selectedScreen = Screens.corporateEmployeeAdd;
                      });
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete Employee'),
                    onTap: () {
                      // Handle delete employee
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            Switch(
              value: true,
              onChanged: (value) {
                // Handle switch value change
              },
            ),
          ],
        ),
      ),
    );
  }*/

  _createEmployee() {
    // Add Company
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperElavation25,
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    Text('Create new employee account',
                        style: CustomTypography.Body1),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Text(
                        'Please provide the necessary information to establish a new employee account.',
                        style: CustomTypography.Body2),
                    SizedBox(
                      height: CustomSpacing.three,
                    ),
                    SizedBox(
                      height: CustomSpacing.three,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),

              // Add Company Form
              // Profile Pic
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // If company image is not uploaded, show default image
                    employeeImageUrl == null || employeeImageUrl == ''
                        ? CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/images/loginImage.png'),
                            radius: 40,
                          )
                        : CircleAvatar(
                            backgroundImage: NetworkImage(employeeImageUrl!),
                            radius: 40,
                          ),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Upload Image",
                          style: CustomTypography.Body1.copyWith(
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                        Text(
                          "Min 400x400px\nPNG or JPEG",
                          style: CustomTypography.BottomNavigationActiveLabel,
                          textAlign: TextAlign.center,
                        ),
                        // Add button
                        Consumer<EmployeeProvider>(
                            builder: (_, employeeProvider, child) {
                          return employeeProvider.isImageUploadLoading
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : CustomButton(
                                  type: ButtonType.filled,
                                  onPressed: () {
                                    // Show image picker
                                    ImagePicker()
                                        .pickImage(source: ImageSource.gallery)
                                        .then((value) {
                                      if (value != null) {
                                        // Handle image upload
                                        File v = File(value.path);
                                        Provider.of<EmployeeProvider>(context,
                                                listen: false)
                                            .uploadImage(context, v)
                                            .then((value) {
                                          if (value != '') {
                                            // Handle image upload response
                                            setState(() {
                                              employeeImageUrl = value;
                                            });
                                          }
                                        });
                                      }
                                    });
                                  },
                                  child: Text(
                                    "Upload Image",
                                    style: CustomTypography.ButtonLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              Form(
                  key: _createEmployeeFormKey,
                  child: Column(children: [
                    // Name
                    TextFormField(
                      controller: _employeeNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: CustomTypography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == "") {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    // Role Dropdown
                    Consumer<EmployeeProvider>(
                        builder: (_, employeeProvider, child) {
                      print(
                          'Selected Employee Type: $selectedCorporateTypeRole');
                      return Stack(
                        children: [
                          TextField(
                            readOnly: true,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                useSafeArea: true,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return CorporateTypeRolesBottomSheet(
                                    selectedRoles: selectedCorporateTypeRole,
                                    addChip: _addCorporateChip,
                                    removeChip: _removeCorporateChip,
                                    removeAllChips: _removeAllCorporateChips,
                                    roles: employeeProvider.roles ?? [],
                                    isEnabled: true,
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
                                      return CorporateTypeRolesBottomSheet(
                                        selectedRoles:
                                            selectedCorporateTypeRole,
                                        addChip: _addCorporateChip,
                                        removeChip: _removeCorporateChip,
                                        removeAllChips:
                                            _removeAllCorporateChips,
                                        roles: employeeProvider.roles ?? [],
                                        isEnabled: true,
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
                                  children: selectedCorporateTypeRole
                                      .map(
                                        (value) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Chip(
                                            label: Text(value.name ?? ''),
                                            deleteIcon: Icon(Icons.cancel),
                                            onDeleted: () =>
                                                _removeCorporateChip(value),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    // Email
                    TextFormField(
                      controller: _employeeEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: CustomTypography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            regextest(value) == false) {
                          return 'Enter a valid email address';
                        }
                        // You can add more specific email validation here if needed
                        return null;
                      },
                    ),
                    SizedBox(
                      height: CustomSpacing.four,
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
                            controller: _employeeMobileController,
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
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: CustomSpacing.four),
                    SizedBox(height: CustomSpacing.two),
                    // Cancel and Submit Buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Consumer<EmployeeProvider>(
                                builder: (context, employeeProvider, child) {
                              return Expanded(
                                child: employeeProvider.isLoading
                                    ? Center(
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : CustomButton(
                                        type: ButtonType.filled,
                                        onPressed: () {
                                          // Handle submit button
                                          if (!_createEmployeeFormKey
                                              .currentState!
                                              .validate()) {
                                            return;
                                          }
                                          if (_selectedScreen ==
                                              Screens.employeeAdd) {
                                            var body = {
                                              "action": "create_user",
                                              "userdata": {
                                                "selectedCountryCode":
                                                    _selectedCountryCode,
                                                "name": _employeeNameController
                                                    .text,
                                                "email":
                                                    _employeeEmailController
                                                        .text,
                                                "roles":
                                                    selectedCorporateTypeRole
                                                        .map((role) => {
                                                              "name": role.name,
                                                              "role": role.role,
                                                              "is_applicable_for_internal":
                                                                  role.isApplicableForInternal,
                                                              "status":
                                                                  role.status
                                                            })
                                                        .toList(),
                                                "phone":
                                                    _employeeMobileController
                                                        .text,
                                                "country_code":
                                                    _selectedCountryCode,
                                                "display_image_url":
                                                    employeeImageUrl,
                                                "is_pgsupport": true,
                                                "isIndividual": true,
                                                "displayName": "",
                                              }
                                            };

                                            Provider.of<EmployeeProvider>(
                                                    context,
                                                    listen: false)
                                                .createEmployee(context, body)
                                                .then((value) {
                                              if (value) {
                                                // Handle success
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  setState(() {
                                                    _selectedScreen =
                                                        Screens.employeeList;
                                                  });
                                                  //Clear all fields
                                                  _employeeNameController
                                                      .clear();
                                                  _employeeEmailController
                                                      .clear();
                                                  _employeeMobileController
                                                      .clear();
                                                  _selectedRoles.clear();
                                                  _textEditingController
                                                      .clear();
                                                  employeeImageUrl = '';
                                                });
                                              }
                                            });
                                          } else {
                                            // use employeeProvider.employees to update
                                            /*
                                    * {

        "userdata": {
            "user_id": "i3xh2rb68VepWgycLmddoWiPulC2",
            "display_image_url": null,
            "name": "Projec green super",
            "roles": [
                {
                    "role": "admin",
                    "name": "Admin"
                }
            ],
            "displayName": "pg super admin",
            "phone": "8767767667",
            // "email":"dam@tam.com",
            "country_code": "+1",
            "isIndividual": false
        }
}*/
                                            var body = {
                                              "userdata": {
                                                "user_id": employeeProvider
                                                    .employees.userId,
                                                "display_image_url":
                                                    employeeImageUrl,
                                                "name": _employeeNameController
                                                    .text,
                                                "roles":
                                                    selectedCorporateTypeRole
                                                        .map((role) => {
                                                              "name": role.name,
                                                              "role": role.role,
                                                              "is_applicable_for_internal":
                                                                  role.isApplicableForInternal,
                                                              "status":
                                                                  role.status
                                                            })
                                                        .toList(),
                                                "displayName": "",
                                                "phone":
                                                    _employeeMobileController
                                                        .text,
                                                "country_code":
                                                    _selectedCountryCode,
                                                "isIndividual": true
                                              }
                                            };

                                            Provider.of<EmployeeProvider>(
                                                    context,
                                                    listen: false)
                                                .updateEmployee(context, body)
                                                .then((value) {
                                              if (value) {
                                                // Handle success
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  setState(() {
                                                    _selectedScreen =
                                                        Screens.employeeList;
                                                  });
                                                  //Clear all fields
                                                  _employeeNameController
                                                      .clear();
                                                  _employeeEmailController
                                                      .clear();
                                                  _employeeMobileController
                                                      .clear();
                                                  _selectedRoles.clear();
                                                  _textEditingController
                                                      .clear();
                                                  employeeImageUrl = '';
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: Text(
                                          'Submit',
                                          style: CustomTypography.ButtonLarge,
                                        ),
                                      ),
                              );
                            }),
                          ],
                        ),
                        SizedBox(height: CustomSpacing.one),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle cancel button
                                  setState(() {
                                    _selectedScreen = Screens.employeeList;
                                  });
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
                          ],
                        ),
                      ],
                    ),
                  ]))
            ]),
      ),
    );
  }

  /*_employeeManagement() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: CustomSpacing.four,
        ),
        Text('Employee Management', style: CustomTypography.Body1),
        SizedBox(
          height: CustomSpacing.two,
        ),
        Text('Manage companies from this place', style: CustomTypography.Body2),
        SizedBox(
          height: CustomSpacing.four,
        ),
        // Add Search and filter dropdown in a row
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Name, email or mobile ...',
                  label: Text('Search', style: CustomTypography.Body1),
                  hintStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: CustomSpacing.four,
            ),
            GestureDetector(
              onTap: () {
                // Open bottom sheet here
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        // Build your filter bottom sheet UI here
                        );
                  },
                );
              },
              child: Icon(
                Icons.filter_list,
                size: 30,
              ),
            ),
          ],
        ),
        // Add Company List
        SizedBox(
          height: CustomSpacing.four,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return _companyListItem();
            },
          ),
        ),
      ],
    );
  }*/

  void _addCorporateChip(value) {
    setState(() {
      selectedCorporateTypeRole?.add(value);
      _textEditingController.clear();
    });
  }

  void _removeCorporateChip(value) {
    print('Removing chip: ${value.name}');
    setState(() {
      selectedCorporateTypeRole
          ?.removeWhere((element) => element.name == value.name);
    });
    print(
        'Selected roles: ${_selectedRoles.map((role) => role.name).toList()}');
  }

  void _removeAllCorporateChips() {
    setState(() {
      selectedCorporateTypeRole?.clear();
    });
  }

  void _addChip(value) {
    setState(() {
      _selectedRoles.add(value);
      _textEditingController.clear();
    });
  }

  void _removeChip(value) {
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

  _getCorporateManagementUI() {
    if (_selectedScreen == Screens.corporateList) {
      return _corporateManagement();
    } else if (_selectedScreen == Screens.corporateAdd) {
      return _createCompany();
    } else if (_selectedScreen == Screens.corporateEdit) {
      return _editCompany();
    } else if (_selectedScreen == Screens.corporateEmployeeList) {
      return _corporateEmployeeManagement();
    } else if (_selectedScreen == Screens.corporateEmployeeAdd) {
      return _createEmployee();
    } else if (_selectedScreen == Screens.verificationList) {
      return _verificationRequestsUI();
    } else {
      return _corporateManagement();
    }
  }

  /// Corporate Management
  _getNonCorporateManagementUI() {
    if (_selectedScreen == Screens.nonCorporateList) {
      return _nonCorporateManagement();
    } else {
      return _nonCorporateManagement();
    }
  }

  _nonCorporateManagement() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: CustomSpacing.four,
        ),
        // Add Search and filter dropdown in a row
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Name, email or mobile ...',
                  label: Text('Search', style: CustomTypography.Body1),
                  hintStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: CustomSpacing.four,
            ),
            GestureDetector(
              onTap: () {
                // Open bottom sheet here
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        // Build your filter bottom sheet UI here
                        );
                  },
                );
              },
              child: Icon(
                Icons.filter_list,
                size: 30,
              ),
            ),
          ],
        ),
        // Toolbar with chips for filter, a text button for clear filter and show number of selections, vertical divider and deselect text and delete button
        SizedBox(
          height: CustomSpacing.four,
        ),
        Row(
          children: [
            // Filter Chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Chip(
                      label: Text('Filter 1'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    SizedBox(
                      width: CustomSpacing.two,
                    ),
                    Chip(
                      label: Text('Filter 2'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    SizedBox(
                      width: CustomSpacing.two,
                    ),
                    Chip(
                      label: Text('Filter 3'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    // Clear Filter Button
                    TextButton(
                      onPressed: () {
                        // Handle clear filter
                      },
                      child: Text('Clear Filter'),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical Divider
            VerticalDivider(
              thickness: 1,
              color: Colors.white.withOpacity(0.5),
            ),
            // Deselect Text
            Text('Deselect'),
            // Delete Button
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Handle delete filter
              },
            ),
          ],
        ),
        SizedBox(
          height: CustomSpacing.four,
        ),
        TabBar(
          isScrollable: true,
          controller: _tabNonCorporateController,
          tabs: [
            Tab(
                child: Row(
              children: [
                Text(
                  'All',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
            Tab(
                child: Row(
              children: [
                Text(
                  'Active',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
            Tab(
                child: Row(
              children: [
                Text(
                  'Pending',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: CustomSpacing.four,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabNonCorporateController,
                  children: [
                    // All Tab
                    ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _nonCorporateListItem();
                      },
                    ),
                    // Active Tab
                    ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _nonCorporateListItem();
                      },
                    ),
                    // Pending Tab
                    ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _nonCorporateListItem();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _nonCorporateListItem() {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.black
                          : AppColors.white,
                  backgroundImage: AssetImage('assets/images/loginImage.png'),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Phone',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  children: [
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          child: ListTile(
                            leading: SvgPicture.asset(
                                'assets/images/connectIcon.svg'),
                            title: Text('View Connections'),
                            onTap: () {
                              // Handle view employees
                              Navigator.pop(context);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ConnectionsScreen(
                                    userId: 'userId',
                                    userName: 'userName',
                                  )));
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            onTap: () {
                              // Handle edit company
                              Navigator.pop(context);
                              setState(() {
                                _selectedScreen = Screens.corporateAdd;
                              });
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            onTap: () {
                              // Handle edit company
                              Navigator.pop(context);
                              setState(() {
                                _selectedScreen = Screens.corporateAdd;
                              });
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 16.0,
                              ),
                              Text('Status',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              SizedBox(width: 16.0),
                              Switch(
                                value: true,
                                onChanged: (value) {
                                  // Handle switch value change
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Checkbox(
                      value: false,
                      onChanged: (value) {
                        // Handle checkbox value change
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Employee Management

  _getEmployeeManagementUI() {
    if (_selectedScreen == Screens.employeeList) {
      return _employeeManagement();
    } else if (_selectedScreen == Screens.employeeAdd) {
      return _createEmployee();
    } else if (_selectedScreen == Screens.employeeEdit) {
      return _createEmployee();
    } else {
      return _employeeManagement();
    }
  }

  _employeeManagement() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: CustomSpacing.four,
        ),
        Text('Employee Management', style: CustomTypography.Body1),
        SizedBox(
          height: CustomSpacing.two,
        ),
        Text('Manage companies from this place', style: CustomTypography.Body2),
        SizedBox(
          height: CustomSpacing.four,
        ),
        // Add Search and filter dropdown in a row
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Name, email or mobile ...',
                  label: Text('Search', style: CustomTypography.Body1),
                  hintStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: CustomSpacing.four,
            ),
            GestureDetector(
              onTap: () {
                // Open bottom sheet here
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        // Build your filter bottom sheet UI here
                        );
                  },
                );
              },
              child: Icon(
                Icons.filter_list,
                size: 30,
              ),
            ),
          ],
        ),
        // Toolbar with chips for filter, a text button for clear filter and show number of selections, vertical divider and deselect text and delete button
        SizedBox(
          height: CustomSpacing.four,
        ),
        Row(
          children: [
            // Filter Chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Chip(
                      label: Text('Filter 1'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    SizedBox(
                      width: CustomSpacing.two,
                    ),
                    Chip(
                      label: Text('Filter 2'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    SizedBox(
                      width: CustomSpacing.two,
                    ),
                    Chip(
                      label: Text('Filter 3'),
                      onDeleted: () {
                        // Handle delete filter
                      },
                    ),
                    // Clear Filter Button
                    TextButton(
                      onPressed: () {
                        // Handle clear filter
                      },
                      child: Text('Clear Filter'),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical Divider
            VerticalDivider(
              thickness: 1,
              color: Colors.white.withOpacity(0.5),
            ),
            // Deselect Text
            Text('Deselect'),
            // Delete Button
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Handle delete filter
              },
            ),
          ],
        ),
        SizedBox(
          height: CustomSpacing.four,
        ),
        TabBar(
          isScrollable: true,
          controller: _tabEmployeeController,
          tabs: [
            Tab(
                child: Row(
              children: [
                Text(
                  'All',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
            Tab(
                child: Row(
              children: [
                Text(
                  'Active',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
            Tab(
                child: Row(
              children: [
                Text(
                  'Pending',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                SizedBox(
                  width: CustomSpacing.two,
                ),
                // rounded container to show number of all users
                SizedBox(
                  height: 25,
                  width: 35,
                  child: Chip(
                    labelPadding: EdgeInsets.all(0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '10',
                      style:
                          CustomTypography.BottomNavigationActiveLabel.copyWith(
                              height: -0.6),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: CustomSpacing.four,
              ),
              Consumer<EmployeeProvider>(
                  builder: (context, employeeProvider, child) {
                return Expanded(
                  child: TabBarView(
                    controller: _tabEmployeeController,
                    children: [
                      // All Tab
                      ListView.builder(
                        itemCount: employeeProvider.employeeList?.length ?? 0,
                        itemBuilder: (context, index) {
                          return _employeeManagementListItem(
                              index, employeeProvider);
                        },
                      ),
                      // Active Tab
                      ListView.builder(
                        itemCount: employeeProvider.employeeList?.length ?? 0,
                        itemBuilder: (context, index) {
                          return _employeeManagementListItem(
                              index, employeeProvider);
                        },
                      ),
                      // Pending Tab
                      ListView.builder(
                        itemCount: employeeProvider.employeeList?.length ?? 0,
                        itemBuilder: (context, index) {
                          return _employeeManagementListItem(
                              index, employeeProvider);
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  _employeeManagementListItem(int index, EmployeeProvider employeeProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: () {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          selectedCompanyListIndex = index;
          setState(() {
            employeeProvider.employeeList?[index].isSelected =
                !employeeProvider.employeeList![index].isSelected;
          });
        },
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: CustomSpacing.two,
              ),
              Row(
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  showCheckbox
                      ? Checkbox(
                          value:
                              employeeProvider.employeeList?[index].isSelected!,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                employeeProvider
                                    .employeeList?[index].isSelected = value!;
                              });
                            });
                          },
                        )
                      : SizedBox(),
                  CircleAvatar(
                    child:
                        employeeProvider.employeeList?[index].displayImageUrl !=
                                    null &&
                                employeeProvider
                                        .employeeList?[index].displayImageUrl !=
                                    ''
                            ? ClipOval(
                                child: Image.network(
                                  employeeProvider
                                      .employeeList![index].displayImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                employeeProvider.employeeList?[index].name
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    "",
                              ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (employeeProvider.employeeList?[index].name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (employeeProvider.employeeList?[index].name
                                      ?.substring(1) ??
                                  ""),
                          style: CustomTypography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(employeeProvider.employeeList?[index].email ?? "",
                            style: CustomTypography.Caption),
                        Text(employeeProvider.employeeList?[index].phone ?? "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  employeeProvider.isStatusLoading &&
                          selectedEmployeeListIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Switch(
                          value: employeeProvider.employeeList?[index].status ??
                              false,
                          onChanged: (value) {
                            // Handle switch value change
                            selectedCompanyListIndex = index;
                            employeeProvider
                                .changeEmployeeStatus(
                                    context,
                                    employeeProvider.employeeList?[index].id ??
                                        '',
                                    value)
                                .then((value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  employeeProvider.employeeList?[index].status =
                                      value;
                                });
                              });
                            });
                          },
                        ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      CustomChip(
                          label: Text(
                              employeeProvider.employeeList?[index].role ??
                                  '')),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  // bottom left and right corners curved
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(
                              userId: employeeProvider.employeeList?[index].id??"",
                              userName: employeeProvider.employeeList?[index].name??"",
                            )));
                      },
                      icon: Icon(Icons.people),
                      label: Text('View Connections',
                          style: CustomTypography.Caption.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                    ),
                    Spacer(),
                    employeeProvider.isEditViewEmployeeLoading
                        ? Center(
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.edit),
                            color: AppColors.primaryMain,
                            onPressed: () async {
                              /// Handle edit company
                              await employeeProvider.viewEmployee(
                                  context,
                                  employeeProvider.employeeList?[index].id ??
                                      '');
                              log(employeeProvider.employees
                                  .toJson()
                                  .toString());
                              // Prefill values
                              employeeImageUrl =
                                  employeeProvider.employees.displayImageUrl ??
                                      '';

                              // Prefill values
                              _employeeNameController.text =
                                  employeeProvider.employees.name ?? '';
                              _employeeEmailController.text =
                                  employeeProvider.employees.email ?? '';
                              _employeeMobileController.text =
                                  employeeProvider.employees.phone ?? '';
                              selectedCorporateTypeRole =
                                  (employeeProvider.employees.role ?? [])
                                      .map((role) => companyType.Roles(
                                            isForIndividual: null,
                                            isMultipleRoleEnabled: null,
                                            isApplicableForTrial: null,
                                            name: role.name,
                                            role: role.role,
                                            isApplicableForInternal:
                                                role.isApplicableForInternal,
                                            status: role.status,
                                          ))
                                      .toList();

                              //selectedCorporateTypeRole = employeeProvider.employees. ?? [];

                              // Set screen to edit
                              setState(() {
                                _selectedScreen = Screens.employeeEdit;
                              });
                            },
                          ),
                    employeeProvider.isDeleteLoading &&
                            selectedCompanyListIndex == index
                        ? Center(
                            child: Container(
                                height: 20,
                                width: 20,
                                margin: EdgeInsets.only(right: 8),
                                child: CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: Icon(Icons.delete),
                            color: AppColors.primaryMain,
                            onPressed: () {
                              selectedEmployeeListIndex = index;
                              // Handle delete by showing dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  // delete company name
                                  return AlertDialog(
                                    title: Text('Delete Employee',
                                        style: CustomTypography.H6),
                                    content: Text(
                                        'Are you sure you want to delete ${employeeProvider.employeeList?[index].name}?',
                                        style: CustomTypography.Body1),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          employeeProvider.deleteCompany(
                                              context, [
                                            employeeProvider
                                                    .employeeList?[index].id ??
                                                ''
                                          ]).then((value) {
                                            if (value) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                setState(() {
                                                  employeeProvider.employeeList
                                                      ?.removeAt(index);
                                                });
                                              });
                                            }
                                          });
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _verificationRequestsUI() {
    return Container(
      color: AppColors.paperElavation25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CustomSpacing.five,
          ),
          Text('Verification Requests', style: CustomTypography.H7),
          SizedBox(
            height: CustomSpacing.three,
          ),
          Text('Manage all accounts request from this panel',
              style: CustomTypography.Body2),
          SizedBox(
            height: CustomSpacing.two,
          ),
          // two tabs for Corporate verification and user verification
          TabBar(
            controller: _tabVerificationController,
            tabs: [
              Tab(
                child: Text(
                  'Corporate',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
              ),
              Tab(
                child: Text(
                  'User',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabVerificationController,
              children: [
                // Corporate Tab
                RefreshIndicator(
                  onRefresh: () async {
                    Provider.of<VerificationProvider>(context, listen: false)
                        .getAllCorporateRequests(context);
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Expanded(
                        child: Consumer<VerificationProvider>(
                            builder: (context, verificationProvider, child) {
                          print(verificationProvider.corporateRequests.length);
                          return verificationProvider.isCorporateLoading
                              ? Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : verificationProvider.corporateRequests.isEmpty
                                  ? SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6,
                                            child: Center(
                                              child: Text(
                                                "No Requests",
                                                style: CustomTypography.Body1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: verificationProvider
                                          .corporateRequests.length,
                                      itemBuilder: (context, index) {
                                        return _verificationCorporateRequestsListItem(
                                            index, verificationProvider);
                                      },
                                    );
                        }),
                      ),
                    ],
                  ),
                ),
                // User Tab
                RefreshIndicator(
                  onRefresh: () async {
                    Provider.of<VerificationProvider>(context, listen: false)
                        .getAllUserRequests(context);
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Expanded(
                        child: Consumer<VerificationProvider>(
                            builder: (context, verificationProvider, child) {
                          return verificationProvider.isUserLoading
                              ? Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : verificationProvider.userRequests.isEmpty
                                  ? SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6,
                                            child: Center(
                                              child: Text(
                                                "No Requests",
                                                style: CustomTypography.Body1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: verificationProvider
                                          .userRequests.length,
                                      itemBuilder: (context, index) {
                                        return _verificationUserRequestsListItem(
                                            index, verificationProvider);
                                      },
                                    );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _verificationCorporateRequestsListItem(
      int index, VerificationProvider verificationProvider) {
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    height: CustomSpacing.one,
                  ),
                  //Use rich Text and color inverted values to white
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '“${verificationProvider.corporateRequests[index].admin?.name ?? ""}”',
                          style: CustomTypography.Body1_5.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' has requested to create new corporate account for company name ',
                          style: CustomTypography.Body1_5,
                        ),
                        TextSpan(
                          text:
                              '“${verificationProvider.corporateRequests[index].companyName}”',
                          style: CustomTypography.Body1_5.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: CustomSpacing.one,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomChip(
                            label: Text(
                                verificationProvider.corporateRequests[index]
                                        .admin?.email ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                            label: Text(
                                verificationProvider.corporateRequests[index]
                                        .admin?.phone ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                            label: Text(
                                verificationProvider.corporateRequests[index]
                                        .companyTypeName ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                            label: Text('Admin',
                                style: CustomTypography.InputLabel)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                // bottom left and right corners curved
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  verificationProvider.isCorporateAcceptLoading &&
                          selectedCorporateVerificationAcceptListIndex == index
                      ? Center(
                          child: Container(
                            margin: EdgeInsets.only(left: 24),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : CustomButton(
                          type: ButtonType.outlined,
                          onPressed: () {
                            // Handle accept
                            selectedCorporateVerificationAcceptListIndex =
                                index;
                            verificationProvider
                                .changeCorporateVerificationStatus(
                                    context,
                                    verificationProvider
                                            .corporateRequests[index].id ??
                                        "",
                                    true)
                                .then((value) {
                              if (value) {
                                if (value) {
                                  verificationProvider
                                      .getAllCorporateRequests(context);
                                }
                              }
                            });
                          },
                          child: Text('Accept',
                              style:
                                  CustomTypography.BottomNavigationActiveLabel
                                      .copyWith(color: AppColors.primaryMain)),
                        ),
                  SizedBox(width: CustomSpacing.two),
                  verificationProvider.isCorporateRejectLoading &&
                          selectedCorporateVerificationRejectListIndex == index
                      ? Center(
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : CustomButton(
                          type: ButtonType.text,
                          onPressed: () {
                            // Handle reject
                            selectedCorporateVerificationRejectListIndex =
                                index;
                            verificationProvider
                                .changeCorporateVerificationStatus(
                                    context,
                                    verificationProvider
                                            .corporateRequests[index].id ??
                                        "",
                                    false)
                                .then((value) {
                              if (value) {
                                if (value) {
                                  verificationProvider
                                      .getAllCorporateRequests(context);
                                }
                              }
                            });
                          },
                          child: Text('Reject',
                              style:
                                  CustomTypography.BottomNavigationActiveLabel
                                      .copyWith(color: AppColors.primaryMain)),
                        ),
                  Spacer(),
                  //date
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: CustomSpacing.two),
                      Text('Mar 7, 2024 23:26',
                          style: CustomTypography.Caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _verificationUserRequestsListItem(
      int index, VerificationProvider verificationProvider) {
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    height: CustomSpacing.one,
                  ),
                  //Use rich Text and color inverted values to white
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '“${verificationProvider.userRequests[index].name ?? ""}”',
                          style: CustomTypography.Body1_5.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' has requested to create new corporate account.',
                          style: CustomTypography.Body1_5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: CustomSpacing.one,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomChip(
                            label: Text(
                                verificationProvider
                                        .userRequests[index].email ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                            label: Text(
                                verificationProvider
                                        .userRequests[index].phone ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                            onPressed: () {
                              //Show a dialog with outlined dropdown with allRoles, user can save or cancel (as column)
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Select Role',
                                        style: CustomTypography.H6),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: CustomSpacing.two,
                                        ),
                                        DropdownButtonFormField(
                                          items: allRoles
                                              .where((role) =>
                                                  role.isApplicableForInternal ==
                                                  true) // Filter out roles where isApplicableForTrial is not true
                                              .map((role) {
                                            return DropdownMenuItem(
                                              child: Text(role.name ?? ""),
                                              value: role,
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            // Handle dropdown value change
                                            selectedRole =
                                                value as roleModel.Roles;
                                          },
                                          value: selectedRole,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: CustomSpacing.two,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    type: ButtonType.filled,
                                                    onPressed: () {
                                                      // Handle save role
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Save',
                                                        style: CustomTypography
                                                            .BottomNavigationActiveLabel),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    type: ButtonType.text,
                                                    onPressed: () {
                                                      // Handle cancel
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Cancel',
                                                        style: CustomTypography
                                                                .BottomNavigationActiveLabel
                                                            .copyWith(
                                                                color: AppColors
                                                                    .primaryMain)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            label: Text(
                                verificationProvider.userRequests[index].role ??
                                    "",
                                style: CustomTypography.InputLabel)),
                        SizedBox(width: CustomSpacing.two),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                // bottom left and right corners curved
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  verificationProvider.isCorporateAcceptLoading &&
                          selectedUserVerificationAcceptListIndex == index
                      ? Center(
                          child: Container(
                            margin: EdgeInsets.only(left: 24),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : CustomButton(
                          type: ButtonType.outlined,
                          onPressed: () {
                            // Handle accept
                            selectedUserVerificationAcceptListIndex = index;
                            verificationProvider
                                .changeUserVerificationStatus(
                                    context,
                                    verificationProvider
                                            .userRequests[index].id ??
                                        "",
                                    true)
                                .then((value) {
                              if (value) {
                                if (value) {
                                  verificationProvider
                                      .getAllUserRequests(context);
                                }
                              }
                            });
                          },
                          child: Text('Accept',
                              style:
                                  CustomTypography.BottomNavigationActiveLabel
                                      .copyWith(color: AppColors.primaryMain)),
                        ),
                  SizedBox(width: CustomSpacing.two),
                  verificationProvider.isUserRejectLoading &&
                          selectedUserVerificationRejectListIndex == index
                      ? Center(
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : CustomButton(
                          type: ButtonType.text,
                          onPressed: () {
                            // Handle reject
                            selectedUserVerificationRejectListIndex = index;
                            verificationProvider
                                .changeUserVerificationStatus(
                                    context,
                                    verificationProvider
                                            .userRequests[index].id ??
                                        "",
                                    false)
                                .then((value) {
                              if (value) {
                                verificationProvider
                                    .getAllUserRequests(context);
                              }
                            });
                          },
                          child: Text('Reject',
                              style:
                                  CustomTypography.BottomNavigationActiveLabel
                                      .copyWith(color: AppColors.primaryMain)),
                        ),
                  Spacer(),
                  //date
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: CustomSpacing.two),
                      Text('Mar 7, 2024 23:26',
                          style: CustomTypography.Caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
