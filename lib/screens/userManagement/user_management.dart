import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:green/design_system/components/corporate_type_roles_bottom_sheet.dart';
import 'package:green/design_system/components/custom_chip.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/models/company_type_model.dart';
import 'package:green/models/role_model.dart' as roleModel;
import 'package:green/providers/company_provider.dart';
import 'package:green/providers/employee_provider.dart';
import 'package:green/providers/non_corporate_user_Provider.dart';
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
import '../../models/company_type_model.dart' as companyType;
import '../../models/initial_data_model.dart';
import '../../models/user_corporate_model.dart';
import '../../providers/corporate_user_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import '../../service/shared_preference_service.dart';
import '../../utils/utils.dart';

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
  String? corporateUserId = "";
  String? nonCorporateUserId = "";

  // Create Company Form
  List<Categories> _selectedRoles = [];
  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();
  int selectedCompanyListIndex = 0;
  int selectedCompanyEmployeeListIndex = 0;
  int selectedNonCorporateListIndex = 0;
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
  int selectedCorporateListIndex = 0;
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

  String selectedCorporateId = '';

  // Claims local variables
  bool showCorporateList = true;
  bool showCorporateUserList = true;
  bool showCorporateUserListDropdown = true;
  bool showCreateCorporate = true;
  bool showEditCorporate = true;
  bool showViewCorporate = true;
  bool showDeleteCorporate = true;
  bool showEnableDisableCorporate = true;
  bool showCorporateVerificationTab = true;
  bool showUserVerificationTab = true;
  bool showCorporateProfile = true;
  bool showEnableDisableUser = true;
  bool showDeleteUser = true;
  bool showEditUser = true;
  bool showConnectionListUser = true;
  bool showCreateUser = true;
  bool showEnableDisableNonCorporate = true;
  bool showDeleteNonCorporate = true;
  bool showEditNonCorporate = true;
  bool showNonCorporateConnectionList = true;
  bool showEnableDisableEmployee = true;
  bool showDeleteEmployee = true;
  bool showEditEmployee = true;
  bool showConnectionListEmployee = true;
  bool showCreateEmployee = true;
  bool showNonCorporateList = true;
  bool showEmployeeList = true;
  bool showCorporateManagementTab = true;
  bool showNonCorporateManagementTab = true;
  bool showEmployeeManagementTab = true;

  bool showMainLoading = true;
  int visibleTabCount = 0;


  List<DropdownMenuItem<String>> corporateDropdownItems = [
    DropdownMenuItem(
      child: Row(
        children: [
          Icon(Icons.apartment),
          SizedBox(width: CustomSpacing.two),
          Text(
            'Corporate Management',
            style: CustomTypography.BottomNavigationActiveLabel,
          ),
        ],
      ),
      value: 'Corporate',
    ),
    DropdownMenuItem(
      child: Text(
        'Companies',
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Companies',
    ),
    DropdownMenuItem(
      child: Text(
        'Users',
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Users',
    ),
    DropdownMenuItem(
      child: Text(
        'Company Profiles',
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Company Profiles',
    ),
    DropdownMenuItem(
      child: Text(
        'Verification Requests',
        style: CustomTypography.BottomNavigationActiveLabel,
      ),
      value: 'Verification Requests',
    ),
  ];

  List<Widget> _verificationTabs = [
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
  ];

  // Filters
  List<roleModel.Roles> filterRoleList = [];
  TextEditingController _filterNameController = TextEditingController();
  TextEditingController _filterEmailController = TextEditingController();
  TextEditingController _filterPhoneController = TextEditingController();
  TextEditingController _filterCompanyController = TextEditingController();

  List<roleModel.Roles> filterRoles = [];
  List<String> filterNames = [];
  List<String> filterEmails = [];
  List<String> filterPhones = [];
  List<String> filterCompanies = [];
  List<String> filterStatus = [];
  roleModel.Roles? selectedRoleForFilter;
  String selectedStatus = '';

  TextEditingController _corporateSearchController = TextEditingController();
  TextEditingController _corporateEmployeeSearchController =
      TextEditingController();
  TextEditingController _nonCorporateSearchController = TextEditingController();
  TextEditingController _employeeSearchController = TextEditingController();
  Timer? companyDeBouncer;
  Timer? corporateEmployeeDeBouncer;
  Timer? nonCorporateDeBouncer;
  Timer? employeeDeBouncer;

  void companyDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (companyDeBouncer != null) {
      companyDeBouncer!.cancel();
    }
    companyDeBouncer = Timer(duration, callback);
  }

  void companySearchClient(String query) async => companyDebounce(() async {
        if (!mounted) return;
        // add filters for name, email, mobile as search text separated by comma, company name as company type filter and role as role filter
        // company name as company type filter and role as role filter
        List<String> searchItems = [];

        // Add filter names, emails, and phones to the search items
        searchItems.addAll(filterNames);
        searchItems.addAll(filterEmails);
        searchItems.addAll(filterPhones);

        // Combine all search items with the query
        if (query.isNotEmpty) {
          searchItems.add(query);
        }

        String searchText = searchItems.join(",");

        // Combine company type filters
        String companyTypeFilter = filterCompanies.join(",");

        // Combine role filters
        String roleFilter = filterRoles.map((e) => e.id ?? "").join(",");

        print(
            'Search Text: $searchText, Company Type Filter: $companyTypeFilter, Role Filter: $roleFilter');

        // Call the common function to fetch data
        await Provider.of<CompanyProvider>(context, listen: false)
            .getAllCompanies(
                context, searchText, companyTypeFilter, roleFilter, true);
      });

  void corporateEmployeeDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (corporateEmployeeDeBouncer != null) {
      corporateEmployeeDeBouncer!.cancel();
    }
    corporateEmployeeDeBouncer = Timer(duration, callback);
  }

  void corporateEmployeeSearchClient(String query) async =>
      corporateEmployeeDebounce(() async {
        if (!mounted) return;
        // add filters for name, email, mobile as search text separated by comma, company name as company type filter and role as role filter
        // company name as company type filter and role as role filter
        List<String> searchItems = [];

        // Add filter names, emails, and phones to the search items
        searchItems.addAll(filterNames);
        searchItems.addAll(filterEmails);
        searchItems.addAll(filterPhones);

        // Combine all search items with the query
        if (query.isNotEmpty) {
          searchItems.add(query);
        }

        String searchText = searchItems.join(",");

        // Combine company type filters
        String companyTypeFilter = filterCompanies.join(",");

        // Combine role filters
        String roleFilter = filterRoles.map((e) => e.id ?? "").join(",");

        print(
            'Search Text: $searchText, Company Type Filter: $companyTypeFilter, Role Filter: $roleFilter');

        // Call the common function to fetch data
        await Provider.of<CorporateProvider>(context, listen: false)
            .getCorporateUserList(context,
                searchText: searchText, roleFilter: roleFilter, isSearch: true, companyId: selectedCorporateId);
      });

  void nonCorporateDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (nonCorporateDeBouncer != null) {
      nonCorporateDeBouncer!.cancel();
    }
    nonCorporateDeBouncer = Timer(duration, callback);
  }

  void nonCorporateSearchClient(String query, {bool? status}) async =>
      nonCorporateDebounce(() async {
        if (!mounted) return;
        // add filters for name, email, mobile as search text separated by comma, company name as company type filter and role as role filter
        // company name as company type filter and role as role filter
        List<String> searchItems = [];

        // Add filter names, emails, and phones to the search items
        searchItems.addAll(filterNames);
        searchItems.addAll(filterEmails);
        searchItems.addAll(filterPhones);

        // Combine all search items with the query
        if (query.isNotEmpty) {
          searchItems.add(query);
        }

        String searchText = searchItems.join(",");

        // Combine company type filters
        String companyTypeFilter = filterCompanies.join(",");

        // Combine role filters
        String roleFilter = filterRoles.map((e) => e.id ?? "").join(",");

        print(
            'Search Text: $searchText, Company Type Filter: $companyTypeFilter, Role Filter: $roleFilter');

        // If no filters and search is empty call api with isSearch false
        bool isSearch = searchText.isNotEmpty ||
            filterCompanies.isNotEmpty ||
            filterRoles.isNotEmpty || status != null;

        // Call the common function to fetch data
        await Provider.of<NonCorporateProvider>(context, listen: false)
            .getNonCorporateUserList(context,
                searchText: searchText,
                roleFilter: roleFilter,
                isSearch: isSearch, status: status);
      });

  void employeeDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (employeeDeBouncer != null) {
      employeeDeBouncer!.cancel();
    }
    employeeDeBouncer = Timer(duration, callback);
  }

  void employeeSearchClient(String query, {bool status = false}) async =>
      employeeDebounce(() async {
        if (!mounted) return;
        // add filters for name, email, mobile as search text separated by comma, company name as company type filter and role as role filter
        // company name as company type filter and role as role filter
        List<String> searchItems = [];

        // Add filter names, emails, and phones to the search items
        searchItems.addAll(filterNames);
        searchItems.addAll(filterEmails);
        searchItems.addAll(filterPhones);

        // Combine all search items with the query
        if (query.isNotEmpty) {
          searchItems.add(query);
        }

        String searchText = searchItems.join(",");

        // Combine company type filters
        String companyTypeFilter = filterCompanies.join(",");

        // Combine role filters
        String roleFilter = filterRoles.map((e) => e.id ?? "").join(",");

        print(
            'Search Text: $searchText, Company Type Filter: $companyTypeFilter, Role Filter: $roleFilter');

        // If no filters and search is empty call api with isSearch false
        /*bool isSearch = searchText.isNotEmpty ||
            filterCompanies.isNotEmpty ||
            filterRoles.isNotEmpty;*/

        bool isSearch = true;
        // Call the common function to fetch data
        await Provider.of<EmployeeProvider>(context, listen: false)
            .getAllEmployees(context,
                searchText: searchText,
                roleFilter: roleFilter,
                isSearch: isSearch,
                status: status);
      });

  addFilter(String filter, String type) {
    removeAllFilters();
    setState(() {
      if (type == 'role') {
        filterRoles.add(roleModel.Roles(name: filter));
      } else if (type == 'name') {
        filterNames.add(filter);
      } else if (type == 'email') {
        filterEmails.add(filter);
      } else if (type == 'phone') {
        filterPhones.add(filter);
      } else if (type == 'company') {
        filterCompanies.add(filter);
      } else if (type == 'status') {
        filterStatus.add(filter);
      }
    });
  }

  removeFilter(String filter, String type) {
    setState(() {
      if (type == 'role') {
        filterRoles.removeWhere((element) => element.name == filter);
      } else if (type == 'name') {
        filterNames.remove(filter);
      } else if (type == 'email') {
        filterEmails.remove(filter);
      } else if (type == 'phone') {
        filterPhones.remove(filter);
      } else if (type == 'company') {
        filterCompanies.remove(filter);
      } else if (type == 'status') {
        filterStatus.remove(filter);
      }
    });
  }

  removeAllFilters() {
    setState(() {
      filterRoles.clear();
      filterNames.clear();
      filterEmails.clear();
      filterPhones.clear();
      filterCompanies.clear();
      filterStatus.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  Future<void> _initializeTabs() async {
    setState(() {
      showMainLoading = true;
    });

    await _setTabs();
    print('Tabs count: $visibleTabCount');

    _configureMainTabController();
    _configureSubTabControllers();

    if (widget.initialIndex != null) {
      _tabController?.animateTo(widget.initialIndex);
    }
    if (widget.initialIndex == 0 && widget.initialScreen == Screens.verificationList) {
      _selectedScreen = Screens.verificationList;
      clearFilters();
      _tabVerificationController?.animateTo(widget.subIndex ?? 0);
    }

    _getData();

    setState(() {
      showMainLoading = false;
    });
  }

  Future<void> _setTabs() async {
    showCorporateList = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCL) ??
        false;
    showCorporateUserListDropdown = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCUM) ??
        false;
    showCorporateUserList = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCL) ??
        false;
    showCreateCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCC) ??
        false;
    showEditCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMEC) ??
        false;
    showViewCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMVC) ??
        false;
    showDeleteCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMDC) ??
        false;
    showEnableDisableCorporate =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CAMED) ??
            false;
    showCorporateVerificationTab =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.CAMLL) ??
            false;
    showUserVerificationTab = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMUL) ??
        false;

    showCorporateProfile = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CAMCUL) ??
        false;

    showEnableDisableUser = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CUMED) ?? false;
    showDeleteUser = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CUMDU) ??
        false;
    showEditUser = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CUMEU) ??
        false;
    showConnectionListUser = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CUMCL) ??
        false;
    showCreateUser = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.CUMCU) ??
        false;
    showEnableDisableNonCorporate =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.NCMED) ??
            false;
    showDeleteNonCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.NCMDU) ??
        false;
    showEditNonCorporate = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.NCMEU) ??
        false;
    showNonCorporateConnectionList =
        await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.NCMCL) ??
            false;
    showEnableDisableEmployee = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPED) ??
        false;
    showDeleteEmployee = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPDU) ?? false;
    showEditEmployee = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPEU) ??
        false;
    showConnectionListEmployee = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPCL) ??
        false;
    showNonCorporateList = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.NCMUL) ??
        false;
    showEmployeeList = await SharedPreferenceService.getClaimForSubfeature(
        SharedPreferenceService.EMPUL) ?? false;



    showCorporateManagementTab = showCorporateList || showCorporateUserListDropdown || showCorporateVerificationTab || showCorporateProfile;
    showNonCorporateManagementTab = showNonCorporateList;
    showEmployeeManagementTab = showEmployeeList;
    if (!showCorporateManagementTab && !showNonCorporateManagementTab && !showEmployeeManagementTab) {
      setState(() {
        _selectedScreen = Screens.defaultScreen;
      });
    }

    visibleTabCount = [
      showCorporateManagementTab,
      showNonCorporateManagementTab,
      showEmployeeManagementTab,
    ].where((tab) => tab).length;

    _tabController = TabController(length: visibleTabCount, vsync: this);
    print('Tab Count: $visibleTabCount');
    _removeUnusedDropdownItems();
    _adjustVerificationTabs();
  }

  void _removeUnusedDropdownItems() {
    if (!showCorporateList) {
      corporateDropdownItems.removeWhere((element) => element.value == 'Companies');
    }
    if (!showCorporateUserListDropdown) {
      corporateDropdownItems.removeWhere((element) => element.value == 'Users');
    }
    if (!showCorporateVerificationTab && !showUserVerificationTab) {
      corporateDropdownItems.removeWhere((element) => element.value == 'Verification Requests');
    }
    if (!showCorporateProfile) {
      corporateDropdownItems.removeWhere((element) => element.value == 'Company Profiles');
    }
  }

  void _adjustVerificationTabs() {
    if (!showCorporateVerificationTab && showUserVerificationTab) {
      _tabVerificationController = TabController(length: 1, vsync: this);
      _verificationTabs.removeAt(0);
    } else if (showCorporateVerificationTab && !showUserVerificationTab) {
      _tabVerificationController = TabController(length: 1, vsync: this);
      _verificationTabs.removeAt(1);
    } else {
      _tabVerificationController = TabController(length: 2, vsync: this);
    }
  }

  void _configureMainTabController() {
    print('Controller size: ${_tabController?.length}');
    _tabController?.addListener(() {
      setState(() {
        _selectedScreen = _getScreenForCurrentTab(_tabController?.index);
        clearFilters();
      });
      print('Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
  }

  Screens _getScreenForCurrentTab(int? tabIndex) {
    if (tabIndex == null) return Screens.defaultScreen;

    int visibleTabIndex = 0;

    if (showCorporateManagementTab) {
      if (tabIndex == visibleTabIndex) {
        return _getCorporateManagementScreen();
      }
      visibleTabIndex++;
    }

    if (showNonCorporateManagementTab) {
      if (tabIndex == visibleTabIndex) {
        return Screens.nonCorporateList;
      }
      visibleTabIndex++;
    }

    if (showEmployeeManagementTab) {
      if (tabIndex == visibleTabIndex) {
        return Screens.employeeList;
      }
    }

    return Screens.defaultScreen;
  }

  Screens _getCorporateManagementScreen() {
    if (showCorporateList) {
      return Screens.corporateList;
    } else if (showCorporateUserListDropdown) {
      return Screens.corporateEmployeeList;
    } else if (showCorporateVerificationTab) {
      return Screens.verificationList;
    } else {
      return Screens.corporateProfile;
    }
  }


  void _configureSubTabControllers() {
    _tabNonCorporateController = TabController(length: 2, vsync: this);
    _tabNonCorporateController?.addListener(() {
      final provider = Provider.of<NonCorporateProvider>(context, listen: false);
      provider.nextPageToken = null;
      provider.nextPageExists = true;
      provider.getNonCorporateUserList(context, status: _tabNonCorporateController?.index == 1);
    });

    _tabEmployeeController = TabController(length: 2, vsync: this);
    _tabEmployeeController?.addListener(() {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      provider.nextPageToken = null;
      provider.nextPageExists = true;
      provider.getAllEmployees(context, status: _tabEmployeeController?.index == 1);
      employeeSearchClient(_employeeSearchController.text, status: _tabEmployeeController?.index == 1);
    });
  }


  Future<void> _getData() async {
     Provider.of<CorporateProvider>(context, listen: false)
        .getCorporateUserList(context);
    Provider.of<NonCorporateProvider>(context, listen: false)
        .getNonCorporateUserList(context);
    Provider.of<CompanyProvider>(context, listen: false)
        .getAllCompanies(context, "", "", "");
    Provider.of<CompanyProvider>(context, listen: false)
        .getCorporateType(context);
    Provider.of<VerificationProvider>(context, listen: false)
        .getAllCorporateRequests(context);
    Provider.of<VerificationProvider>(context, listen: false)
        .getAllUserRequests(context);
    Provider.of<EmployeeProvider>(context, listen: false)
        .getAllEmployees(context, searchText: "", roleFilter: "");
    filterRoleList = allRoles =
        await Provider.of<RoleProvider>(context, listen: false)
            .getAllRoles(context);
    selectedEmployeeRoles =
        await Provider.of<EmployeeProvider>(context, listen: false)
            .getRoles(context);
    filterRoleList = allRoles =
        await Provider.of<RoleProvider>(context, listen: false)
            .getAllRoles(context);
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
        floatingActionButton: /*_selectedScreen != Screens.corporateEdit &&
                _selectedScreen != Screens.corporateAdd &&
                _selectedScreen != Screens.corporateEmployeeAdd &&
                _selectedScreen != Screens.employeeAdd &&
                _selectedScreen != Screens.nonCorporateList &&
                _selectedScreen != Screens.verificationList &&
                _selectedScreen != Screens.corporateEmployeeEdit &&
                _selectedScreen != Screens.nonCorporateEdit &&
                (_selectedScreen == Screens.corporateList &&
                    showCreateCorporate) &&
            (_selectedScreen == Screens.corporateEmployeeList &&
                showCreateUser) &&
            (_selectedScreen == Screens.employeeList &&
                showCreateEmployee)*/
          (_selectedScreen == Screens.corporateList && showCreateCorporate) ||
              (_selectedScreen == Screens.corporateEmployeeList && showCreateUser) ||
              (_selectedScreen == Screens.employeeList&&showCreateEmployee)
            ? FloatingActionButton(
                onPressed: () async {
                  if (_selectedScreen == Screens.corporateList) {
                    print("object");
                    selectedCorporateTypeRole = [
                      companyType.Roles(
                        name: "Admin",
                        role: "admin",
                      )
                    ];
                    setState(() {
                      _selectedScreen = Screens.corporateAdd;
                      clearFilters();
                    });
                  } else if (_selectedScreen == Screens.corporateEmployeeEdit) {
                    setState(() {
                      _selectedScreen = Screens.corporateEmployeeEdit;
                      clearFilters();
                    });
                  } else if (_selectedScreen == Screens.corporateEmployeeList) {
                    filterRoleList = await Provider.of<CorporateProvider>(context, listen: false)
                        .getRolesWithCompanyId(context, selectedCorporateId??"");
                    setState(() {
                      _selectedScreen = Screens.corporateEmployeeAdd;
                      clearFilters();
                    });
                  } else if (_selectedScreen == Screens.employeeList) {
                    setState(() {
                      _selectedScreen = Screens.employeeAdd;
                      clearFilters();
                    });
                  }
                },
                child: Icon(Icons.add),
              )
            : SizedBox(),
        body: PopScope(
          canPop: (_selectedScreen == Screens.corporateList && !showCheckbox) || _selectedScreen == Screens.defaultScreen,
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
                clearFilters();
              });
            } else if (_selectedScreen == Screens.corporateEdit) {
              setState(() {
                _selectedScreen = Screens.corporateList;
                clearFilters();
              });
            } else if (_selectedScreen == Screens.corporateEmployeeList) {
              setState(() {
                if (showCorporateList) {
                  _selectedScreen = Screens.corporateList;
                } else {
                  Navigator.pop(context);
                }
                clearFilters();
              });
            } else if (_selectedScreen == Screens.corporateEmployeeAdd) {
              setState(() {
                _selectedScreen = Screens.corporateEmployeeList;
                clearFilters();
              });
            } else if (_selectedScreen == Screens.corporateEmployeeEdit) {
              setState(() {
                _selectedScreen = Screens.corporateEmployeeList;
                clearFilters();
              });
            } else if (_selectedScreen == Screens.nonCorporateList) {
              setState(() {
                if (showCorporateList) {
                  _selectedScreen = Screens.corporateList;
                } else {
                  if (showCorporateUserListDropdown) {
                    _selectedScreen = Screens.corporateEmployeeList;
                  } else {
                    _selectedScreen = Screens.verificationList;
                  }
                }
                clearFilters();
              });
            } else if (_selectedScreen == Screens.employeeAdd) {
              setState(() {
                _selectedScreen = Screens.employeeList;
                clearFilters();
              });
            } else if (_selectedScreen == Screens.employeeEdit) {
              setState(() {
                _selectedScreen = Screens.employeeList;
                clearFilters();
              });
            } else if (_selectedScreen == Screens.verificationList) {
              setState(() {
                if(showCorporateVerificationTab && showUserVerificationTab) {
                  if (_tabVerificationController?.index == 0) {
                    if (showCorporateList) {
                      _selectedScreen = Screens.corporateList;
                    } else {
                      if (showCorporateUserListDropdown) {
                        _selectedScreen = Screens.corporateEmployeeList;
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  } else if (_tabVerificationController?.index == 1) {
                    if (showCorporateList) {
                      _selectedScreen = Screens.corporateList;
                    } else {
                      if (showCorporateUserListDropdown) {
                        _selectedScreen = Screens.corporateEmployeeList;
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  }
                } else if(showCorporateVerificationTab) {
                  if (showCorporateList) {
                    _selectedScreen = Screens.corporateList;
                  } else {
                    if (showCorporateUserListDropdown) {
                      _selectedScreen = Screens.corporateEmployeeList;
                    } else {
                      Navigator.pop(context);
                    }
                  }
                } else if(showUserVerificationTab) {
                  if (showCorporateList) {
                    _selectedScreen = Screens.corporateList;
                  } else {
                    if (showCorporateUserListDropdown) {
                      _selectedScreen = Screens.corporateEmployeeList;
                    } else {
                      Navigator.pop(context);
                    }
                  }
                }
                clearFilters();
              });
            } else if (_selectedScreen == Screens.nonCorporateEdit) {
              setState(() {
                _selectedScreen = Screens.nonCorporateList;
                clearFilters();
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
                    child: showMainLoading? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(),),) :Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                      child: _selectedScreen == Screens.defaultScreen?_defaultScreen():Column(
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
                          _selectedScreen == Screens.defaultScreen
                              ? _defaultScreen()
                              : SizedBox(),
                          TabBar(
                            isScrollable: true,
                            controller: _tabController,
                            labelStyle:
                                CustomTypography.BottomNavigationActiveLabel,
                            tabs: [
                              if (showCorporateManagementTab)
                              Tab(
                                child: DropdownButton(
                                  underline: SizedBox(),
                                  value: 'Corporate',
                                  items: corporateDropdownItems,
                                  onChanged: (value) {
                                    // Handle dropdown item selection
                                    if (value == 'Corporate') {
                                      setState(() {
                                        _selectedScreen = Screens.corporateList;
                                        clearFilters();
                                      });
                                    } else if (value == 'Companies') {
                                      setState(() {
                                        _selectedScreen = Screens.corporateList;
                                        clearFilters();
                                      });
                                    } else if (value == 'Users') {
                                      setState(() {
                                        selectedCorporateId = "";
                                        _selectedScreen =
                                            Screens.corporateEmployeeList;
                                        clearFilters();
                                      });
                                    } else if (value == 'Company Profiles') {
                                      // Handle company profiles option
                                      setState(() {
                                        _selectedScreen = Screens.corporateProfile;
                                        clearFilters();
                                      });
                                    } else if (value ==
                                        'Verification Requests') {
                                      // Handle verification requests option
                                      setState(() {
                                        _selectedScreen =
                                            Screens.verificationList;
                                        clearFilters();
                                      });
                                    } else if (value == 'AnotherOption') {
                                      // Handle another option
                                    }
                                    _tabController?.animateTo(0);
                                  },
                                ),
                              ),
                              if (showNonCorporateManagementTab)
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(showCorporateManagementTab ? 1 : 0);
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
                              if (showEmployeeManagementTab)
                              InkWell(
                                onTap: () {
                                  int destinationTabIndex = showCorporateManagementTab
                                      ? showNonCorporateManagementTab
                                      ? 2 // If both Corporate and Non-Corporate tabs are visible
                                      : 1 // If only Corporate tab is visible
                                      : 0; // If neither Corporate nor Non-Corporate tabs are visible
                                  _tabController?.animateTo(destinationTabIndex);
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
                                if (showCorporateManagementTab) _getCorporateManagementUI(),
                                // Non Corporate Management
                                if (showNonCorporateManagementTab) _getNonCorporateManagementUI(),
                                // Employee Management
                                if (showEmployeeManagementTab) _getEmployeeManagementUI(),
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
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
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
                  SizedBox(height: CustomSpacing.four),
                  // Toolbar with chips for filter, a text button for clear filter and show number of selections, vertical divider and deselect text and delete button

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Column(
                      children: [
                        // Filter Chips
                        Wrap(
                          direction: Axis.horizontal,
                          alignment: WrapAlignment.start,
                          runAlignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          verticalDirection: VerticalDirection.down,
                          spacing: 4,
                          children: [
                            // Dynamic chips for all filters such that we can do add remove and remove all operations
                            for (var role in filterRoles)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(role.name ?? ""),
                                onDeleted: () {
                                  removeFilter(role.name ?? "", 'role');
                                },
                              ),
                            for (var name in filterNames)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(name),
                                onDeleted: () {
                                  removeFilter(name, 'name');
                                },
                              ),
                            for (var email in filterEmails)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(email),
                                onDeleted: () {
                                  removeFilter(email, 'email');
                                },
                              ),
                            for (var phone in filterPhones)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(phone),
                                onDeleted: () {
                                  removeFilter(phone, 'phone');
                                },
                              ),
                            for (var company in filterCompanies)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(company),
                                onDeleted: () {
                                  removeFilter(company, 'company');
                                },
                              ),
                            for (var status in filterStatus)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                    horizontal: CustomSpacing.two),
                                label: Text(status),
                                onDeleted: () {
                                  removeFilter(status, 'status');
                                },
                              ),
                          ],
                        ),
                        // Clear Filter Button
                        (filterCompanies.isEmpty &&
                                filterEmails.isEmpty &&
                                filterNames.isEmpty &&
                                filterPhones.isEmpty &&
                                filterRoles.isEmpty &&
                                filterStatus.isEmpty)
                            ? SizedBox()
                            : TextButton(
                                onPressed: () {
                                  // Handle clear filter
                                  removeAllFilters();
                                },
                                child: Text('Clear Filter'),
                              ),
                        Divider(
                          thickness: 1,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                        Builder(builder: (context) {
                          return Column(
                            children: [
                              // name, phone, email, company, role dropdown, status,
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Form(
                                    child: Column(children: [
                                  // Name
                                  TextFormField(
                                    controller: _filterNameController,
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
                                    controller: _filterEmailController,
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
                                  TextFormField(
                                    controller: _filterPhoneController,
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
                                  ),
                                  SizedBox(height: CustomSpacing.two),
                                  // Company
                                  TextFormField(
                                    controller: _filterCompanyController,
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
                                  (_selectedScreen == Screens.corporateList)
                                      ? SizedBox()
                                      : DropdownButtonFormField<
                                          roleModel.Roles>(
                                          decoration: InputDecoration(
                                            labelText: 'Role',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: filterRoleList
                                              .map((roleModel.Roles value) {
                                            return DropdownMenuItem<
                                                roleModel.Roles>(
                                              value: value,
                                              child: Text(value.name ?? ''),
                                            );
                                          }).toList(),
                                          onChanged: (roleModel.Roles? value) {
                                            // Handle role change
                                            setState(() {
                                              selectedRoleForFilter = value;
                                            });
                                          },
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
                                    items: ['Active', 'Inactive']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      // Handle status change
                                      setState(() {
                                        selectedStatus = value!;
                                      });
                                    },
                                  ),
                                  SizedBox(height: CustomSpacing.two),
                                  // Cancel and Submit Buttons
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CustomButton(
                                        onPressed: () {
                                          // Handle submit button, first add to the filter list and then according to the screen we call the respective apis
                                          if (_filterNameController
                                              .text.isNotEmpty) {
                                            addFilter(
                                                _filterNameController.text,
                                                'name');
                                            _filterNameController.clear();
                                          }
                                          if (_filterEmailController
                                              .text.isNotEmpty) {
                                            addFilter(
                                                _filterEmailController.text,
                                                'email');
                                            _filterEmailController.clear();
                                          }
                                          if (_filterPhoneController
                                              .text.isNotEmpty) {
                                            addFilter(
                                                _filterPhoneController.text,
                                                'phone');
                                            _filterPhoneController.clear();
                                          }
                                          if (_filterCompanyController
                                              .text.isNotEmpty) {
                                            addFilter(
                                                _filterCompanyController.text,
                                                'company');
                                            _filterCompanyController.clear();
                                          }
                                          if (selectedRoleForFilter != null) {
                                            addFilter(
                                                selectedRoleForFilter?.name ??
                                                    '',
                                                'role');
                                            selectedRoleForFilter = null;
                                          }
                                          if (selectedStatus.isNotEmpty) {
                                            addFilter(selectedStatus, 'status');
                                            selectedStatus = '';
                                          }
                                          // call api and close the drawer
                                          if (_selectedScreen ==
                                              Screens.corporateList) {
                                            companySearchClient(
                                                _corporateSearchController
                                                    .text);
                                            Scaffold.of(context)
                                                .closeEndDrawer();
                                          } else if (_selectedScreen ==
                                              Screens.corporateEmployeeList) {
                                            corporateEmployeeSearchClient(
                                                _corporateEmployeeSearchController
                                                    .text);
                                            Scaffold.of(context)
                                                .closeEndDrawer();
                                          } else if (_selectedScreen ==
                                              Screens.nonCorporateList) {
                                            nonCorporateSearchClient(
                                                _nonCorporateSearchController
                                                    .text);
                                            Scaffold.of(context)
                                                .closeEndDrawer();
                                          } else if (_selectedScreen ==
                                              Screens.employeeList) {
                                            employeeSearchClient(
                                                _employeeSearchController.text);
                                            Scaffold.of(context)
                                                .closeEndDrawer();
                                          }
                                        },
                                        type: ButtonType.filled,
                                        child: Text(
                                          'Add Filter',
                                          style: CustomTypography.ButtonLarge,
                                        ),
                                      ),
                                      SizedBox(width: CustomSpacing.two),
                                      OutlinedButton(
                                        onPressed: () {
                                          // Handle submit button
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
                                          style: CustomTypography.ButtonLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ])),
                              )
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  _defaultScreen() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Center(
            child: Column(
              children: [
                Expanded(
                  child: Text('This feature is launching soon!',
                      style: CustomTypography.H4),
                ),
                SizedBox(
                  height: CustomSpacing.two,
                ),
                Text('We have something coming that is going to blow you away. Check back often for the launch.', style: CustomTypography.Body1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _corporateManagement() {
    return RefreshIndicator(
      onRefresh: () async {
        companySearchClient(_corporateSearchController.text);
      },
      child: Builder(builder: (context) {
        return Column(
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
                    controller: _corporateSearchController,
                    onChanged: companySearchClient,
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
                ? Consumer<CompanyProvider>(
                    builder: (_, companyProvider, child) {
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
                              itemCount: companyProvider.companies.length +
                                  (companyProvider.companyListNextPageExists
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == companyProvider.companies.length) {
                                  // Reached the end of the current list, load more data
                                  companyProvider.getAllCompanies(context, "",
                                      "", ""); // Adjust parameters as needed
                                  return SizedBox(
                                    height:
                                        50, // Placeholder for loading indicator
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else {
                                  return _companyListItem(
                                      index, companyProvider);
                                }
                              },
                            );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  _companyListItem(int index, CompanyProvider companyProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(top: 0.0, bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onLongPress: !showDeleteCorporate
                ? null
                : () {
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
                      !showDeleteCorporate
                          ? SizedBox()
                          : showCheckbox
                              ? Checkbox(
                                  value:
                                      companyProvider.companies[index].isSelected!,
                                  onChanged: (value) {
                                    // Handle checkbox value change
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        companyProvider
                                            .companies[index].isSelected = value;
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
                      !showEnableDisableCorporate
                          ? SizedBox()
                          : companyProvider.isStatusLoading &&
                                  selectedCompanyListIndex == index
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8.0, right: 8.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : Switch(
                                  value:
                                      companyProvider.companies[index].isEnabled ??
                                          false,
                                  onChanged: (value) {
                                    // Handle switch value change
                                    selectedCompanyListIndex = index;
                                    companyProvider
                                        .changeCompanyStatus(
                                            context,
                                            companyProvider.companies[index].id ??
                                                '',
                                            value)
                                        .then((value) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          companyProvider
                                              .companies[index].isEnabled = value;
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
                        showCorporateUserList?Consumer<CorporateProvider>(
                          builder: (context, corporateProvider, child) {
                            return TextButton.icon(
                              onPressed: () async {
                                // Handle view employees
                                print('View Employees');
                                selectedCorporateId =
                                    companyProvider.companies[index].id ?? '';

                                await corporateProvider
                                    .getCorporateUserList(context,
                                        companyId:
                                            companyProvider.companies[index].id ?? '', isSearch: true);

                                selectedCorporateId =
                                    companyProvider.companies[index].id ?? '';
                                setState(() {
                                  _corporateEmployeeSearchController.text = "";
                                  _selectedScreen = Screens.corporateEmployeeList;
                                  clearFilters();
                                });
                              },
                              icon: Icon(Icons.people),
                              label: Text('View Employees',
                                  style: CustomTypography.Caption.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black)),
                            );
                          }
                        ):SizedBox(),
                        Spacer(),
                        showEditCorporate
                            ? IconButton(
                                icon: Icon(Icons.edit),
                                color: AppColors.primaryMain,
                                onPressed: () async {
                                  /// Handle edit company
                                  await companyProvider.viewCompany(context,
                                      companyProvider.companies[index].id ?? '');
                                  log(companyProvider.company.toJson().toString());
                                  // Prefill values
                                  companyImageUrl =
                                      companyProvider.company.companyImageUrl;
                                  selectedCompanyType = CorporateType(
                                    name: companyProvider.company.companyTypeName,
                                    type: companyProvider.company.companyType,
                                  );
                                  _enableDomainCheck =
                                      companyProvider.company.enableDomainCheck ??
                                          false;
                                  selectedCorporateTypeRole = [
                                    companyType.Roles(
                                      name: "Admin",
                                      role: "admin",
                                    )
                                  ];
                                  _domainListController.text = companyProvider
                                          .company.domainList
                                          ?.join(",") ??
                                      '';
                                  _companyLegalNameController.text =
                                      companyProvider.company.name ?? '';
                                  if (companyProvider.company.displayName != null) {
                                    _companyDisplayNameController.text =
                                        companyProvider
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
                                      companyProvider.company.admins?.displayName ??
                                          '';
                                  _adminEmailController.text =
                                      companyProvider.company.admins?.email ?? '';
                                  _selectedCountryCode = _adminMobileController
                                          .text =
                                      companyProvider.company.admins?.mobile ?? '';
                                  _enableDomainCheck =
                                      companyProvider.company.enableDomainCheck ??
                                          false;
                                  // Set screen to edit

                                  setState(() {
                                    _selectedScreen = Screens.corporateEdit;
                                    clearFilters();
                                  });
                                },
                              )
                            : SizedBox(),
                        !showDeleteCorporate
                            ? SizedBox()
                            : companyProvider.isDeleteLoading &&
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
                                                          .addPostFrameCallback(
                                                              (_) {
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
    );
  }

  _corporateEmployeeManagement() {
    return RefreshIndicator(
      onRefresh: () async {
        corporateEmployeeSearchClient(_corporateEmployeeSearchController.text);
      },
      child: Builder(builder: (context) {
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
                    controller: _corporateEmployeeSearchController,
                    onChanged: corporateEmployeeSearchClient,
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

                    Scaffold.of(context).openEndDrawer();
                  },
                  child: Icon(
                    Icons.filter_list,
                    size: 30,
                  ),
                ),
              ],
            ),
            // select all checkbox
            showCheckbox
                ? Consumer<CorporateProvider>(
                    builder: (_, corporateProvider, child) {
                    return Row(
                      children: [
                        Checkbox(
                          value: corporateProvider.employeeList
                              ?.every((element) => element.isSelected!),
                          onChanged: (value) {
                            // Handle select all checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              corporateProvider.employeeList
                                  ?.forEach((element) {
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
                                  title: Text('Delete Employees',
                                      style: CustomTypography.H7),
                                  content: Text(
                                      'Are you sure you want to delete selected employees?',
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
                                        corporateProvider
                                            .deleteCompany(
                                                context,
                                                corporateProvider.employeeList!
                                                    .where((element) =>
                                                        element.isSelected ==
                                                        true)
                                                    .map((e) => e.userId ?? '')
                                                    .toList())
                                            .then((value) {
                                          if (value) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              setState(() {
                                                corporateProvider.employeeList
                                                    ?.removeWhere((element) =>
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
            SizedBox(
              height: CustomSpacing.four,
            ),
            Expanded(
              child: Consumer<CorporateProvider>(
                  builder: (context, corporateProvider, child) {
                return corporateProvider.isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : (corporateProvider.employeeList ?? []).isEmpty
                        ? Center(
                            child: Text('No employees',
                                style: CustomTypography.Body1),
                          )
                        : ListView.builder(
                            itemCount:
                                (corporateProvider.employeeList ?? []).length +
                                    (corporateProvider.nextPageExists ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index ==
                                  (corporateProvider.employeeList ?? [])
                                      .length) {
                                // Reached the end of the current list, load more data
                                corporateProvider.getCorporateUserList(context,
                                    companyId: selectedCorporateId);
                                return SizedBox(
                                  height:
                                      50, // Placeholder for loading indicator
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else {
                                return _corporateUserList(
                                    index, corporateProvider);
                              }
                            },
                          );
              }),
            ),
          ],
        );
      }),
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
                                print('Selected Company Type: $selectedCorporateTypeRole');
                                return Stack(
                                  children: [
                                    TextField(
                                      readOnly: true,
                                      enabled: false, // Disable user input
                                      controller: _textEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'Role(s)',
                                        //hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.arrow_drop_down), // Remove onPressed handler
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
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: Chip(
                                                  label: Text(value.name ?? ''),
                                                  deleteIcon: Icon(Icons.cancel), // Remove onDeleted handler
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
                              },
                            ),
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
                                                      "display_image_url":
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
                                                          clearFilters();
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
                                              clearFilters();
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
                                      /*hintText: _selectedRoles.isEmpty
                                          ? 'Select Roles'
                                          : "",*/
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
                                                    "action": "",
                                                    "userdata": {
                                                      "company_id":
                                                          companyProvider
                                                              .company.id,
                                                      "id": companyProvider
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
                                                      "display_image_url":
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
                                                          clearFilters();
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
                                              clearFilters();
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

  _viewCompany() {
    // Add Company
    return Consumer<CompanyProvider>(
      builder: (context, companyProvider, child) {
        return SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(top: 8),
            child: companyProvider.isLoading?Container(height: 20, width: 20, child: CircularProgressIndicator(),):Card(
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
                          Text('View corporate account',
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
                              Text('View the necessary information.',
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
                                  width: CustomSpacing.eight,
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
                              ]))
                        ],
                      ),
                    ),
                  ]),
            ),
          ),
        );
      }
    );
  }

  void clearFilters() {
    filterCompanies.clear();
    filterStatus.clear();
    filterRoles.clear();
    filterPhones.clear();
    filterEmails.clear();
    filterNames.clear();
  }

  _corporateUserList(int index, CorporateProvider corporateProvider) {
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
          selectedCompanyEmployeeListIndex = index;
          setState(() {
            corporateProvider.employeeList?[index].isSelected =
                corporateProvider.employeeList![index].isSelected;
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
                          value: corporateProvider
                              .employeeList?[index].isSelected!,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                corporateProvider
                                    .employeeList?[index].isSelected = value!;
                              });
                            });
                          },
                        )
                      : SizedBox(),
                  CircleAvatar(
                    child: corporateProvider
                                    .employeeList?[index].displayImageUrl !=
                                null &&
                            corporateProvider
                                    .employeeList?[index].displayImageUrl !=
                                ''
                        ? ClipOval(
                            child: Image.network(
                              corporateProvider
                                  .employeeList![index].displayImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            corporateProvider.employeeList?[index].name
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
                          (corporateProvider.employeeList?[index].name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (corporateProvider.employeeList?[index].name
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
                        Text(corporateProvider.employeeList?[index].email ?? "",
                            style: CustomTypography.Caption),
                        Text(
                            corporateProvider.employeeList?[index].phone
                                    ?.toString() ??
                                "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                 !showEnableDisableUser? SizedBox():corporateProvider.isStatusLoading &&
                          selectedCompanyEmployeeListIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Switch(
                          value:
                              corporateProvider.employeeList?[index].status ??
                                  false,
                          onChanged: (value) {
                            print(
                                corporateProvider.employeeList?[index].userId);
                            // Handle switch value change
                            selectedCompanyEmployeeListIndex = index;
                            corporateProvider
                                .changeCorporateEmployeeStatus(
                                    context,
                                    corporateProvider
                                            .employeeList?[index].userId ??
                                        '',
                                    value)
                                .then((value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  corporateProvider
                                      .employeeList?[index].status = value;
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
                      SingleChildScrollView(
                        child: Row(
                          children: [
                            CustomChip(
                                label: Text(corporateProvider
                                        .employeeList?[index].role?.name ??
                                    '')),
                          ],
                        ),
                      ),
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
                    !showConnectionListUser?const SizedBox():TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(
                                  userId: corporateProvider
                                          .employeeList?[index].userId ??
                                      '',
                                  userName: corporateProvider
                                          .employeeList?[index].name ??
                                      '',
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
                    !showEditUser?SizedBox():corporateProvider.isEditViewEmployeeLoading &&
                            selectedCompanyEmployeeListIndex == index
                        ? Center(
                            child: Container(
                                height: 20,
                                width: 20,
                                margin: EdgeInsets.only(right: 8),
                                child: CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: Icon(Icons.edit),
                            color: AppColors.primaryMain,
                            onPressed: () async {
                              selectedCompanyEmployeeListIndex = index;
                              String userId = corporateProvider
                                      .employeeList![index].userId ??
                                  '';
                              await corporateProvider.viewCorporateUserEmployee(
                                  context, userId);
                              log(corporateProvider.employees
                                  .toJson()
                                  .toString());
                              companyImageUrl =
                                  corporateProvider.employees.displayImageUrl ??
                                      '';
                              setState(() {
                                corporateUserId = corporateProvider
                                    .employeeList![index].userId;
                                _selectedScreen = Screens.corporateEmployeeEdit;
                                clearFilters();
                              });
                            },
                          ),
                    !showDeleteUser?SizedBox():corporateProvider.isDeleteLoading &&
                            selectedCompanyEmployeeListIndex == index
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
                              selectedCompanyEmployeeListIndex = index;
                              // Handle delete by showing dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  // delete company name
                                  return AlertDialog(
                                    title: Text('Delete Employee',
                                        style: CustomTypography.H6),
                                    content: Text(
                                        'Are you sure you want to delete '
                                        '${corporateProvider.employeeList?[index].name}?',
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
                                          corporateProvider.deleteCompany(
                                              context, [
                                            corporateProvider
                                                    .employeeList?[index]
                                                    .userId ??
                                                ''
                                          ]).then((value) {
                                            if (value) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                setState(() {
                                                  corporateProvider.employeeList
                                                      ?.removeAt(index);
                                                });
                                              });
                                              Provider.of<CorporateProvider>(
                                                      context,
                                                      listen: false)
                                                  .getCorporateUserList(
                                                      context);
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

  _createEmployee() {
    // Add Company
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.paperElavation25
              : AppColors.paperElavation25Light,
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
                                                "company_id":
                                                    selectedCorporateId,
                                                "is_pgsupport":
                                                    selectedCorporateId == ""
                                                        ? true
                                                        : false,
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
                                                    clearFilters();
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
                                                    clearFilters();
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

  _createCorporateUser() {
    // Add Company
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.paperElavation25
              : AppColors.paperElavation25Light,
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
                    Text('Create new corporate user account',
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
                    Consumer<CorporateProvider>(
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
                                  List<companyType.Roles> roles = [];

                                  if (employeeProvider.roles != null) {
                                    employeeProvider.roles!.forEach((role) {
                                      roles.add(companyType.Roles(
                                        isForIndividual: role.isForIndividual,
                                        isMultipleRoleEnabled: role.isMultipleRoleEnabled,
                                        isApplicableForTrial: role.isApplicableForTrial,
                                        name: role.name,
                                        role: role.role,
                                        isApplicableForInternal: role.isApplicableForInternal,
                                        status: role.status,
                                      ));
                                    });
                                  }
                                  return CorporateTypeRolesBottomSheet(
                                    selectedRoles: selectedCorporateTypeRole,
                                    addChip: _addCorporateChip,
                                    removeChip: _removeCorporateChip,
                                    removeAllChips: _removeAllCorporateChips,
                                    roles: roles,
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
                                      List<companyType.Roles> roles = [];

                                      if (employeeProvider.roles != null) {
                                        employeeProvider.roles!.forEach((role) {
                                          roles.add(companyType.Roles(
                                            isForIndividual: role.isForIndividual,
                                            isMultipleRoleEnabled: role.isMultipleRoleEnabled,
                                            isApplicableForTrial: role.isApplicableForTrial,
                                            name: role.name,
                                            role: role.role,
                                            isApplicableForInternal: role.isApplicableForInternal,
                                            status: role.status,
                                          ));
                                        });
                                      }
                                      return CorporateTypeRolesBottomSheet(
                                        selectedRoles:
                                            selectedCorporateTypeRole,
                                        addChip: _addCorporateChip,
                                        removeChip: _removeCorporateChip,
                                        removeAllChips:
                                            _removeAllCorporateChips,
                                        roles: roles,
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
                            Consumer<CorporateProvider>(
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
                                              Screens.corporateAdd) {
                                            print("ASDF");
                                            var body = {
                                              "user_id": employeeProvider
                                                  .employees.userId,
                                              "action": "create_user",
                                              "userdata": {
                                                "selectedCountryCode":
                                                    _selectedCountryCode,
                                                "name": _employeeNameController
                                                    .text,
                                                "email":
                                                    _employeeEmailController
                                                        .text,
                                                // "user_id":
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

                                            Provider.of<CorporateProvider>(
                                                    context,
                                                    listen: false)
                                                .createCorporateEmployee(
                                                    context, body)
                                                .then((value) {
                                              if (value) {
                                                // Handle success
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  setState(() {
                                                    _selectedScreen =
                                                        Screens.employeeList;
                                                    clearFilters();
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
                                                // "user_id": employeeProvider
                                                //     .employees.userId,
                                                "display_image_url":
                                                    employeeImageUrl,
                                                "name": _employeeNameController
                                                    .text,
                                                "roles":
                                                    selectedCorporateTypeRole
                                                        .map((role) => {
                                                              "role": role.role,
                                                              "name": role.name,
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
                                                "email":
                                                    _employeeEmailController
                                                        .text,
                                                "country_code":
                                                    _selectedCountryCode,
                                                "isIndividual": false
                                              }
                                            };

                                            Provider.of<CorporateProvider>(
                                                    context,
                                                    listen: false)
                                                .createCorporateEmployee(
                                                    context, body)
                                                .then((value) {
                                              if (value) {
                                                Provider.of<CorporateProvider>(
                                                        context,
                                                        listen: false)
                                                    .getCorporateUserList(
                                                        context);
                                                // Handle success
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  setState(() {
                                                    _selectedScreen =
                                                        Screens.employeeList;
                                                    clearFilters();
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

  Widget _editCorporateUser(BuildContext context, String employeeId) {
    CorporateProvider corporateProvider =
        Provider.of<CorporateProvider>(context, listen: false);
    return FutureBuilder<UsersCorporate>(
      future: corporateProvider.viewCorporateUserEmployee(context, employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading user data"));
        } else if (snapshot.hasData) {
          UsersCorporate currentUser = snapshot.data!;
          TextEditingController _employeeNameController =
              TextEditingController(text: currentUser.name);
          TextEditingController _employeeEmailController =
              TextEditingController(text: currentUser.email);
          TextEditingController _employeeMobileController =
              TextEditingController(text: currentUser.phone);
          TextEditingController _employeeCountryCodeController =
              TextEditingController(text: currentUser.countryCode);
          String employeeImageUrl = currentUser.displayImageUrl ?? '';
          print(currentUser.role?[0].name.toString());
          print(currentUser.countryCode.toString());
          if (currentUser.role != null && currentUser.role!.isNotEmpty) {
            selectedCorporateTypeRole = [
              companyType.Roles(
                isForIndividual: currentUser.role![0].isForIndividual,
                isMultipleRoleEnabled:
                    currentUser.role![0].isMultipleRoleEnabled,
                isApplicableForTrial: currentUser.role![0].isApplicableForTrial,
                name: currentUser.role![0].name ?? "",
                role: currentUser.role![0].role ?? "",
                isApplicableForInternal:
                    currentUser.role![0].isApplicableForInternal,
                status: currentUser.role![0].status,
              )
            ];
          }
          String? values = currentUser.role?[0].name.toString();

          return SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.paperElavation25
                    : AppColors.paperElavation25Light,
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
                          Text('Edit corporate user account',
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
                                  backgroundImage: AssetImage(
                                      'assets/images/loginImage.png'),
                                  radius: 40,
                                )
                              : CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(employeeImageUrl!),
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
                                style: CustomTypography
                                    .BottomNavigationActiveLabel,
                                textAlign: TextAlign.center,
                              ),
                              // Add button
                              Consumer<CorporateProvider>(
                                  builder: (_, corporateProvider, child) {
                                return corporateProvider
                                        .isEditViewEmployeeLoading
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
                                              Provider.of<EmployeeProvider>(
                                                      context,
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

                          Consumer<CorporateProvider>(
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
                                          selectedRoles:
                                              selectedCorporateTypeRole,
                                          addChip: _addCorporateChip,
                                          removeChip: _removeCorporateChip,
                                          removeAllChips:
                                              _removeAllCorporateChips,
                                          roles:
                                              selectedCompanyType?.roles ?? [],
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
                                              removeChip: _removeCorporateChip,
                                              removeAllChips:
                                                  _removeAllCorporateChips,
                                              roles:
                                                  selectedCompanyType?.roles ??
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
                                    margin: const EdgeInsets.only(right: 32.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: selectedCorporateTypeRole
                                            .map(
                                              (value) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Chip(
                                                    label: Text(
                                                        value.name ?? values!),
                                                    deleteIcon:
                                                        Icon(Icons.cancel),
                                                    onDeleted: () {
                                                      print(
                                                          'Removing chip: ${value.name}');
                                                      setState(() {
                                                        selectedCorporateTypeRole
                                                            ?.removeWhere(
                                                                (element) =>
                                                                    element
                                                                        .name ==
                                                                    value.name);
                                                        values = "";
                                                        selectedCorporateTypeRole ==
                                                            "";
                                                      });
                                                      print(values);
                                                    }),
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
                            readOnly: true,
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child: CountryListPicker(
                                      initialCountry: Countries.Australia,
                                      // Ensure this is correctly set or dynamically assigned
                                      border: InputBorder.none,
                                      flagSize: Size(35, 30),
                                      onChanged: (code) {
                                        // This is typically triggered when a new selection is made in the picker
                                        setState(() {
                                          _selectedCountryCode =
                                              code; // Maintaining a state variable for other uses
                                          _employeeCountryCodeController.text =
                                              code; // Update the controller
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
                                        // This may be triggered based on specific implementations of CountryListPicker
                                        print(
                                            'This is the country code: $country');
                                        setState(() {
                                          _selectedCountryCode =
                                              country.dialing_code;
                                          _employeeCountryCodeController.text =
                                              country.dialing_code;
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
                                  Consumer<CorporateProvider>(builder:
                                      (context, employeeProvider, child) {
                                    return Expanded(
                                      child: employeeProvider.isLoading
                                          ? Center(
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : CustomButton(
                                              type: ButtonType.filled,
                                              onPressed: () {
                                                if (!_createEmployeeFormKey
                                                    .currentState!
                                                    .validate()) {
                                                  return;
                                                }

                                                var body = {
                                                  "userdata": {
                                                    "user_id": corporateUserId,
                                                    "display_image_url":
                                                        employeeImageUrl,
                                                    "name":
                                                        _employeeNameController
                                                            .text,
                                                    "email":
                                                        _employeeEmailController
                                                            .text,
                                                    "phone":
                                                        _employeeMobileController
                                                            .text,
                                                    "roles":
                                                        selectedCorporateTypeRole
                                                            .map((role) => {
                                                                  "role":
                                                                      role.role,
                                                                  "name":
                                                                      role.name,
                                                                  "is_applicable_for_internal":
                                                                      role.isApplicableForInternal,
                                                                  "status": role
                                                                      .status
                                                                })
                                                            .toList(),
                                                    "displayName": "",
                                                    "country_code":
                                                        _selectedCountryCode,
                                                    "isIndividual": false
                                                  }
                                                };

                                                Provider.of<CorporateProvider>(
                                                        context,
                                                        listen: false)
                                                    .updateCorporateEmployee(
                                                        context, body)
                                                    .then((value) {
                                                  if (value) {
                                                    Provider.of<CorporateProvider>(
                                                            context,
                                                            listen: false)
                                                        .getCorporateUserList(
                                                            context);
                                                    // Handle success
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      setState(() {
                                                        _selectedScreen =
                                                            Screens
                                                                .employeeList;
                                                        clearFilters();
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
                                              },
                                              child: Text(
                                                'Submit',
                                                style: CustomTypography
                                                    .ButtonLarge,
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
                                          _selectedScreen =
                                              Screens.employeeList;
                                          clearFilters();
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
                          ),
                        ]))
                  ]),
            ),
          );
        } else {
          return Center(child: Text("No user data available"));
        }
      },
    );
  }

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

  _getCorporateManagementUI() {
    print(Screens.corporateAdd);
    if (_selectedScreen == Screens.corporateList) {
      return _corporateManagement();
    } else if (_selectedScreen == Screens.corporateAdd) {
      return _createCompany();
    } else if (_selectedScreen == Screens.corporateEdit) {
      return _editCompany();
    } else if (_selectedScreen == Screens.corporateEmployeeList) {
      return _corporateEmployeeManagement();
    } else if (_selectedScreen == Screens.corporateEmployeeAdd) {
      return _createCorporateUser();
    } else if (_selectedScreen == Screens.corporateEmployeeEdit) {
      return _editCorporateUser(context, corporateUserId!);
    } else if (_selectedScreen == Screens.verificationList) {
      return _verificationRequestsUI();
    } else if (_selectedScreen == Screens.corporateAdd) {
      return _verificationRequestsUI();
    } else if (_selectedScreen == Screens.corporateProfile) {
     return _getViewCompany();
      return _viewCompany();
    } else {
      return _corporateManagement();
    }
  }

  _getViewCompany() {
    var companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    companyProvider.viewCompany(context,
        "true");
    log(companyProvider.company.toJson().toString());
    // Prefill values
    companyImageUrl =
        companyProvider.company.companyImageUrl;
    selectedCompanyType = CorporateType(
      name: companyProvider.company.companyTypeName,
      type: companyProvider.company.companyType,
    );
    _enableDomainCheck =
        companyProvider.company.enableDomainCheck ??
            false;
    selectedCorporateTypeRole = [
      companyType.Roles(
        name: "Admin",
        role: "admin",
      )
    ];
    _domainListController.text = companyProvider
        .company.domainList
        ?.join(",") ??
        '';
    _companyLegalNameController.text =
        companyProvider.company.name ?? '';
    if (companyProvider.company.displayName != null) {
      _companyDisplayNameController.text =
          companyProvider
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
        companyProvider.company.admins?.displayName ??
            '';
    _adminEmailController.text =
        companyProvider.company.admins?.email ?? '';
    _selectedCountryCode = _adminMobileController
        .text =
        companyProvider.company.admins?.mobile ?? '';
    _enableDomainCheck =
        companyProvider.company.enableDomainCheck ??
            false;
    // Set screen to edit

      _selectedScreen = Screens.corporateProfile;
      clearFilters();
      return _viewCompany();
  }

  /// Non Corporate Management
  _getNonCorporateManagementUI() {
    if (_selectedScreen == Screens.nonCorporateList) {
      return _nonCorporateManagement();
    } else if (_selectedScreen == Screens.nonCorporateEdit) {
      return _editNonCorporateUser(context, nonCorporateUserId!);
    } else {
      return _nonCorporateManagement();
    }
  }

  _nonCorporateManagement() {
    return Builder(builder: (context) {
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
                  controller: _nonCorporateSearchController,
                  onChanged: nonCorporateSearchClient,
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
          TabBar(
            controller: _tabNonCorporateController,
            tabs: [
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: CustomSpacing.three,
                  ),
                  Text(
                    'All',
                    style: CustomTypography.BottomNavigationActiveLabel,
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  // rounded container to show number of all users
                  Consumer<NonCorporateProvider>(
                      builder: (context, noncorporateProvider, child) {
                    return SizedBox(
                      height: 25,
                      width: 35,
                      child: Chip(
                        labelPadding: EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          noncorporateProvider.allCount,
                          style: CustomTypography.BottomNavigationActiveLabel
                              .copyWith(height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  Text(
                    'Active',
                    style: CustomTypography.BottomNavigationActiveLabel,
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  // rounded container to show number of all users
                  Consumer<NonCorporateProvider>(
                      builder: (context, noncorporateProvider, child) {
                    return SizedBox(
                      height: 25,
                      width: 35,
                      child: Chip(
                        labelPadding: EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          noncorporateProvider.activeCount,
                          style: CustomTypography.BottomNavigationActiveLabel
                              .copyWith(height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
          !showDeleteNonCorporate?SizedBox():showCheckbox
              ? Consumer<NonCorporateProvider>(
                  builder: (_, nonCorporateProvider, child) {
                  return Row(
                    children: [
                      Checkbox(
                        value: (nonCorporateProvider.employeeList ?? [])
                            .every((element) => element.isSelected!),
                        onChanged: (value) {
                          // Handle select all checkbox value change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            (nonCorporateProvider.employeeList ?? [])
                                .forEach((element) {
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
                                title: Text('Delete Individuals',
                                    style: CustomTypography.H7),
                                content: Text(
                                    'Are you sure you want to delete selected individuals?',
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
                                      nonCorporateProvider
                                          .deleteNonCorporateUser(
                                              context,
                                              (nonCorporateProvider
                                                          .employeeList ??
                                                      [])
                                                  .where((element) =>
                                                      element.isSelected ==
                                                      true)
                                                  .map((e) => e.userId ?? '')
                                                  .toList())
                                          .then((value) {
                                        if (value) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            setState(() {
                                              (nonCorporateProvider
                                                          .employeeList ??
                                                      [])
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                nonCorporateSearchClient(_nonCorporateSearchController.text);
              },
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
                        Consumer<NonCorporateProvider>(
                            builder: (context, noncorporateProvider, child) {
                          return noncorporateProvider.isLoading
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : noncorporateProvider.employeeList!.isEmpty
                                  ? Center(
                                      child: Text('No individuals found',
                                          style: CustomTypography.Body1),
                                    )
                                  : Builder(
                                    builder: (context) {

                                      return ListView.builder(
                                          itemCount: noncorporateProvider
                                                  .employeeList!.length +
                                              (noncorporateProvider.nextPageExists
                                                  ? 1
                                                  : 0),
                                          itemBuilder: (context, index) {
                                            if (index ==
                                                noncorporateProvider
                                                    .employeeList!.length) {
                                              // Reached the end of the current list, load more data
                                              noncorporateProvider
                                                  .getNonCorporateUserList(
                                                context,
                                                searchText: "",
                                                // Adjust parameters as needed
                                                roleFilter: "",
                                                isSearch: false,
                                              );
                                              return SizedBox(
                                                height: 50,
                                                // Placeholder for loading indicator
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            } else {
                                              return _nonCorporateListItem(
                                                  index, noncorporateProvider);
                                            }
                                          },
                                        );
                                    }
                                  );
                        }),
                        // Active Tab
                        Consumer<NonCorporateProvider>(
                            builder: (context, noncorporateProvider, child) {
                              return noncorporateProvider.isLoading
                                  ? Center(
                                child: CircularProgressIndicator(),
                              )
                                  : noncorporateProvider.employeeList!.isEmpty
                                  ? Center(
                                child: Text('No individuals found',
                                    style: CustomTypography.Body1),
                              )
                                  : ListView.builder(
                                itemCount: noncorporateProvider
                                    .employeeList!.length +
                                    (noncorporateProvider.nextPageExists
                                        ? 1
                                        : 0),
                                itemBuilder: (context, index) {
                                  if (index ==
                                      noncorporateProvider
                                          .employeeList!.length) {
                                    // Reached the end of the current list, load more data
                                    noncorporateProvider
                                        .getNonCorporateUserList(
                                      context,
                                      searchText: "",
                                      // Adjust parameters as needed
                                      roleFilter: "",
                                      isSearch: false,
                                    );
                                    return SizedBox(
                                      height: 50,
                                      // Placeholder for loading indicator
                                      child: Center(
                                        child:
                                        CircularProgressIndicator(),
                                      ),
                                    );
                                  } else {
                                    return _nonCorporateListItem(
                                        index, noncorporateProvider);
                                  }
                                },
                              );
                            }),
                        // Pending Tab
                        // ListView.builder(
                        //   itemCount: 5,
                        //   itemBuilder: (context, index) {
                        //     return _corporateEmployeeManagement();
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  _nonCorporateListItem(int index, NonCorporateProvider nonCorporateProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: !showDeleteNonCorporate?null:() {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          selectedCompanyListIndex = index;
          setState(() {
            // companyProvider.companies[index].isSelected =
            // !companyProvider.employeeList[index].isSelected!;
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
                  !showDeleteNonCorporate?SizedBox():showCheckbox
                      ? Checkbox(
                          value: nonCorporateProvider
                              .employeeList![index].isSelected!,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                nonCorporateProvider
                                    .employeeList![index].isSelected = value;
                              });
                            });
                          },
                        )
                      : SizedBox(),
                  CircleAvatar(
                    child: nonCorporateProvider
                                    .employeeList![index].displayImageUrl !=
                                null &&
                            nonCorporateProvider
                                    .employeeList![index].displayImageUrl !=
                                ''
                        ? ClipOval(
                            child: Image.network(
                              nonCorporateProvider!
                                  .employeeList![index].displayImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            nonCorporateProvider
                                    .employeeList![index].displayName
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
                          (nonCorporateProvider.employeeList![index].displayName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (nonCorporateProvider
                                      .employeeList![index].displayName
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
                            nonCorporateProvider
                                    .employeeList![index].displayName ??
                                "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  !showEnableDisableNonCorporate?SizedBox():nonCorporateProvider.isStatusLoading &&
                          selectedNonCorporateListIndex == index
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Switch(
                          value: nonCorporateProvider
                                  .employeeList![index]!.status ??
                              false,
                          onChanged: (value) {
                            // Handle switch value change
                            selectedNonCorporateListIndex = index;
                            // nonCorporateProvider
                            //     .changeCompanyStatus(
                            //     context,
                            //     nonCorporateProvider.employeeList![index].userId ?? '',
                            //     value)
                            //     .then((value) {
                            //   WidgetsBinding.instance.addPostFrameCallback((_) {
                            //     setState(() {
                            //       companyProvider.employeeList![index]!.isEnabled =
                            //           value;
                            //     });
                            //   });
                            // });
                            nonCorporateProvider
                                .changeNonCorporateStatus(
                                    context,
                                    nonCorporateProvider
                                            .employeeList![index].userId ??
                                        '',
                                    value)
                                .then((value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  nonCorporateProvider
                                      .employeeList![index].status = value;
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
                        nonCorporateProvider.employeeList![index].name
                            .toString(),
                        // (nonCorporateProvider.employeeList![index].admins?.name
                        //     ?.substring(0, 1)
                        //     .toUpperCase() ??
                        //     "") +
                        //     (nonCorporateProvider.employeeList![index].admins?.name
                        //         ?.substring(1) ??
                        //         ""),
                        style: CustomTypography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black),
                      ),
                      Text(
                          nonCorporateProvider.employeeList![index].displayName
                              .toString(),
                          // .admins?.email ?? '',
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
                    !showNonCorporateConnectionList?SizedBox():TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(
                                  userId: nonCorporateProvider
                                          .employeeList![index].userId ??
                                      '',
                                  userName: nonCorporateProvider
                                          .employeeList![index].displayName ??
                                      '',
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
                    !showEditNonCorporate?SizedBox():nonCorporateProvider.isEditViewEmployeeLoading &&
                            selectedNonCorporateListIndex == index
                        ? Center(
                            child: Container(
                                height: 20,
                                width: 20,
                                margin: EdgeInsets.only(right: 8),
                                child: CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: Icon(Icons.edit),
                            color: AppColors.primaryMain,
                            onPressed: () async {
                              /// Handle edit company
                              //   await companyProvider.viewCompany(
                              //       context, companyProvider.employeeList[index].userId ?? '');
                              //   log(companyProvider.employeeList.toJson().toString());
                              //   // Prefill values
                              //   companyImageUrl =
                              //       companyProvider.employeeList.companyImageUrl;
                              //   selectedCompanyType = CorporateType(
                              //     name: companyProvider.employeeList.companyTypeName,
                              //     type: companyProvider.employeeList.companyType,
                              //   );
                              //   _enableDomainCheck =
                              //       companyProvider.employeeList.enableDomainCheck ?? false;
                              //   selectedCorporateTypeRole = [
                              //     companyType.Roles(
                              //       name: "Admin",
                              //       role: "admin",
                              //     )
                              //   ];
                              //   _domainListController.text =
                              //       companyProvider.employeeList.domainList?.join(",") ?? '';
                              //   _companyLegalNameController.text =
                              //       companyProvider.employeeList.name ?? '';
                              //   if (companyProvider.employeeList.displayName != null) {
                              //     _companyDisplayNameController.text = companyProvider
                              //         .employeeList!.displayName!
                              //         .substring(0, 1)
                              //         .toUpperCase() +
                              //         companyProvider.employeeList!.displayName!
                              //             .substring(1) ??
                              //         '';
                              //   }
                              //
                              //   _adminNameController.text =
                              //       companyProvider.company.admins?.name ?? "";
                              //   _adminDisplayNameController.text =
                              //       companyProvider.company.admins?.displayName ?? '';
                              //   _adminEmailController.text =
                              //       companyProvider.company.admins?.email ?? '';
                              //   _selectedCountryCode = _adminMobileController.text =
                              //       companyProvider.company.admins?.mobile ?? '';
                              //   _enableDomainCheck =
                              //       companyProvider.company.enableDomainCheck ?? false;
                              //   // Set screen to edit
                              //
                              //   setState(() {
                              //     _selectedScreen = Screens.corporateEdit;
                              //   });
                              selectedNonCorporateListIndex = index;

                              setState(() {
                                nonCorporateUserId = nonCorporateProvider
                                    .employeeList![index].userId;
                                _selectedScreen = Screens.nonCorporateEdit;
                              });
                            },
                          ),
                    nonCorporateProvider.isDeleteLoading &&
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
                                        'Are you sure you want to delete ${nonCorporateProvider.employeeList![index].displayName}?',
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
                                          nonCorporateProvider
                                              .deleteNonCorporateUser(context, [
                                            nonCorporateProvider
                                                    .employeeList![index]
                                                    .userId ??
                                                ''
                                          ]).then((value) {
                                            if (value) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                setState(() {
                                                  nonCorporateProvider
                                                      .employeeList!
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

  Widget _editNonCorporateUser(BuildContext context, String userId) {
    NonCorporateProvider nonCorporateProvider =
        Provider.of<NonCorporateProvider>(context, listen: false);
    return FutureBuilder<UsersCorporate>(
      future: nonCorporateProvider.viewNonCorporateUser(context, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading user data"));
        } else if (snapshot.hasData) {
          UsersCorporate currentUser = snapshot.data!;
          TextEditingController _employeeNameController =
              TextEditingController(text: currentUser.name);
          TextEditingController _employeeEmailController =
              TextEditingController(text: currentUser.email);
          TextEditingController _employeeMobileController =
              TextEditingController(text: currentUser.phone);
          TextEditingController _employeeCountryCodeController =
              TextEditingController(text: currentUser.countryCode);
          String employeeImageUrl = currentUser.displayImageUrl ?? '';
          print(currentUser.role?[0].name.toString());
          print(currentUser.countryCode.toString());
          if (currentUser.role != null && currentUser.role!.isNotEmpty) {
            selectedCorporateTypeRole = [
              companyType.Roles(
                isForIndividual: currentUser.role![0].isForIndividual,
                isMultipleRoleEnabled:
                    currentUser.role![0].isMultipleRoleEnabled,
                isApplicableForTrial: currentUser.role![0].isApplicableForTrial,
                name: currentUser.role![0].name ?? "",
                role: currentUser.role![0].role ?? "",
                isApplicableForInternal:
                    currentUser.role![0].isApplicableForInternal,
                status: currentUser.role![0].status,
              )
            ];
          }
          String? values = currentUser.role?[0].name.toString();

          return SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.paperElavation25
                    : AppColors.paperElavation25Light,
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
                          Text('Edit corporate user account',
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
                                  backgroundImage: AssetImage(
                                      'assets/images/loginImage.png'),
                                  radius: 40,
                                )
                              : CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(employeeImageUrl!),
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
                                style: CustomTypography
                                    .BottomNavigationActiveLabel,
                                textAlign: TextAlign.center,
                              ),
                              // Add button
                              Consumer<CorporateProvider>(
                                  builder: (_, corporateProvider, child) {
                                return corporateProvider
                                        .isEditViewEmployeeLoading
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
                                              Provider.of<EmployeeProvider>(
                                                      context,
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

                          Consumer<CorporateProvider>(
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
                                          selectedRoles:
                                              selectedCorporateTypeRole,
                                          addChip: _addCorporateChip,
                                          removeChip: _removeCorporateChip,
                                          removeAllChips:
                                              _removeAllCorporateChips,
                                          roles:
                                              selectedCompanyType?.roles ?? [],
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
                                              removeChip: _removeCorporateChip,
                                              removeAllChips:
                                                  _removeAllCorporateChips,
                                              roles:
                                                  selectedCompanyType?.roles ??
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
                                    margin: const EdgeInsets.only(right: 32.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: selectedCorporateTypeRole
                                            .map(
                                              (value) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Chip(
                                                    label: Text(
                                                        value.name ?? values!),
                                                    deleteIcon:
                                                        Icon(Icons.cancel),
                                                    onDeleted: () {
                                                      print(
                                                          'Removing chip: ${value.name}');
                                                      setState(() {
                                                        selectedCorporateTypeRole
                                                            ?.removeWhere(
                                                                (element) =>
                                                                    element
                                                                        .name ==
                                                                    value.name);
                                                        values = "";
                                                        selectedCorporateTypeRole ==
                                                            "";
                                                      });
                                                      print(values);
                                                    }),
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
                            readOnly: true,
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child: CountryListPicker(
                                      initialCountry: Countries.Australia,
                                      // Ensure this is correctly set or dynamically assigned
                                      border: InputBorder.none,
                                      flagSize: Size(35, 30),
                                      onChanged: (code) {
                                        // This is typically triggered when a new selection is made in the picker
                                        setState(() {
                                          _selectedCountryCode =
                                              code; // Maintaining a state variable for other uses
                                          _employeeCountryCodeController.text =
                                              code; // Update the controller
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
                                        // This may be triggered based on specific implementations of CountryListPicker
                                        print(
                                            'This is the country code: $country');
                                        setState(() {
                                          _selectedCountryCode =
                                              country.dialing_code;
                                          _employeeCountryCodeController.text =
                                              country.dialing_code;
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
                                  Consumer<CorporateProvider>(builder:
                                      (context, employeeProvider, child) {
                                    return Expanded(
                                      child: employeeProvider.isLoading
                                          ? Center(
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : CustomButton(
                                              type: ButtonType.filled,
                                              onPressed: () {
                                                if (!_createEmployeeFormKey
                                                    .currentState!
                                                    .validate()) {
                                                  return;
                                                }

                                                var body = {
                                                  "userdata": {
                                                    "user_id":
                                                        nonCorporateUserId,
                                                    "display_image_url":
                                                        employeeImageUrl,
                                                    "name":
                                                        _employeeNameController
                                                            .text,
                                                    "email":
                                                        _employeeEmailController
                                                            .text,
                                                    "phone":
                                                        _employeeMobileController
                                                            .text,
                                                    "roles":
                                                        selectedCorporateTypeRole
                                                            .map((role) => {
                                                                  "role":
                                                                      role.role,
                                                                  "name":
                                                                      role.name,
                                                                  "is_applicable_for_internal":
                                                                      role.isApplicableForInternal,
                                                                  "status": role
                                                                      .status
                                                                })
                                                            .toList(),
                                                    "displayName": "",
                                                    "country_code":
                                                        _selectedCountryCode,
                                                    "isIndividual": true
                                                  }
                                                };

                                                Provider.of<CorporateProvider>(
                                                        context,
                                                        listen: false)
                                                    .updateCorporateEmployee(
                                                        context, body)
                                                    .then((value) {
                                                  if (value) {
                                                    Provider.of<CorporateProvider>(
                                                            context,
                                                            listen: false)
                                                        .getCorporateUserList(
                                                            context);
                                                    // Handle success
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      setState(() {
                                                        _selectedScreen =
                                                            Screens
                                                                .employeeList;
                                                        clearFilters();
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
                                              },
                                              child: Text(
                                                'Submit',
                                                style: CustomTypography
                                                    .ButtonLarge,
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
                                          _selectedScreen =
                                              Screens.employeeList;
                                          clearFilters();
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
                          ),
                        ]))
                  ]),
            ),
          );
        } else {
          return Center(child: Text("No user data available"));
        }
      },
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
    return Builder(builder: (context) {
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
                  controller: _employeeSearchController,
                  onChanged: employeeSearchClient,
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
          TabBar(
            controller: _tabEmployeeController,
            tabs: [
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'All',
                    style: CustomTypography.BottomNavigationActiveLabel,
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  // rounded container to show number of all users
                  Consumer<EmployeeProvider>(
                      builder: (context, employeeProvider, child) {
                    return SizedBox(
                      height: 25,
                      width: 35,
                      child: Chip(
                        labelPadding: EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          employeeProvider.allCount.toString(),
                          style: CustomTypography.BottomNavigationActiveLabel
                              .copyWith(height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
              Tab(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Active',
                    style: CustomTypography.BottomNavigationActiveLabel,
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  // rounded container to show number of all users
                  Consumer<EmployeeProvider>(
                      builder: (context, employeeProvider, child) {
                    return SizedBox(
                      height: 25,
                      width: 35,
                      child: Chip(
                        labelPadding: EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          employeeProvider.activeCount.toString(),
                          style: CustomTypography.BottomNavigationActiveLabel
                              .copyWith(height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
          !showDeleteEmployee?SizedBox():showCheckbox
              ? Consumer<EmployeeProvider>(
                  builder: (_, employeeProvider, child) {
                  return Row(
                    children: [
                      Checkbox(
                        value: (employeeProvider.employeeList ?? [])
                            .every((element) => element.isSelected!),
                        onChanged: (value) {
                          // Handle select all checkbox value change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            (employeeProvider.employeeList ?? [])
                                .forEach((element) {
                              setState(() {
                                element.isSelected = value ?? false;
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
                                title: Text('Delete Employees',
                                    style: CustomTypography.H7),
                                content: Text(
                                    'Are you sure you want to delete selected employees?',
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
                                      employeeProvider
                                          .deleteMultipleEmployees(
                                              context,
                                              (employeeProvider.employeeList ??
                                                      [])
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
                                              (employeeProvider.employeeList ??
                                                      [])
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                Provider.of<EmployeeProvider>(context, listen: false)
                    .getAllEmployees(context);
              },
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
                          employeeProvider.isLoading
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : employeeProvider.employeeList!.isEmpty
                                  ? Center(
                                      child: Text('No employees found',
                                          style: CustomTypography.Body1),
                                    )
                                  : ListView.builder(
                                      itemCount: employeeProvider
                                              .employeeList?.length ??
                                          0 +
                                              (employeeProvider.nextPageExists
                                                  ? 1
                                                  : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                            (employeeProvider
                                                    .employeeList?.length ??
                                                0)) {
                                          // Reached the end of the current list, load more data
                                          if (!employeeProvider.isLoading &&
                                              employeeProvider.nextPageExists) {
                                            employeeProvider.getAllEmployees(
                                              context,
                                              searchText: "",
                                              // Adjust parameters as needed
                                              roleFilter: "",
                                              isSearch: false,
                                            );
                                          }
                                          return SizedBox(
                                            height: 50,
                                            // Placeholder for loading indicator
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        } else {
                                          return _employeeManagementListItem(
                                              index, employeeProvider);
                                        }
                                      },
                                    ),

                          // Active Tab
                          employeeProvider.isLoading
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : employeeProvider.employeeList!.isEmpty
                                  ? Center(
                                      child: Text('No employees found',
                                          style: CustomTypography.Body1),
                                    )
                                  : ListView.builder(
                                      itemCount: employeeProvider
                                              .employeeList?.length ??
                                          0 +
                                              (employeeProvider.nextPageExists
                                                  ? 1
                                                  : 0),
                                      itemBuilder: (context, index) {
                                        if (index ==
                                            (employeeProvider
                                                    .employeeList?.length ??
                                                0)) {
                                          // Reached the end of the current list, load more data
                                          if (!employeeProvider.isLoading &&
                                              employeeProvider.nextPageExists) {
                                            employeeProvider.getAllEmployees(
                                              context,
                                              searchText: "",
                                              // Adjust parameters as needed
                                              roleFilter: "",
                                              isSearch: false,
                                            );
                                          }
                                          return SizedBox(
                                            height: 50,
                                            // Placeholder for loading indicator
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        } else {
                                          return _employeeManagementListItem(
                                              index, employeeProvider);
                                        }
                                      },
                                    ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  _employeeManagementListItem(int index, EmployeeProvider employeeProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: !showDeleteEmployee?null:() {
          // Show checkbox
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              showCheckbox = !showCheckbox;
            });
          });
          selectedEmployeeListIndex = index;
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
                  !showDeleteEmployee?SizedBox():showCheckbox
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
                  !showEnableDisableEmployee?SizedBox():employeeProvider.isStatusLoading &&
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
                            selectedEmployeeListIndex = index;
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
                    !showConnectionListEmployee?SizedBox():TextButton.icon(
                      onPressed: () {
                        // Handle view employees
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ConnectionsScreen(
                                  userId: employeeProvider
                                          .employeeList?[index].id ??
                                      "",
                                  userName: employeeProvider
                                          .employeeList?[index].name ??
                                      "",
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
                    !showEditEmployee?SizedBox():employeeProvider.isEditViewEmployeeLoading && selectedEmployeeListIndex == index
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
                              selectedEmployeeListIndex = index;
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
                                clearFilters();
                              });
                            },
                          ),
                    employeeProvider.isDeleteLoading &&
                            selectedEmployeeListIndex == index
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
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.paperElavation25
          : AppColors.paperElavation25Light,
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
            tabs: _verificationTabs,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabVerificationController,
              children: [
                // Corporate Tab
                if (showCorporateVerificationTab)
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
                if (showUserVerificationTab)
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

  buildDropdownMenuItems() {
    return [
      DropdownMenuItem(
        child: Row(
          children: [
            Icon(Icons.apartment),
            SizedBox(width: CustomSpacing.two),
            Text(
              'Corporate Management',
              style: CustomTypography.BottomNavigationActiveLabel,
            ),
          ],
        ),
        value: 'Corporate',
      ),
      showCorporateList
          ? DropdownMenuItem(
              child: Text(
                'Companies',
                style: CustomTypography.BottomNavigationActiveLabel,
              ),
              value: 'Companies',
            )
          : Container(
              height: 0,
              child: DropdownMenuItem(
                child: Text(
                  'Companies',
                  style: CustomTypography.BottomNavigationActiveLabel,
                ),
                value: 'Companies',
              ),
            ),
      showCorporateUserListDropdown
          ? DropdownMenuItem(
              child: Text(
                'Users',
                style: CustomTypography.BottomNavigationActiveLabel,
              ),
              value: 'Users',
            )
          : SizedBox(),
      showViewCorporate
          ? DropdownMenuItem(
              child: Text(
                'Company Profiles',
                style: CustomTypography.BottomNavigationActiveLabel,
              ),
              value: 'Company Profiles',
            )
          : SizedBox(),
      DropdownMenuItem(
        child: Text(
          'Verification Requests',
          style: CustomTypography.BottomNavigationActiveLabel,
        ),
        value: 'Verification Requests',
      ),
    ];
  }
}
