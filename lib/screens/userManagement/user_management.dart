import 'dart:developer';
import '../../utils/global_imports.dart';
import 'package:flutter/foundation.dart';
import 'package:RiskSphere/design_system/components/corporate_type_roles_bottom_sheet.dart';
import 'package:RiskSphere/design_system/components/custom_chip.dart';
import 'package:RiskSphere/models/company_model.dart';
import 'package:RiskSphere/models/company_type_model.dart';
import 'package:RiskSphere/models/corporate_verification_list_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import 'package:RiskSphere/providers/company_provider.dart';
import 'package:RiskSphere/providers/employee_provider.dart';
import 'package:RiskSphere/providers/non_corporate_user_Provider.dart';
import 'package:RiskSphere/providers/verification_provider.dart';
import 'package:RiskSphere/screens/userManagement/connections_screen.dart';
import 'package:RiskSphere/screens/userManagement/service/user_management_corporate_dropdown_menu_service.dart';
import 'package:RiskSphere/screens/userManagement/service/verification_tab_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phone_input/phone_input_package.dart';
import 'package:http/http.dart' as http;

import '../../design_system/components/country_picker_flag_name.dart';
import '../../design_system/repo/constants.dart';
import '../../models/company_type_model.dart' as companyType;
import '../../models/initial_data_model.dart';
import '../../models/user_corporate_model.dart';
import '../../providers/corporate_user_provider.dart';
import '../../providers/role_provider.dart';
import '../../utils/utils.dart';
import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:dropdown_button2/dropdown_button2.dart';

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

  Screens _selectedScreen = Screens.defaultScreen;

  bool showCheckbox = false;
  String? corporateUserId = "";
  String? nonCorporateUserId = "";

  // Create Company Form
  List<Categories> _selectedRoles = [];
  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();
  PhoneController corporateMobileController =
      PhoneController(const PhoneNumber(nsn: '', isoCode: IsoCode.US));
  PhoneController corporateEmployeeMobileController =
      PhoneController(const PhoneNumber(nsn: '', isoCode: IsoCode.US));
  PhoneController corporateEditMobileController =
      PhoneController(const PhoneNumber(nsn: '', isoCode: IsoCode.US));
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

  String _selectedCorporateCountryName = 'United States';

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

  bool isPgAdmin = false;

  PhoneController createEmployeePhoneController =
      PhoneController(PhoneNumber(isoCode: IsoCode.US, nsn: ''));

  UserManagementCorporateDropdownMenuService corporateDropdownMenuService =
      UserManagementCorporateDropdownMenuService();
  VerificationTabsService verificationTabsService = VerificationTabsService();

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

  List<companyType.Roles> _roles = [];
  bool _isLoading = false;

  /// Fetch roles from the API with Firebase Token
  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = "${AppConstant.baseURL}/companies?role=external";
    // "https://us-central1-project-green-dev-429104"

    try {
      // Get the Firebase Authentication token
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not authenticated!");
        return;
      }

      IdTokenResult? tokenResult = await user.getIdTokenResult();
      String? token = tokenResult.token;

      if (token == null || token.isEmpty) {
        print("Error: Firebase token is null or empty.");
        return;
      }

      // Set headers with the Authorization token
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rolesData = data["roles"];

        List<companyType.Roles> fetchedRoles = rolesData.map((role) {
          return companyType.Roles(
            isForIndividual: role["is_for_individual"] ?? false,
            isMultipleRoleEnabled: role["is_multiple_role_enabled"] ?? false,
            isApplicableForTrial: role["is_applicable_for_trial"] ?? false,
            name: role["name"] ?? "",
            role: role["role"] ?? "",
            isApplicableForInternal:
                role["is_applicable_for_internal"] ?? false,
            status: role["status"] ?? false,
          );
        }).toList();

        setState(() {
          _roles = fetchedRoles;
        });

        // Debug: Print roles
        for (var role in _roles) {
          print("Role: ${role.name}, Status: ${role.status}");
        }
      } else {
        print(
            "Failed to load roles: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching roles: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openBottomSheet(BuildContext context) {
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
          roles: _roles,
          isEnabled: true,
        );
      },
    );
  }

  void companyDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (companyDeBouncer != null) {
      companyDeBouncer!.cancel();
    }
    companyDeBouncer = Timer(duration, callback);
  }

  void companySearchClient(String query) async {
    // Debounce the search operation to avoid multiple rapid API calls
    companyDebounce(() async {
      if (!mounted) return;

      // Combine filters for names, emails, phones, and the query
      List<String> searchItems = [];

      // Add name, email, and phone filters
      if (filterNames.isNotEmpty) searchItems.addAll(filterNames);
      if (filterEmails.isNotEmpty) searchItems.addAll(filterEmails);
      if (filterPhones.isNotEmpty) searchItems.addAll(filterPhones);

      // Add the user's query to the search items
      if (query.isNotEmpty) searchItems.add(query);

      // Generate the final search text by joining items with a comma
      String searchText = searchItems.join(",");

      // Combine company type filters
      String companyTypeFilter = filterCompanies.isNotEmpty
          ? filterCompanies.join(",")
          : ""; // Avoid an empty string causing issues in the API

      // Combine role filters
      String roleFilter = filterRoles.isNotEmpty
          ? filterRoles.map((e) => e.id ?? "").join(",")
          : "";

      print(
          'Search Text: $searchText, Company Type Filter: $companyTypeFilter, Role Filter: $roleFilter');

      // Fetch filtered company data using the provider
      await Provider.of<CompanyProvider>(context, listen: false)
          .getAllCompanies(
        context,
        searchText,
        companyTypeFilter,
        roleFilter,
        isSearch: true, // Use named argument here
      );
    });
  }

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
                searchText: searchText,
                roleFilter: roleFilter,
                isSearch: true,
                companyId: selectedCorporateId);
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
            filterRoles.isNotEmpty ||
            status != null;

        // Call the common function to fetch data
        await Provider.of<NonCorporateProvider>(context, listen: false)
            .getNonCorporateUserList(context,
                searchText: searchText,
                roleFilter: roleFilter,
                isSearch: isSearch,
                status: status);
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
    if (widget.initialIndex == 0 &&
        widget.initialScreen == Screens.verificationList) {
      print('Initial Screen: ${widget.initialScreen}');
      setState(() {
        _selectedScreen = Screens.verificationList;
        clearFilters();
        _tabVerificationController?.animateTo(widget.subIndex ?? 0);
      });
    } else if (widget.initialIndex == 0 &&
        widget.initialScreen == Screens.corporateAdd) {
      print('Initial Screen: ${widget.initialScreen}');
      setState(() {
        _selectedScreen = Screens.corporateAdd;
        clearFilters();
        _tabVerificationController?.animateTo(widget.subIndex ?? 0);
      });
    } else if (widget.initialIndex == 0 &&
        widget.initialScreen == Screens.corporateEmployeeAdd) {
      print('Initial Screen123: ${widget.initialScreen}');
      setState(() {
        _selectedScreen = Screens.corporateEmployeeAdd;
        clearFilters();
        _tabVerificationController?.animateTo(widget.subIndex ?? 0);
      });
    } else {
      print('Initial Screen: ${widget.initialScreen}');
      setState(() {
        _selectedScreen = Screens.verificationList;
        clearFilters();
        _tabVerificationController?.animateTo(widget.subIndex ?? 0);
      });
    }

    setState(() {
      print('Selected Screen load end: $_selectedScreen');
      showMainLoading = false;
    });
  }

  Future<void> _setTabs() async {
    final results = await Future.wait([
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.IS_PG_ADMIN),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMCL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMCUM),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMUL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMCC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMEC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMVC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMDC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMED),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMLL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMVU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMCUL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CUMED),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CUMDU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CUMEU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CUMCL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CUMCU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.NCMED),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.NCMDU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.NCMEU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.NCMCL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.EMPED),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.EMPDU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.EMPEU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.EMPCL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.NCMUL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.EMPUL),
    ]);

    // Assign values
    isPgAdmin = results[0] ?? false;
    showCorporateList = results[1] ?? false;
    showCorporateUserListDropdown = results[2] ?? false;
    showCorporateUserList = results[3] ?? false;
    showCreateCorporate = results[4] ?? false;
    showEditCorporate = results[5] ?? false;
    showViewCorporate = results[6] ?? false;
    showDeleteCorporate = results[7] ?? false;
    showEnableDisableCorporate = results[8] ?? false;
    showCorporateVerificationTab = results[9] ?? false;
    showUserVerificationTab = results[10] ?? false;
    showCorporateProfile = results[11] ?? false;
    showEnableDisableUser = results[12] ?? false;
    showDeleteUser = results[13] ?? false;
    showEditUser = results[14] ?? false;
    showConnectionListUser = results[15] ?? false;
    showCreateUser = results[16] ?? false;
    showEnableDisableNonCorporate = results[17] ?? false;
    showDeleteNonCorporate = results[18] ?? false;
    showEditNonCorporate = results[19] ?? false;
    showNonCorporateConnectionList = results[20] ?? false;
    showEnableDisableEmployee = results[21] ?? false;
    showDeleteEmployee = results[22] ?? false;
    showEditEmployee = results[23] ?? false;
    showConnectionListEmployee = results[24] ?? false;
    showNonCorporateList = results[25] ?? false;
    showEmployeeList = results[26] ?? false;

    // Compute tab visibility
    showCorporateManagementTab = showCorporateList ||
        showCorporateUserListDropdown ||
        showCorporateVerificationTab ||
        showCorporateProfile;
    showNonCorporateManagementTab = showNonCorporateList;
    showEmployeeManagementTab = showEmployeeList;

    if (!showCorporateManagementTab &&
        !showNonCorporateManagementTab &&
        !showEmployeeManagementTab) {
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
    _adjustVerificationTabs(context);

    // Fetch data after setting up tabs
    _getData();
  }

  // Future<void> _setTabs() async {
  //   isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.IS_PG_ADMIN) ??
  //       false;
  //   //isPgAdmin = true;
  //   showCorporateList = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMCL) ??
  //       false;
  //   showCorporateUserListDropdown =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.CAMCUM) ??
  //           false;
  //   showCorporateUserList = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMUL) ??
  //       false;
  //   showCreateCorporate = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMCC) ??
  //       false;
  //   showEditCorporate = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMEC) ??
  //       false;
  //   showViewCorporate = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMVC) ??
  //       false;
  //   showDeleteCorporate = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMDC) ??
  //       false;
  //   showEnableDisableCorporate =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.CAMED) ??
  //           false;
  //   showCorporateVerificationTab =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.CAMLL) ??
  //           false;
  //   showUserVerificationTab =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.CAMVU) ??
  //           false;
  //
  //   showCorporateProfile = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CAMCUL) ??
  //       false;
  //
  //   showEnableDisableUser = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CUMED) ??
  //       false;
  //   showDeleteUser = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CUMDU) ??
  //       false;
  //   showEditUser = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CUMEU) ??
  //       false;
  //   showConnectionListUser =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.CUMCL) ??
  //           false;
  //   showCreateUser = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.CUMCU) ??
  //       false;
  //   showEnableDisableNonCorporate =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.NCMED) ??
  //           false;
  //   showDeleteNonCorporate =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.NCMDU) ??
  //           false;
  //   showEditNonCorporate = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.NCMEU) ??
  //       false;
  //   showNonCorporateConnectionList =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.NCMCL) ??
  //           false;
  //   showEnableDisableEmployee =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.EMPED) ??
  //           false;
  //   showDeleteEmployee = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.EMPDU) ??
  //       false;
  //   showEditEmployee = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.EMPEU) ??
  //       false;
  //   showConnectionListEmployee =
  //       await SharedPreferenceService.getClaimForSubfeature(
  //               SharedPreferenceService.EMPCL) ??
  //           false;
  //   showNonCorporateList = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.NCMUL) ??
  //       false;
  //   showEmployeeList = await SharedPreferenceService.getClaimForSubfeature(
  //           SharedPreferenceService.EMPUL) ??
  //       false;
  //
  //   showCorporateManagementTab = showCorporateList ||
  //       showCorporateUserListDropdown ||
  //       showCorporateVerificationTab ||
  //       showCorporateProfile;
  //   showNonCorporateManagementTab = showNonCorporateList;
  //   showEmployeeManagementTab = showEmployeeList;
  //   if (!showCorporateManagementTab &&
  //       !showNonCorporateManagementTab &&
  //       !showEmployeeManagementTab) {
  //     setState(() {
  //       _selectedScreen = Screens.defaultScreen;
  //     });
  //   }
  //
  //   visibleTabCount = [
  //     showCorporateManagementTab,
  //     showNonCorporateManagementTab,
  //     showEmployeeManagementTab,
  //   ].where((tab) => tab).length;
  //
  //   _tabController = TabController(length: visibleTabCount, vsync: this);
  //   print('Tab Count: $visibleTabCount');
  //   _removeUnusedDropdownItems();
  //   _adjustVerificationTabs(context);
  //
  //   _getData();
  // }

  void _removeUnusedDropdownItems() {
    // Get the current corporate dropdown items
    List<DropdownMenuItem<String>> items =
        corporateDropdownMenuService.corporateDropdownItems(context);

    // Remove items based on conditions
    if (!showCorporateList) {
      items.removeWhere((element) => element.value == 'Companies');
    }
    if (!showCorporateUserListDropdown) {
      items.removeWhere((element) => element.value == 'Users');
    }
    if (!showCorporateVerificationTab && !showUserVerificationTab) {
      items.removeWhere((element) => element.value == 'Verification Requests');
    }
    if (!showCorporateProfile) {
      items.removeWhere((element) => element.value == 'Company Profiles');
    }
    print(
        'Access Rights: CorporateList: $showCorporateList, CorporateUserList: $showCorporateUserListDropdown, CorporateVerificationTab: $showCorporateVerificationTab, UserVerificationTab: $showUserVerificationTab, CorporateProfile: $showCorporateProfile');
    print('Items: $items');
    // Setting the updated items
    corporateDropdownMenuService.setCorporateDropdownItems(context, items);
  }

  void _adjustVerificationTabs(BuildContext context) {
    // Get the current verification tabs
    List<Tab> tabs = verificationTabsService.verificationTabs(context);

    // Adjust the tabs based on conditions
    if (!showCorporateVerificationTab && showUserVerificationTab) {
      tabs.removeAt(0); // Remove the first tab (Corporate Verification)
    } else if (showCorporateVerificationTab && !showUserVerificationTab) {
      tabs.removeAt(1); // Remove the second tab (User Verification)
    }

    // Update the tab controller based on the number of visible tabs
    _tabVerificationController =
        TabController(length: tabs.length, vsync: this);

    // Set the updated tabs
    verificationTabsService.setVerificationTabs(context, tabs);
  }

  void _configureMainTabController() {
    print('Controller size: ${_tabController?.length}');
    _selectedScreen = _getScreenForCurrentTab(_tabController?.index);
    _tabController?.addListener(() {
      setState(() {
        print('Tab Index: ${_tabController?.index}');
        _selectedScreen = _getScreenForCurrentTab(_tabController?.index);
        print('Selected Screen: $_selectedScreen');
        clearFilters();
      });
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
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
    } else if (showCorporateVerificationTab || showUserVerificationTab) {
      return Screens.verificationList;
    } else {
      return Screens.corporateProfile;
    }
  }

  void _configureSubTabControllers() {
    _tabNonCorporateController = TabController(length: 2, vsync: this);
    _tabNonCorporateController?.addListener(() {
      final provider =
          Provider.of<NonCorporateProvider>(context, listen: false);
      provider.page = 1; // Reset to the first page
      provider.getNonCorporateUserList(context,
          status: _tabNonCorporateController?.index == 1);
    });

    _tabEmployeeController = TabController(length: 2, vsync: this);
    _tabEmployeeController?.addListener(() {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      provider.page = 1; // Reset to the first page
      provider.getAllEmployees(context,
          status: _tabEmployeeController?.index == 1);
      employeeSearchClient(
        _employeeSearchController.text,
        status: _tabEmployeeController?.index == 1,
      );
    });
  }

  Future<void> _getData() async {
    List<Future> apiCalls = [];

    if (showCorporateUserListDropdown) {
      print("API call for corporate user list");
      apiCalls.add(Provider.of<CorporateProvider>(context, listen: false)
          .getCorporateUserList(context));
    }
    if (showNonCorporateList) {
      print("API call for non corporate user list");
      apiCalls.add(Provider.of<NonCorporateProvider>(context, listen: false)
          .getNonCorporateUserList(context));
    }
    if (showCorporateList) {
      print("API call for corporate list");
      apiCalls.add(Provider.of<CompanyProvider>(context, listen: false)
          .getAllCompanies(context, "", "", ""));
    }

    apiCalls.add(Provider.of<CompanyProvider>(context, listen: false)
        .getCorporateType(context));

    if (showCorporateVerificationTab) {
      print("API call for corporate verification list");
      apiCalls.add(Provider.of<VerificationProvider>(context, listen: false)
          .getAllCorporateRequests(context));
    }
    if (showUserVerificationTab) {
      print("API call for user verification list");
      apiCalls.add(Provider.of<VerificationProvider>(context, listen: false)
          .getAllUserRequests(context));
    }
    if (showEmployeeList) {
      print("API call for employee list");
      apiCalls.add(Provider.of<EmployeeProvider>(context, listen: false)
          .getAllEmployees(context));
    }

    // Parallel API calls for fetching roles
    var roleFuture =
        Provider.of<RoleProvider>(context, listen: false).getAllRoles(context);
    var employeeRoleFuture =
        Provider.of<EmployeeProvider>(context, listen: false).getRoles(context);

    // Await all API calls in parallel
    var results =
        await Future.wait([...apiCalls, roleFuture, employeeRoleFuture]);

    // Assign results to variables after completion
    filterRoleList = allRoles = results[apiCalls.length];
    selectedEmployeeRoles = results[apiCalls.length + 1];

    // If only the corporate profile needs to be loaded, fetch it separately
    if (!showCorporateList &&
        !showCorporateUserListDropdown &&
        !showCorporateVerificationTab &&
        !showUserVerificationTab &&
        showCorporateProfile) {
      var companyProvider =
          Provider.of<CompanyProvider>(context, listen: false);
      await companyProvider.viewCompany(context, "current");
      var company = companyProvider.company;

      companyImageUrl = company.companyImageUrl;
      selectedCompanyType = CorporateType(
        name: company.companyTypeName,
        type: company.companyType,
      );
      _enableDomainCheck = company.enableDomainCheck ?? false;
      selectedCorporateTypeRole = [
        companyType.Roles(
          name: "Admin",
          role: "admin",
        )
      ];
      _domainListController.text = company.domainList?.join(",") ?? '';
      _companyLegalNameController.text = company.name ?? '';
      if (company.displayName != null) {
        _companyDisplayNameController.text =
            company.displayName!.substring(0, 1).toUpperCase() +
                company.displayName!.substring(1);
      }

      _adminNameController.text = company.adminName ?? "";
      _adminDisplayNameController.text = company.adminName ?? '';
      _adminEmailController.text = company.adminEmail ?? '';
      _selectedCountryCode = _adminMobileController.text =
          company.adminCountryCode?.replaceAll('+', '') ?? "1";
      corporateEditMobileController.value = PhoneNumber(
          isoCode:
              countryCodeToIsoCode[_selectedCountryCode]?.first ?? IsoCode.US,
          nsn: company.adminMobile ?? "");
      _enableDomainCheck = company.enableDomainCheck ?? false;
      _selectedCorporateCountryName = company.countryName ?? 'United States';

      // Set screen to edit
      _selectedScreen = Screens.corporateProfile;
      clearFilters();
      log(company.toJson().toString());
    }
  }

  // Future<void> _getData() async {
  //   if (showCorporateUserListDropdown) {
  //     print("API call for corporate user list");
  //     Provider.of<CorporateProvider>(context, listen: false)
  //         .getCorporateUserList(context);
  //   }
  //   if (showNonCorporateList) {
  //     print("API call for non corporate user list");
  //     Provider.of<NonCorporateProvider>(context, listen: false)
  //         .getNonCorporateUserList(context);
  //   }
  //   if (showCorporateList) {
  //     print("API call for corporate list");
  //     Provider.of<CompanyProvider>(context, listen: false)
  //         .getAllCompanies(context, "", "", "");
  //   }
  //   Provider.of<CompanyProvider>(context, listen: false)
  //       .getCorporateType(context);
  //   if (showCorporateVerificationTab) {
  //     print("API call for corporate verification list");
  //     Provider.of<VerificationProvider>(context, listen: false)
  //         .getAllCorporateRequests(context);
  //   }
  //   if (showUserVerificationTab) {
  //     print("API call for user verification list");
  //     Provider.of<VerificationProvider>(context, listen: false)
  //         .getAllUserRequests(context);
  //   }
  //   if (showEmployeeList) {
  //     print("API call for employee list");
  //     Provider.of<EmployeeProvider>(context, listen: false)
  //         .getAllEmployees(context);
  //   }
  //   filterRoleList = allRoles =
  //       await Provider.of<RoleProvider>(context, listen: false)
  //           .getAllRoles(context);
  //   selectedEmployeeRoles =
  //       await Provider.of<EmployeeProvider>(context, listen: false)
  //           .getRoles(context);
  //   filterRoleList = allRoles =
  //       await Provider.of<RoleProvider>(context, listen: false)
  //           .getAllRoles(context);
  //   // if only view corporate in dropdown then call view api
  //   if (!showCorporateList &&
  //       !showCorporateUserListDropdown &&
  //       !showCorporateVerificationTab &&
  //       !showUserVerificationTab &&
  //       showCorporateProfile) {
  //     var companyProvider =
  //         Provider.of<CompanyProvider>(context, listen: false);
  //     companyProvider.viewCompany(context, "current").then((value) {
  //       companyImageUrl = companyProvider.company.companyImageUrl;
  //       selectedCompanyType = CorporateType(
  //         name: companyProvider.company.companyTypeName,
  //         type: companyProvider.company.companyType,
  //       );
  //       _enableDomainCheck = companyProvider.company.enableDomainCheck ?? false;
  //       selectedCorporateTypeRole = [
  //         companyType.Roles(
  //           name: "Admin",
  //           role: "admin",
  //         )
  //       ];
  //       _domainListController.text =
  //           companyProvider.company.domainList?.join(",") ?? '';
  //       _companyLegalNameController.text = companyProvider.company.name ?? '';
  //       if (companyProvider.company.displayName != null) {
  //         _companyDisplayNameController.text = companyProvider
  //                     .company.displayName!
  //                     .substring(0, 1)
  //                     .toUpperCase() +
  //                 companyProvider.company.displayName!.substring(1) ??
  //             '';
  //       }
  //
  //       _adminNameController.text = companyProvider.company.adminName ?? "";
  //       _adminDisplayNameController.text =
  //           companyProvider.company.adminName ?? '';
  //       _adminEmailController.text = companyProvider.company.adminEmail ?? '';
  //       _selectedCountryCode = _adminMobileController.text =
  //           companyProvider.company.adminCountryCode?.replaceAll('+', '') ??
  //               "1";
  //       print('Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
  //       corporateEditMobileController.value = PhoneNumber(
  //           isoCode:
  //               countryCodeToIsoCode[_selectedCountryCode]?.first ?? IsoCode.US,
  //           nsn: companyProvider.company.adminMobile ?? "");
  //       _enableDomainCheck = companyProvider.company.enableDomainCheck ?? false;
  //       _selectedCorporateCountryName =
  //           companyProvider.company.countryName ?? 'United States';
  //       // Set screen to edit
  //       _selectedScreen = Screens.corporateProfile;
  //       clearFilters();
  //       log(companyProvider.company.toJson().toString());
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return SafeArea(
        child: PopScope(
          onPopInvokedWithResult: (canPop, result) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
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
            drawer: const CustomDrawer(),
            floatingActionButton: (_selectedScreen == Screens.corporateList &&
                        showCreateCorporate) ||
                    (_selectedScreen == Screens.corporateEmployeeList &&
                        showCreateUser) ||
                    (_selectedScreen == Screens.employeeList &&
                        showCreateEmployee)
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
                      } else if (_selectedScreen ==
                          Screens.corporateEmployeeEdit) {
                        setState(() {
                          _selectedScreen = Screens.corporateEmployeeEdit;
                          clearFilters();
                        });
                      } else if (_selectedScreen ==
                          Screens.corporateEmployeeList) {
                        var userProfileProvider =
                            Provider.of<UserProfileProvider>(context,
                                listen: false);
                        final trialStatus =
                            userProfileProvider.trialInfo['status'] ?? '';
                        int totalTrialUsers =
                            userProfileProvider.trialInfo['totalUsers'] ?? 0;
                        int totalUsersVerified = userProfileProvider
                                .trialInfo['totalUsersVerified'] ??
                            0;
                        if (trialStatus.isNotEmpty &&
                            (totalUsersVerified >= totalTrialUsers)) {
                          showDialog(
                            context: context,
                            barrierColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                  MessageCard(
                                    isUpgrade: true,
                                    messageTextSpans: [
                                      TextSpan(
                                        text:
                                            'You have reached the maximum limit of users for your account. Please upgrade your account to add more users.',
                                        style: CustomTypography(context).Body1,
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                          return;
                        }

                        filterRoleList = await Provider.of<CorporateProvider>(
                                context,
                                listen: false)
                            .getRolesWithCompanyId(
                                context, selectedCorporateId ?? "");
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
                    child: const Icon(Icons.add),
                  )
                : const SizedBox(),
            body: PopScope(
              /* canPop: (_selectedScreen == Screens.corporateList && !showCheckbox) ||
                  _selectedScreen == Screens.defaultScreen,
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
                      } else if (showUserVerificationTab ||
                          showCorporateVerificationTab) {
                        _selectedScreen = Screens.verificationList;
                      } else {
                        var companyProvider =
                            Provider.of<CompanyProvider>(context, listen: false);
                        companyProvider.viewCompany(context, "true").then((value) {
                          companyImageUrl = companyProvider.company.companyImageUrl;
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
                          print('Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
                          corporateEditMobileController.value = PhoneNumber(isoCode:countryCodeToIsoCode[_selectedCountryCode]?.first??IsoCode.US, nsn: companyProvider.company.admins?.mobile??"");
                          _enableDomainCheck =
                              companyProvider.company.enableDomainCheck ?? false;
                          _selectedCorporateCountryName = companyProvider.company.countryName ?? 'United States';
                          // Set screen to edit

                          /// Todo: Add the code to view the company profile
                          _selectedScreen = Screens.corporateProfile;
                          clearFilters();

                          log(companyProvider.company.toJson().toString());
                        });
                        ///Todo: Add the code to view the company profile
                        _selectedScreen = Screens.corporateProfile;
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
                    if (showCorporateVerificationTab && showUserVerificationTab) {
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
                    } else if (showCorporateVerificationTab) {
                      if (showCorporateList) {
                        _selectedScreen = Screens.corporateList;
                      } else {
                        if (showCorporateUserListDropdown) {
                          _selectedScreen = Screens.corporateEmployeeList;
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    } else if (showUserVerificationTab) {
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
              },*/
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
                        child: showMainLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 24),
                                child: _selectedScreen == Screens.defaultScreen
                                    ? _defaultScreen()
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'User Management',
                                            style:
                                                typography.H5_Regular.copyWith(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? AppColors.white
                                                  : AppColors.black,
                                            ),
                                          ),
                                          // Add 3 tabs
                                          SizedBox(
                                            height: CustomSpacing.two,
                                          ),
                                          _selectedScreen ==
                                                  Screens.defaultScreen
                                              ? _defaultScreen()
                                              : const SizedBox(),
                                          TabBar(
                                            isScrollable: true,
                                            controller: _tabController,
                                            labelStyle: typography
                                                .BottomNavigationActiveLabel,
                                            tabs: [
                                              if (showCorporateManagementTab)
                                                Tab(
                                                  child: DropdownButton(
                                                    underline: const SizedBox(),
                                                    value: 'Corporate',
                                                    items: corporateDropdownMenuService
                                                        .corporateDropdownItems(
                                                            context),
                                                    onChanged: (value) {
                                                      // Handle dropdown item selection
                                                      if (value ==
                                                          'Corporate') {
                                                        setState(() {
                                                          _selectedScreen =
                                                              Screens
                                                                  .corporateList;
                                                          clearFilters();
                                                        });
                                                      } else if (value ==
                                                          'Companies') {
                                                        setState(() {
                                                          _selectedScreen =
                                                              Screens
                                                                  .corporateList;
                                                          clearFilters();
                                                        });
                                                      } else if (value ==
                                                          'Users') {
                                                        setState(() {
                                                          selectedCorporateId =
                                                              "";
                                                          _selectedScreen = Screens
                                                              .corporateEmployeeList;
                                                          clearFilters();
                                                        });
                                                      } else if (value ==
                                                          'Company Profiles') {
                                                        // Handle company profiles option
                                                        setState(() {
                                                          var companyProvider =
                                                              Provider.of<
                                                                      CompanyProvider>(
                                                                  context,
                                                                  listen:
                                                                      false);
                                                          companyProvider
                                                              .viewCompany(
                                                                  context,
                                                                  "current")
                                                              .then((value) {
                                                            companyImageUrl =
                                                                companyProvider
                                                                    .company
                                                                    .companyImageUrl;
                                                            selectedCompanyType =
                                                                CorporateType(
                                                              name: companyProvider
                                                                  .company
                                                                  .companyTypeName,
                                                              type: companyProvider
                                                                  .company
                                                                  .companyType,
                                                            );
                                                            _enableDomainCheck =
                                                                companyProvider
                                                                        .company
                                                                        .enableDomainCheck ??
                                                                    false;
                                                            selectedCorporateTypeRole =
                                                                [
                                                              companyType.Roles(
                                                                name: "Admin",
                                                                role: "admin",
                                                              )
                                                            ];
                                                            _domainListController
                                                                    .text =
                                                                companyProvider
                                                                        .company
                                                                        .domainList
                                                                        ?.join(
                                                                            ",") ??
                                                                    '';
                                                            _companyLegalNameController
                                                                    .text =
                                                                companyProvider
                                                                        .company
                                                                        .name ??
                                                                    '';
                                                            if (companyProvider
                                                                    .company
                                                                    .displayName !=
                                                                null) {
                                                              _companyDisplayNameController
                                                                  .text = companyProvider
                                                                          .company
                                                                          .displayName!
                                                                          .substring(
                                                                              0,
                                                                              1)
                                                                          .toUpperCase() +
                                                                      companyProvider
                                                                          .company
                                                                          .displayName!
                                                                          .substring(
                                                                              1) ??
                                                                  '';
                                                            }

                                                            _adminNameController
                                                                    .text =
                                                                companyProvider
                                                                        .company
                                                                        .adminName ??
                                                                    "";
                                                            _adminDisplayNameController
                                                                    .text =
                                                                companyProvider
                                                                        .company
                                                                        .adminName ??
                                                                    '';
                                                            _adminEmailController
                                                                    .text =
                                                                companyProvider
                                                                        .company
                                                                        .adminEmail ??
                                                                    '';
                                                            _selectedCountryCode =
                                                                _adminMobileController
                                                                    .text = companyProvider
                                                                        .company
                                                                        .adminCountryCode
                                                                        ?.replaceAll(
                                                                            '+',
                                                                            '') ??
                                                                    "1";
                                                            print(
                                                                'Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
                                                            corporateEditMobileController.value = PhoneNumber(
                                                                isoCode: countryCodeToIsoCode[
                                                                            _selectedCountryCode]
                                                                        ?.first ??
                                                                    IsoCode.US,
                                                                nsn: companyProvider
                                                                        .company
                                                                        .adminMobile ??
                                                                    "");
                                                            _enableDomainCheck =
                                                                companyProvider
                                                                        .company
                                                                        .enableDomainCheck ??
                                                                    false;
                                                            _selectedCorporateCountryName =
                                                                companyProvider
                                                                        .company
                                                                        .countryName ??
                                                                    "United States";
                                                            // Set screen to edit

                                                            _selectedScreen =
                                                                Screens
                                                                    .corporateProfile;
                                                            clearFilters();

                                                            log(companyProvider
                                                                .company
                                                                .toJson()
                                                                .toString());
                                                            _selectedCorporateCountryName =
                                                                companyProvider
                                                                        .company
                                                                        .countryName ??
                                                                    "United States";
                                                          });
                                                          _selectedScreen = Screens
                                                              .corporateProfile;
                                                          clearFilters();
                                                        });
                                                      } else if (value ==
                                                          'Verification Requests') {
                                                        // Handle verification requests option
                                                        setState(() {
                                                          _selectedScreen = Screens
                                                              .verificationList;
                                                          clearFilters();
                                                        });
                                                      } else if (value ==
                                                          'AnotherOption') {
                                                        // Handle another option
                                                      }
                                                      _tabController
                                                          ?.animateTo(0);
                                                    },
                                                  ),
                                                ),
                                              if (showNonCorporateManagementTab)
                                                InkWell(
                                                  onTap: () {
                                                    _tabController?.animateTo(
                                                        showCorporateManagementTab
                                                            ? 1
                                                            : 0);
                                                    _selectedScreen = Screens
                                                        .nonCorporateList;
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(Icons.people),
                                                      SizedBox(
                                                        width:
                                                            CustomSpacing.two,
                                                      ),
                                                      const Tab(
                                                          text:
                                                              'Non Corporate Management'),
                                                    ],
                                                  ),
                                                ),
                                              if (showEmployeeManagementTab)
                                                InkWell(
                                                  onTap: () {
                                                    int destinationTabIndex =
                                                        showCorporateManagementTab
                                                            ? showNonCorporateManagementTab
                                                                ? 2 // If both Corporate and Non-Corporate tabs are visible
                                                                : 1 // If only Corporate tab is visible
                                                            : 0; // If neither Corporate nor Non-Corporate tabs are visible
                                                    _tabController?.animateTo(
                                                        destinationTabIndex);
                                                    _selectedScreen =
                                                        Screens.employeeList;
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                          Icons.account_circle),
                                                      SizedBox(
                                                        width:
                                                            CustomSpacing.two,
                                                      ),
                                                      const Tab(
                                                          text:
                                                              'Employee Management'),
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
                                                if (showCorporateManagementTab)
                                                  _getCorporateManagementUI(),
                                                // Non Corporate Management
                                                if (showNonCorporateManagementTab)
                                                  _getNonCorporateManagementUI(),
                                                // Employee Management
                                                if (showEmployeeManagementTab)
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
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: CustomSpacing.four),
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
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
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
                                ? const SizedBox()
                                : TextButton(
                                    onPressed: () {
                                      // Handle clear filter
                                      removeAllFilters();
                                    },
                                    child: Text(LanguageService.getTranslated(
                                        context,
                                        'usermanagement_app_filter_clear')),
                                  ),
                            Divider(
                              thickness: 1,
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            SizedBox(
                              height: CustomSpacing.two,
                            ),
                            Builder(builder: (context) {
                              return Column(
                                children: [
                                  // name, phone, email, company, role dropdown, status,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Form(
                                        child: Column(children: [
                                      // Name
                                      TextFormField(
                                        controller: _filterNameController,
                                        decoration: InputDecoration(
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_name'),
                                          labelStyle: typography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: CustomSpacing.two,
                                      ),
                                      // Email
                                      TextFormField(
                                        readOnly: true,
                                        controller: _filterEmailController,
                                        decoration: InputDecoration(
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_email'),
                                          labelStyle: typography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_phone'),
                                          hintText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_phone_hint'),
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
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_company'),
                                          labelStyle: typography.Body1,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: CustomSpacing.two),
                                      // Role Dropdown
                                      (_selectedScreen == Screens.corporateList)
                                          ? const SizedBox()
                                          : DropdownButtonFormField<
                                              roleModel.Roles>(
                                              decoration: InputDecoration(
                                                labelText: LanguageService
                                                    .getTranslated(context,
                                                        'usermanagement_app_filter_role'),
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
                                              onChanged:
                                                  (roleModel.Roles? value) {
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
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_filter_status'),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                    _filterCompanyController
                                                        .text,
                                                    'company');
                                                _filterCompanyController
                                                    .clear();
                                              }
                                              if (selectedRoleForFilter !=
                                                  null) {
                                                addFilter(
                                                    selectedRoleForFilter
                                                            ?.name ??
                                                        '',
                                                    'role');
                                                selectedRoleForFilter = null;
                                              }
                                              if (selectedStatus.isNotEmpty) {
                                                addFilter(
                                                    selectedStatus, 'status');
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
                                                  Screens
                                                      .corporateEmployeeList) {
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
                                                    _employeeSearchController
                                                        .text);
                                                Scaffold.of(context)
                                                    .closeEndDrawer();
                                              }
                                            },
                                            type: ButtonType.filled,
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  'usermanagement_app_filter_submit'),
                                              style: typography.ButtonLarge,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 22,
                                                      vertical: 8),
                                            ),
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  'usermanagement_app_filter_cancel'),
                                              style: typography.ButtonLarge,
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
          ),
        ),
      );
    });
  }

  _defaultScreen() {
    var typography = CustomTypography(context);
    return Column(
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
    );
  }

  _corporateManagement() {
    var typography = CustomTypography(context);
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
            Text(
                LanguageService.getTranslated(
                    context, 'usermanagement_companies_list_companies_title'),
                style: typography.H6.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.white
                        : AppColors.black)),
            SizedBox(
              height: CustomSpacing.four,
            ),
            Text(
                LanguageService.getTranslated(
                    context, 'usermanagement_companies_list_subtitle'),
                style: typography.Body2),
            SizedBox(
              height: CustomSpacing.four,
            ),
            // Add Search and filter dropdown in a row
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _corporateSearchController,
                      onChanged: companySearchClient,
                      decoration: InputDecoration(
                        hintText: LanguageService.getTranslated(context,
                            'usermanagement_search_field_lable_name_email_mobile'),
                        label: Text(
                            LanguageService.getTranslated(
                                context, 'usermanagement_search_field_lable'),
                            style: typography.Body1),
                        hintStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: CustomSpacing.four,
                ),
                GestureDetector(
                  onTap: () {
                    //Show end drawer
                    Scaffold.of(context).openEndDrawer();
                  },
                  child: const Icon(
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
                        Text(
                            LanguageService.getTranslated(context,
                                "usermanagement_app_corporate_management_select_all_text"),
                            style: typography.Body1),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // Handle delete selected companies
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                      LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_management_bulk_delete_dialog_title'),
                                      style: typography.H7),
                                  content: Text(
                                      LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_management_bulk_delete_dialog_description'),
                                      style: typography.Body2),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(LanguageService.getTranslated(
                                          context, 'cancel')),
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
                                      child: Text(LanguageService.getTranslated(
                                          context, 'delete')),
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
                : const SizedBox(),

            // Add Company List
            Expanded(
              child: Consumer<CompanyProvider>(
                builder: (context, companyProvider, child) {
                  return companyProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : companyProvider.companies.isEmpty
                          ? Center(
                              child: Text(
                                  LanguageService.getTranslated(context,
                                      "usermanagement_app_corporate_management_empty_list_text"),
                                  style: typography.Body1),
                            )
                          : /*ListView.builder(
                              itemCount: companyProvider.companies.length +
                                  (companyProvider.companyListNextPageExists
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == companyProvider.companies.length) {
                                  // Reached the end of the current list, load more data
                                  companyProvider.getAllCompanies(context, "",
                                      "", ""); // Adjust parameters as needed
                                  return const SizedBox(
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
                            );*/
                          ListView.builder(
                              itemCount: companyProvider.companies.length,
                              itemBuilder: (context, index) {
                                if (index ==
                                    companyProvider.companies.length - 1) {
                                  // Check if it's the last item
                                  if (companyProvider.isNextPageLoading) {
                                    // Display loading indicator
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  } else if (companyProvider.page >=
                                          companyProvider.totalPages &&
                                      companyProvider.companies.isNotEmpty) {
                                    // Display end of list message
                                    return Column(
                                      children: [
                                        _companyListItem(
                                            index, companyProvider),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "company_list_app_end_of_list_text"),
                                              style: CustomTypography(context)
                                                  .Body1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Trigger fetching the next page
                                    companyProvider.page =
                                        companyProvider.page + 1;
                                    companyProvider.getAllCompanies(
                                      context,
                                      _corporateSearchController.text,
                                      "", // Pass company type filter
                                      "", // Pass role filter
                                    );
                                    return const SizedBox(); // Placeholder
                                  }
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
    var typography = CustomTypography(context);
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(top: 0.0, bottom: 8),
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
                        ? const SizedBox()
                        : showCheckbox
                            ? Checkbox(
                                value: companyProvider
                                    .companies[index].isSelected!,
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
                            : const SizedBox(),
                    CircleAvatar(
                      child: companyProvider.companies[index].companyImageUrl !=
                                  null &&
                              companyProvider
                                  .companies[index].companyImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                companyProvider
                                    .companies[index].companyImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              (companyProvider.companies[index].displayName ??
                                          "")
                                      .isNotEmpty
                                  ? companyProvider
                                      .companies[index].displayName!
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : (companyProvider.companies[index].name ??
                                              "")
                                          .isNotEmpty
                                      ? companyProvider.companies[index].name!
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : "",
                              style: typography.Body2.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                              ),
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
                            (companyProvider.companies[index].displayName ?? "")
                                    .isNotEmpty
                                ? companyProvider.companies[index].displayName!
                                        .substring(0, 1)
                                        .toUpperCase() +
                                    companyProvider
                                        .companies[index].displayName!
                                        .substring(1)
                                : (companyProvider.companies[index].name ?? "")
                                        .isNotEmpty
                                    ? companyProvider.companies[index].name!
                                            .substring(0, 1)
                                            .toUpperCase() +
                                        companyProvider.companies[index].name!
                                            .substring(1)
                                    : "",
                            style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                              companyProvider
                                      .companies[index].companyTypeName ??
                                  "",
                              style: typography.Caption),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: CustomSpacing.two,
                    ),
                    !showEnableDisableCorporate
                        ? const SizedBox()
                        : companyProvider.isStatusLoading &&
                                selectedCompanyListIndex == index
                            ? const Padding(
                                padding: EdgeInsets.only(top: 8.0, right: 8.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            : Switch(
                                value: companyProvider
                                        .companies[index].isEnabled ??
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
                          (companyProvider.companies[index].adminName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "") +
                              (companyProvider.companies[index].adminName
                                      ?.substring(1) ??
                                  ""),
                          style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                        ),
                        Text(companyProvider.companies[index].adminEmail ?? '',
                            style: typography.Caption),
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
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon with text
                      showCorporateUserList
                          ? Consumer<CorporateProvider>(
                              builder: (context, corporateProvider, child) {
                              return TextButton.icon(
                                onPressed: () async {
                                  // Handle view employees
                                  print('View Employees');
                                  selectedCorporateId =
                                      companyProvider.companies[index].id ?? '';

                                  await corporateProvider.getCorporateUserList(
                                      context,
                                      companyId:
                                          companyProvider.companies[index].id ??
                                              '',
                                      isSearch: true);

                                  selectedCorporateId =
                                      companyProvider.companies[index].id ?? '';
                                  setState(() {
                                    _corporateEmployeeSearchController.text =
                                        "";
                                    _selectedScreen =
                                        Screens.corporateEmployeeList;
                                    clearFilters();
                                  });
                                },
                                icon: const Icon(Icons.people),
                                label: Text('View Employees',
                                    style: typography.Caption.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.white
                                            : AppColors.black)),
                              );
                            })
                          : const SizedBox(),
                      const Spacer(),
                      showEditCorporate
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              color: AppColors.primaryMain,
                              onPressed: () async {
                                /// Handle edit company
                                await companyProvider.viewCompany(context,
                                    companyProvider.companies[index].id ?? '');
                                log(companyProvider.company
                                    .toJson()
                                    .toString());
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
                                if (companyProvider.company.displayName !=
                                    null) {
                                  _companyDisplayNameController.text =
                                      (companyProvider.company.displayName ??
                                                  "")
                                              .isNotEmpty
                                          ? companyProvider.company.displayName!
                                                  .substring(0, 1)
                                                  .toUpperCase() +
                                              companyProvider
                                                  .company.displayName!
                                                  .substring(1)
                                          : (companyProvider.company.name ?? "")
                                                  .isNotEmpty
                                              ? companyProvider.company.name!
                                                      .substring(0, 1)
                                                      .toUpperCase() +
                                                  companyProvider.company.name!
                                                      .substring(1)
                                              : '';
                                }

                                _adminNameController.text =
                                    companyProvider.company.adminName ?? "";
                                _adminDisplayNameController.text =
                                    companyProvider.company.adminName ?? '';
                                _adminEmailController.text =
                                    companyProvider.company.adminEmail ?? '';
                                _selectedCountryCode = _adminMobileController
                                        .text =
                                    (companyProvider.company.adminCountryCode ??
                                            '')
                                        .replaceAll('+', '');
                                print(
                                    'Country Code: ${countryCodeToIsoCode[_selectedCountryCode]}');
                                corporateEditMobileController.value =
                                    PhoneNumber(
                                        isoCode: countryCodeToIsoCode[
                                                    _selectedCountryCode]
                                                ?.first ??
                                            IsoCode.US,
                                        nsn: companyProvider
                                                .company.adminMobile ??
                                            "");
                                _enableDomainCheck =
                                    companyProvider.company.enableDomainCheck ??
                                        false;
                                _selectedCorporateCountryName =
                                    companyProvider.company.countryName ??
                                        "United States";
                                if (companyProvider.company.admins != null &&
                                    companyProvider
                                        .company.admins!.isNotEmpty) {
                                  _selectedUser = companyProvider
                                      .company.admins!
                                      .firstWhere(
                                    (admin) =>
                                        admin.email ==
                                        companyProvider.company.adminEmail,
                                    // Match by admin ID or other unique property
                                    orElse: () => companyProvider
                                        .company
                                        .admins!
                                        .first, // Fallback to the first admin
                                  );
                                }
                                // Set screen to edit

                                setState(() {
                                  _selectedScreen = Screens.corporateEdit;
                                  clearFilters();
                                });
                              },
                            )
                          : const SizedBox(),
                      !showDeleteCorporate
                          ? const SizedBox()
                          : companyProvider.isDeleteLoading &&
                                  selectedCompanyListIndex == index
                              ? Center(
                                  child: Container(
                                      height: 20,
                                      width: 20,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: const CircularProgressIndicator()),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: AppColors.primaryMain,
                                  onPressed: () {
                                    selectedCompanyListIndex = index;
                                    // Handle delete by showing dialog
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: const Color(0xFF1C1C1E),
                                      // Dark background
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                      ),
                                      builder: (context) {
                                        final name = companyProvider
                                                .companies[index].displayName ??
                                            '';
                                        String selectedUserId = '';
                                        final eligibleUsers = [
                                          {
                                            'name': 'Arslan',
                                            'email': 'arslan@example.com',
                                            'avatar': '👨‍🎨'
                                          },
                                          {
                                            'name': 'Amit Didwania',
                                            'email': 'amit@example.com',
                                            'avatar': '👨🏾‍💻'
                                          },
                                          {
                                            'name': 'Naveen Aggrawal',
                                            'email': 'naveen@example.com',
                                            'avatar': '👨🏻‍💼'
                                          },
                                        ];

                                        return StatefulBuilder(
                                          builder: (context, setModalState) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      24, 32, 24, 32),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Are you sure you want to delete $name',
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'To ensure continuity, please assign another eligible user to take over their responsibilities.',
                                                    style: typography.Body1
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white70),
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Search Field (non-functional placeholder)
                                                  TextField(
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Search by name or email ID',
                                                      hintStyle:
                                                          const TextStyle(
                                                              color: Colors
                                                                  .white54),
                                                      prefixIcon: const Icon(
                                                          Icons.search,
                                                          color:
                                                              Colors.white60),
                                                      filled: true,
                                                      fillColor: Colors.black45,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide:
                                                            BorderSide.none,
                                                      ),
                                                    ),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Scrollable user list
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxHeight: 200),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: ListView.separated(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          eligibleUsers.length,
                                                      separatorBuilder:
                                                          (_, __) =>
                                                              const Divider(
                                                                  height: 1,
                                                                  color: Colors
                                                                      .white12),
                                                      itemBuilder:
                                                          (context, i) {
                                                        final user =
                                                            eligibleUsers[i];
                                                        return ListTile(
                                                          leading: CircleAvatar(
                                                              child: Text(user[
                                                                  'avatar']!)),
                                                          title: Text(
                                                              user['name']!,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                          subtitle: Text(
                                                              user['email']!,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white70)),
                                                          trailing:
                                                              Radio<String>(
                                                            value:
                                                                user['email']!,
                                                            groupValue:
                                                                selectedUserId,
                                                            onChanged: (val) {
                                                              setModalState(() {
                                                                selectedUserId =
                                                                    val!;
                                                              });
                                                            },
                                                            activeColor:
                                                                Colors.red,
                                                          ),
                                                          onTap: () {
                                                            setModalState(() {
                                                              selectedUserId =
                                                                  user[
                                                                      'email']!;
                                                            });
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),

                                                  const SizedBox(height: 16),
                                                  Text(
                                                    "Note: All related Accounts, Sub-Accounts, SOVs, and Location Lists will be transferred and shared via email with the assigned user.",
                                                    style: typography.Body2
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white60),
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // Assign & Delete Button
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        companyProvider
                                                            .deleteCompany(
                                                                context, [
                                                          companyProvider
                                                                  .companies[
                                                                      index]
                                                                  .id ??
                                                              ''
                                                        ]).then((value) {
                                                          if (value) {
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback(
                                                                    (_) {
                                                              setState(() {
                                                                companyProvider
                                                                    .companies
                                                                    .removeAt(
                                                                        index);
                                                              });
                                                            });
                                                          }
                                                        });
                                                      },
                                                      child: const Text(
                                                          'Assign & Delete',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ),

                                                  const SizedBox(height: 12),

                                                  // Download Data Button
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.lightBlue,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        // Add download logic here
                                                      },
                                                      child: const Text(
                                                          'Download Data',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black)),
                                                    ),
                                                  ),

                                                  const SizedBox(height: 12),

                                                  // Cancel Button
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Colors.white,
                                                        side: const BorderSide(
                                                            color:
                                                                Colors.white24),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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
    });
  }

  _corporateEmployeeManagement() {
    var typography = CustomTypography(context);
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
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _corporateEmployeeSearchController,
                      onChanged: corporateEmployeeSearchClient,
                      decoration: InputDecoration(
                        hintText: LanguageService.getTranslated(context,
                            'usermanagement_search_field_lable_name_email_mobile'),
                        label: Text(
                            LanguageService.getTranslated(
                                context, "usermanagement_search_field_lable"),
                            style: typography.Body1),
                        hintStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                  child: const Icon(
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
                        Text(
                            LanguageService.getTranslated(context,
                                "usermanagement_app_corporate_employee_management_select_all_text"),
                            style: typography.Body1),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // Handle delete selected companies
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                      LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_employee_management_bulk_delete_dialog_title'),
                                      style: typography.H7),
                                  content: Text(
                                      LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_employee_management_bulk_delete_dialog_description'),
                                      style: typography.Body2),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(LanguageService.getTranslated(
                                          context,
                                          'usermanagement_app_corporate_employee_management_bulk_delete_dialog_cancel')),
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
                                      child: Text(LanguageService.getTranslated(
                                          context,
                                          'usermanagement_app_corporate_employee_management_bulk_delete_dialog_delete')),
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
                : const SizedBox(),
            // Add Company List
            SizedBox(
              height: CustomSpacing.four,
            ),
            Expanded(
              child: Consumer<CorporateProvider>(
                  builder: (context, corporateProvider, child) {
                return corporateProvider.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : (corporateProvider.employeeList ?? []).isEmpty
                        ? Center(
                            child:
                                Text('No employees', style: typography.Body1),
                          )
                        : ListView.builder(
                            itemCount:
                                corporateProvider.employeeList?.length ?? 0,
                            itemBuilder: (context, index) {
                              if (index ==
                                  corporateProvider.employeeList!.length - 1) {
                                // Check if it's the last item
                                if (corporateProvider.isNextPageLoading) {
                                  // Display loading indicator
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else if (corporateProvider.page >=
                                        corporateProvider.totalPages &&
                                    corporateProvider
                                        .employeeList!.isNotEmpty) {
                                  // Display end of list message
                                  return Column(
                                    children: [
                                      _corporateUserList(
                                          index, corporateProvider),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "End of the list",
                                            // You can use your localized text here
                                            style:
                                                CustomTypography(context).Body1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Trigger fetching the next page
                                  corporateProvider.page += 1;
                                  corporateProvider.getCorporateUserList(
                                    context,
                                    companyId: selectedCorporateId,
                                  );
                                  return const SizedBox(); // Placeholder for fetching
                                }
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
    var typography = CustomTypography(context);
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: Card(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
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
                      Text(
                          LanguageService.getTranslated(context,
                              'usermanagement_crete_new_corporateacct_main_title'),
                          style: typography.H7.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
                      SizedBox(
                        height: CustomSpacing.four,
                      ),
                      Text(
                          LanguageService.getTranslated(context,
                              'usermanagement_crete_new_corporateacct_main_titledesc'),
                          style: typography.Body2),
                      SizedBox(
                        height: CustomSpacing.three,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
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
                                ? const CircleAvatar(
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
                                  LanguageService.getTranslated(context,
                                      'usermanagement_upload_image_txt'),
                                  style: typography.Body1.copyWith(
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: CustomSpacing.two,
                                ),
                                Text(
                                  LanguageService.getTranslated(
                                      context, 'usermanagement_app_image_size'),
                                  style: typography.BottomNavigationActiveLabel,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: CustomSpacing.two,
                                ),
                                // Add button
                                Consumer<CompanyProvider>(
                                    builder: (_, companyProvider, child) {
                                  return companyProvider.isImageUploadLoading
                                      ? const Center(
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
                                            LanguageService.getTranslated(
                                                context,
                                                'usermanagement_upload_image_btn'),
                                            style: typography.ButtonLarge,
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
                            // Corporate Country just show flag and country name
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CountryPickerFlagName(
                                    onCountryChange: (country) {
                                      setState(() {
                                        _selectedCorporateCountryName =
                                            country.name;
                                      });
                                    },
                                    initialValue: country_picker.Country(
                                      phoneCode: '1',
                                      countryCode: getCountryCodeFromName(
                                              _selectedCorporateCountryName) ??
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
                            // Company Type
                            Consumer<CompanyProvider>(
                                builder: (_, companyProvider, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            'usermanagement_company type_label'),
                                        labelStyle: typography.Body1,
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
                                            style: typography.Body1,
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
                              padding: const EdgeInsets.symmetric(
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
                                    LanguageService.getTranslated(
                                        context, 'usermanagement_domain_check'),
                                    style: typography.Body1,
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
                                          labelText: LanguageService.getTranslated(
                                              context,
                                              'usermanagement_domainname_list'),
                                          labelStyle: typography.Body1,
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
                                            return LanguageService.getTranslated(
                                                context,
                                                'usermanagement_domainname_list_error');
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: CustomSpacing.four),
                                    ],
                                  )
                                : const SizedBox(),
                            // Company Legal Name
                            TextFormField(
                              controller: _companyLegalNameController,
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(
                                    context,
                                    'usermanagement_company_name_field_label'),
                                labelStyle: typography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return LanguageService.getTranslated(context,
                                      'usermanagement_company_name_field_label_error');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Company Display Name
                            TextFormField(
                              controller: _companyDisplayNameController,
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(
                                    context, 'usermanagement_display_label'),
                                labelStyle: typography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return LanguageService.getTranslated(context,
                                      'usermanagement_app_corporate_display_name_validator');
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
                                  LanguageService.getTranslated(context,
                                      'usermanagement_users&roles_field_label'),
                                  style: typography.Subtitle1.copyWith(
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
                                      enabled: false, // Disable user input
                                      controller: _textEditingController,
                                      decoration: InputDecoration(
                                        labelText:
                                            LanguageService.getTranslated(
                                                context,
                                                'usermanagement_roles_label'),
                                        //hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
                                        border: const OutlineInputBorder(),
                                        suffixIcon: const Icon(Icons
                                            .arrow_drop_down), // Remove onPressed handler
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
                                                      label: Text(
                                                          value.name ?? ''),
                                                      deleteIcon: const Icon(Icons
                                                          .cancel), // Remove onDeleted handler
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
                                labelText: LanguageService.getTranslated(
                                    context, 'usermanagement_name_field_label'),
                                labelStyle: typography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == "") {
                                  return LanguageService.getTranslated(context,
                                      'usermanagement_name_field_label_error');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Display Name
                            TextFormField(
                              controller: _adminDisplayNameController,
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(
                                    context,
                                    'usermanagement_display_name_field_label'),
                                labelStyle: typography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                // can be empty but if not empty, should not have digits
                                if (value != null &&
                                    value != "" &&
                                    RegExp(r'[0-9]').hasMatch(value)) {
                                  return LanguageService.getTranslated(context,
                                      'usermanagement_app_corporate_display_name_validator');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Phone
                            Row(
                              children: [
                                Expanded(
                                  child: PhoneInput(
                                    key: const Key('phone-field'),
                                    controller: corporateMobileController,
                                    shouldFormat: true,
                                    defaultCountry: IsoCode.US,
                                    decoration: InputDecoration(
                                      labelText: LanguageService.getTranslated(
                                          context, "register_mobile_number"),
                                      hintText: LanguageService.getTranslated(
                                          context,
                                          "register_non_corporate_mobilefield_placeholder"),
                                      border: const OutlineInputBorder(),
                                      counterText: '',
                                    ),
                                    countrySelectorNavigator:
                                        const CountrySelectorNavigator.dialog(
                                      showSearchInput: true,
                                      searchInputDecoration: InputDecoration(
                                        hintText: 'Search Country',
                                      ),
                                    ),
                                    showFlagInInput: true,
                                    flagShape: BoxShape.circle,
                                    flagSize: 35,
                                    onChanged: (PhoneNumber? p) {
                                      if (p == null) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedCountryCode = p.countryCode;
                                      });
                                      print('changed ${p.countryCode}');
                                    },
                                    onSaved: (PhoneNumber? p) {
                                      if (p == null) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedCountryCode = p.countryCode;
                                      });
                                      print('changed ${p.countryCode}');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.four),
                            // Email
                            TextFormField(
                              readOnly: true,
                              controller: _adminEmailController,
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(
                                    context,
                                    'usermanagement_email_field_label'),
                                labelStyle: typography.Body1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    regextest(value) == false) {
                                  return LanguageService.getTranslated(context,
                                      'usermanagement_email_placeholder');
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
                                            ? const Center(
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
                                                  if (_adminNameController.text.isEmpty ||
                                                      _adminEmailController
                                                          .text.isEmpty ||
                                                      _companyLegalNameController
                                                          .text.isEmpty ||
                                                      selectedCompanyType ==
                                                          null ||
                                                      selectedCorporateTypeRole
                                                          .isEmpty ||
                                                      _selectedCorporateCountryName
                                                          .isEmpty) {
                                                    // Show snackbar with name of field empty
                                                    if (_adminNameController
                                                        .text.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_user_name_error_text'),
                                                              style: typography
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
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_user_email_error_text'),
                                                              style: typography
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
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_company_legal_name_invalid_error_text'),
                                                              style: typography
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
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_company_type_invalid_error_text'),
                                                              style: typography
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
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_company_roles_invalid_error_text'),
                                                              style: typography
                                                                  .Body1),
                                                        ),
                                                      );
                                                    } else if (_selectedCorporateCountryName
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      'usermanagement_app_corporate_create_company_country_invalid_error_text'),
                                                              style: typography
                                                                  .Body1),
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  // Create body
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
                                                          corporateMobileController
                                                                  .value?.nsn ??
                                                              "",
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
                                                      "country":
                                                          _selectedCorporateCountryName,
                                                    }
                                                  };
                                                  print(body);
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
                                                        corporateMobileController
                                                            .dispose();
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
                                                  LanguageService.getTranslated(
                                                      context,
                                                      'usermanagement_save_act_btn'),
                                                  style: typography.ButtonLarge,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 22, vertical: 8),
                                          ),
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
                                                'usermanagement_cancel_btn'),
                                            style: typography.ButtonLarge,
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

  List<CorporateAdmins> filteredAdmins = [];
  CorporateAdmins? _selectedUser;
  TextEditingController _userSearchController = TextEditingController();

  _editCompany({bool isView = false}) {
    var typography = CustomTypography(context);
    List<CorporateAdmins> filteredAdmins = [];
    CorporateAdmins? _selectedUser;
    TextEditingController _userSearchController = TextEditingController();

    // Add Company
    return Consumer<CompanyProvider>(
        builder: (context, companyProvider, child) {
      return companyProvider.isLoading
          ? const Center(
              child: SizedBox(
                  width: 25, height: 25, child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: Card(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.only(
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
                              Text(
                                  isView
                                      ? LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_view_company_title_text')
                                      : LanguageService.getTranslated(context,
                                          'usermanagement_app_corporate_edit_company_title_text'),
                                  style: typography.H7.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black)),
                              SizedBox(
                                height: CustomSpacing.four,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                        isView
                                            ? LanguageService.getTranslated(
                                                context,
                                                'usermanagement_app_corporate_view_company_description_text')
                                            : LanguageService.getTranslated(
                                                context,
                                                'usermanagement_app_corporate_edit_company_description_text'),
                                        style: typography.Body2),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: CustomSpacing.three,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
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
                                    companyImageUrl == null ||
                                            companyImageUrl == ''
                                        ? const CircleAvatar(
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
                                    !showEditCorporate
                                        ? const SizedBox()
                                        : Column(
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
                                                    typography.Body1.copyWith(
                                                        color: Colors.white),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                height: CustomSpacing.two,
                                              ),
                                              Text(
                                                "Min 400x400px\nPNG or JPEG",
                                                style: typography
                                                    .BottomNavigationActiveLabel,
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                height: CustomSpacing.two,
                                              ),
                                              // Add button
                                              Consumer<CompanyProvider>(builder:
                                                  (_, companyProvider, child) {
                                                return companyProvider
                                                        .isImageUploadLoading
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      )
                                                    : CustomButton(
                                                        type: ButtonType.filled,
                                                        onPressed: () {
                                                          // Show image picker
                                                          ImagePicker()
                                                              .pickImage(
                                                                  source:
                                                                      ImageSource
                                                                          .gallery)
                                                              .then((value) {
                                                            if (value != null) {
                                                              // Handle image upload
                                                              File v = File(
                                                                  value.path);
                                                              Provider.of<CompanyProvider>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .uploadImage(
                                                                      context,
                                                                      v)
                                                                  .then(
                                                                      (value) {
                                                                if (value !=
                                                                    '') {
                                                                  // Handle image upload response
                                                                  setState(() {
                                                                    companyImageUrl =
                                                                        value;
                                                                  });
                                                                }
                                                              });
                                                            }
                                                          });
                                                        },
                                                        child: Text(
                                                          "Upload Image",
                                                          style: typography
                                                              .ButtonLarge,
                                                          textAlign:
                                                              TextAlign.center,
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
                                    // Corporate Country just show flag and country name
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: CountryPickerFlagName(
                                            onCountryChange:
                                                null /*isView?null:(country) {
                                        setState(() {
                                          _selectedCorporateCountryName = country.name;
                                        });
                                      }*/
                                            ,
                                            initialValue:
                                                country_picker.Country(
                                              phoneCode: '1',
                                              countryCode: getCountryCodeFromName(
                                                      _selectedCorporateCountryName) ??
                                                  "",
                                              e164Sc: 1,
                                              geographic: true,
                                              level: 1,
                                              name:
                                                  _selectedCorporateCountryName,
                                              example: '',
                                              displayName: '',
                                              displayNameNoCountryCode: '',
                                              e164Key: '',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: CustomSpacing.six),
                                    // Company Type
                                    Consumer<CompanyProvider>(
                                        builder: (_, companyProvider, child) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField(
                                              value: selectedCompanyType?.type,
                                              decoration: InputDecoration(
                                                labelText: LanguageService
                                                    .getTranslated(context,
                                                        'usermanagement_company type_label'),
                                                labelStyle: typography.Body1,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  child: Text(
                                                    selectedCompanyType?.name ??
                                                        "",
                                                    style: typography.Body1,
                                                  ),
                                                  value:
                                                      selectedCompanyType?.type,
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            LanguageService.getTranslated(
                                                context,
                                                'usermanagement_domain_check'),
                                            style: typography.Body1,
                                          ),
                                          Switch(
                                            value: _enableDomainCheck,
                                            onChanged: !showEditCorporate
                                                ? (value) {}
                                                : (value) {
                                                    // Handle switch value change
                                                    setState(() {
                                                      _enableDomainCheck =
                                                          value;
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
                                                readOnly: !showEditCorporate,
                                                controller:
                                                    _domainListController,
                                                decoration: InputDecoration(
                                                  labelText: LanguageService
                                                      .getTranslated(context,
                                                          'usermanagement_domainname_list'),
                                                  labelStyle: typography.Body1,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                maxLines: 3,
                                                validator: (value) {
                                                  if (value == "" ||
                                                      !RegExp(r'@(?:[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)(?:,@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)*')
                                                          .hasMatch(value!)) {
                                                    return LanguageService
                                                        .getTranslated(context,
                                                            'usermanagement_domainname_list_error');
                                                  }
                                                  return null;
                                                },
                                              ),
                                              SizedBox(
                                                  height: CustomSpacing.four),
                                            ],
                                          )
                                        : const SizedBox(),
                                    // Company Legal Name
                                    TextFormField(
                                      readOnly: true,
                                      controller: _companyLegalNameController,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            'usermanagement_company_name_field_label'),
                                        labelStyle: typography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == "") {
                                          return LanguageService.getTranslated(
                                              context,
                                              'usermanagement_company_name_field_label_error');
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    // Company Display Name
                                    TextFormField(
                                      readOnly: !showEditCorporate,
                                      controller: _companyDisplayNameController,
                                      decoration: InputDecoration(
                                        labelText:
                                            LanguageService.getTranslated(
                                                context,
                                                'usermanagement_display_label'),
                                        labelStyle: typography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        // can be empty but if not empty, should not have digits
                                        if (value != null &&
                                            value != "" &&
                                            RegExp(r'[0-9]').hasMatch(value)) {
                                          return LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_corporate_display_name_validator');
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    // User & Role(s) divider

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          LanguageService.getTranslated(context,
                                              'usermanagement_users&roles_field_label'),
                                          style: typography.Subtitle1.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface),
                                        ),
                                        SizedBox(width: CustomSpacing.three),
                                        Expanded(
                                          child: Divider(
                                            thickness: 1,
                                            color: Colors.white.withOpacity(
                                                0.11999999731779099),
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
                                              labelText:
                                                  LanguageService.getTranslated(
                                                      context,
                                                      'usermanagement_roles_label'),
                                              /*hintText: _selectedRoles.isEmpty
                                              ? 'Select Roles'
                                              : "",*/
                                              border:
                                                  const OutlineInputBorder(),
                                              suffixIcon: const IconButton(
                                                icon:
                                                    Icon(Icons.arrow_drop_down),
                                                onPressed: null,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4.0,
                                            left: 10.0,
                                            right: 10.0,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  right: 32.0),
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children:
                                                      selectedCorporateTypeRole
                                                          .map(
                                                            (value) => Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          8.0),
                                                              child: Chip(
                                                                label: Text(
                                                                    value.name ??
                                                                        ''),
                                                                deleteIcon:
                                                                    const Icon(Icons
                                                                        .cancel),
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
                                    if (isPgAdmin) ...[
                                      SizedBox(height: CustomSpacing.four),
                                      DropdownButtonFormField2<CorporateAdmins>(
                                        decoration: InputDecoration(
                                          labelText: 'Select Admin',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        value: _selectedUser,
                                        items: companyProvider.company.admins!
                                            .map(
                                              (admin) => DropdownMenuItem<
                                                  CorporateAdmins>(
                                                value: admin,
                                                child: SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      94,
                                                  child: ListTile(
                                                    leading: admin.imageUrl !=
                                                                null &&
                                                            admin.imageUrl!
                                                                .isNotEmpty
                                                        ? CircleAvatar(
                                                            backgroundImage:
                                                                NetworkImage(admin
                                                                    .imageUrl!),
                                                          )
                                                        : CircleAvatar(
                                                            child: Text(admin
                                                                .name![0]
                                                                .toUpperCase()),
                                                          ),
                                                    title: Text(admin.name!),
                                                    subtitle:
                                                        Text(admin.email!),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (selectedAdmin) {
                                          setState(() {
                                            _selectedUser = selectedAdmin;
                                            // Autofill fields based on selection
                                            if (selectedAdmin != null) {
                                              _adminNameController.text =
                                                  selectedAdmin.name!;
                                              _adminDisplayNameController.text =
                                                  selectedAdmin.displayName!;
                                              _adminEmailController.text =
                                                  selectedAdmin.email!;
                                              _selectedCountryCode =
                                                  (selectedAdmin.countryCode ??
                                                          "")
                                                      .replaceAll("+", "");
                                              corporateEditMobileController
                                                  .value = PhoneNumber(
                                                isoCode: countryCodeToIsoCode[
                                                            _selectedCountryCode]
                                                        ?.first ??
                                                    IsoCode.US,
                                                nsn: selectedAdmin.mobile ?? "",
                                              );
                                            }
                                          });
                                        },
                                        // Custom appearance for the selected item
                                        selectedItemBuilder: (context) {
                                          return companyProvider.company.admins!
                                              .map((admin) => Text(
                                                    '${admin.name} (${admin.email})',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ))
                                              .toList();
                                        },
                                        // Adjust button and dropdown dimensions
                                        buttonStyleData: ButtonStyleData(
                                          height: 50,
                                          width:
                                              200, // Adjust the width of the button
                                        ),
                                        dropdownStyleData: DropdownStyleData(
                                          maxHeight: 300,
                                          // Set the max height for the dropdown
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                          ),
                                        ),
                                        menuItemStyleData: MenuItemStyleData(
                                          height:
                                              60, // Height of each menu item
                                        ),
                                      ),
                                    ],

                                    SizedBox(height: CustomSpacing.four),
                                    // Name
                                    TextFormField(
                                      readOnly: true,
                                      controller: _adminNameController,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            'usermanagement_name_field_label'),
                                        labelStyle: typography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == "") {
                                          return LanguageService.getTranslated(
                                              context,
                                              'usermanagement_name_field_label_error');
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
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            'usermanagement_display_name_field_label'),
                                        labelStyle: typography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        // can be empty but if not empty, should not have digits
                                        if (value != null &&
                                            value != "" &&
                                            RegExp(r'[0-9]').hasMatch(value)) {
                                          return LanguageService.getTranslated(
                                              context,
                                              'usermanagement_app_corporate_display_name_validator');
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: CustomSpacing.four),

                                    // Phone
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PhoneInput(
                                            enabled: false,
                                            key: const Key('phone-field'),
                                            controller:
                                                corporateEditMobileController,
                                            shouldFormat: true,
                                            defaultCountry: IsoCode.US,
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "register_mobile_number"),
                                              hintText:
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "register_non_corporate_mobilefield_placeholder"),
                                              border:
                                                  const OutlineInputBorder(),
                                              counterText: '',
                                            ),
                                            countrySelectorNavigator:
                                                const CountrySelectorNavigator
                                                    .dialog(
                                              showSearchInput: true,
                                              searchInputDecoration:
                                                  InputDecoration(
                                                hintText: 'Search Country',
                                              ),
                                            ),
                                            showFlagInInput: true,
                                            flagShape: BoxShape.circle,
                                            flagSize: 35,
                                            onChanged: (PhoneNumber? p) {
                                              if (p == null) {
                                                return;
                                              }
                                              setState(() {
                                                _selectedCountryCode =
                                                    p.countryCode;
                                              });
                                              print('changed ${p.countryCode}');
                                            },
                                            onSaved: (PhoneNumber? p) {
                                              if (p == null) {
                                                return;
                                              }
                                              setState(() {
                                                _selectedCountryCode =
                                                    p.countryCode;
                                              });
                                              print('changed ${p.countryCode}');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    // Email
                                    TextFormField(
                                      readOnly: true,
                                      controller: _adminEmailController,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            'usermanagement_email_field_label'),
                                        labelStyle: typography.Body1,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty ||
                                            regextest(value) == false) {
                                          return LanguageService.getTranslated(
                                              context,
                                              'usermanagement_email_placeholder');
                                        }
                                        // You can add more specific email validation here if needed
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: CustomSpacing.four),
                                    // Cancel and Submit Buttons
                                    !showEditCorporate
                                        ? const SizedBox()
                                        : Consumer<CompanyProvider>(builder:
                                            (_, companyProvider, child) {
                                            return Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          companyProvider
                                                                  .isLoading
                                                              ? const Center(
                                                                  child:
                                                                      SizedBox(
                                                                  width: 20,
                                                                  height: 20,
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ))
                                                              : CustomButton(
                                                                  type: ButtonType
                                                                      .filled,
                                                                  onPressed:
                                                                      () {
                                                                    {
                                                                      if (!_createCompanyFormKey
                                                                          .currentState!
                                                                          .validate()) {
                                                                        return;
                                                                      }
                                                                      // validate
                                                                      if (_adminNameController.text.isEmpty ||
                                                                          _adminEmailController
                                                                              .text
                                                                              .isEmpty ||
                                                                          _companyLegalNameController
                                                                              .text
                                                                              .isEmpty ||
                                                                          selectedCompanyType ==
                                                                              null ||
                                                                          selectedCorporateTypeRole
                                                                              .isEmpty) {
                                                                        // Show snackbar with name of field empty
                                                                        if (_adminNameController
                                                                            .text
                                                                            .isEmpty) {
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('User Name cannot be empty', style: typography.Body1),
                                                                            ),
                                                                          );
                                                                        } else if (_adminEmailController
                                                                            .text
                                                                            .isEmpty) {
                                                                          // check regex for email
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('User Email cannot be empty', style: typography.Body1),
                                                                            ),
                                                                          );
                                                                        } else if (_companyLegalNameController
                                                                            .text
                                                                            .isEmpty) {
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Company Legal Name cannot be empty', style: typography.Body1),
                                                                            ),
                                                                          );
                                                                        } else if (selectedCompanyType ==
                                                                            null) {
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Company Type cannot be empty', style: typography.Body1),
                                                                            ),
                                                                          );
                                                                        } else if (selectedCorporateTypeRole
                                                                            .isEmpty) {
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Role(s) cannot be empty', style: typography.Body1),
                                                                            ),
                                                                          );
                                                                        }
                                                                        return;
                                                                      }
                                                                      // Edit body

                                                                      Map<String,
                                                                              dynamic>
                                                                          body =
                                                                          {};
                                                                      if (_selectedUser !=
                                                                              null &&
                                                                          isPgAdmin) {
                                                                        body = {
                                                                          "action":
                                                                              "",
                                                                          "userdata":
                                                                              {
                                                                            "company_id":
                                                                                companyProvider.company.id,
                                                                            "id":
                                                                                companyProvider.company.id,
                                                                            "company_name":
                                                                                _companyLegalNameController.text,
                                                                            "company_display_name":
                                                                                _companyDisplayNameController.text,
                                                                            "enable_domain_check":
                                                                                _enableDomainCheck,
                                                                            "domain_list":
                                                                                _domainListController.text.split(','),
                                                                            "display_image_url":
                                                                                companyImageUrl,
                                                                            "selected_admin_id":
                                                                                _selectedUser?.userId ?? "",
                                                                          }
                                                                        };
                                                                      } else {
                                                                        Map<String,
                                                                                dynamic>
                                                                            body =
                                                                            {
                                                                          "action":
                                                                              "",
                                                                          "userdata":
                                                                              {
                                                                            "company_id":
                                                                                companyProvider.company.id,
                                                                            "id":
                                                                                companyProvider.company.id,
                                                                            "company_name":
                                                                                _companyLegalNameController.text,
                                                                            "company_display_name":
                                                                                _companyDisplayNameController.text,
                                                                            "enable_domain_check":
                                                                                _enableDomainCheck,
                                                                            "domain_list":
                                                                                _domainListController.text.split(','),
                                                                            "display_image_url":
                                                                                companyImageUrl,
                                                                          }
                                                                        };
                                                                      }
                                                                      companyProvider
                                                                          .updateCompany(
                                                                              context,
                                                                              body)
                                                                          .then(
                                                                              (value) {
                                                                        if (value) {
                                                                          // Handle success
                                                                          WidgetsBinding
                                                                              .instance
                                                                              .addPostFrameCallback((_) {
                                                                            setState(() {
                                                                              _selectedScreen = Screens.corporateList;
                                                                              clearFilters();
                                                                            });
                                                                            //Clear all fields
                                                                            _adminNameController.clear();
                                                                            _adminDisplayNameController.clear();
                                                                            _adminEmailController.clear();
                                                                            corporateEditMobileController.reset();
                                                                            _companyLegalNameController.clear();
                                                                            _companyDisplayNameController.clear();
                                                                            _domainListController.clear();
                                                                            _selectedRoles.clear();
                                                                            _textEditingController.clear();
                                                                            selectedCorporateTypeRole.clear();
                                                                            companyImageUrl =
                                                                                '';

                                                                            // get data to update the list

                                                                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const UserManagementScreen()));
                                                                          });
                                                                        }
                                                                      });
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        'usermanagement_save_act_btn'),
                                                                    style: typography
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
                                                                Screens
                                                                    .corporateList;
                                                            clearFilters();
                                                          });
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      22,
                                                                  vertical: 8),
                                                        ),
                                                        child: Text(
                                                          LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  'usermanagement_cancel_btn'),
                                                          style: typography
                                                              .ButtonLarge,
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
    });
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
    var typography = CustomTypography(context);
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: const EdgeInsets.only(top: 0.0, bottom: 8),
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
                      : const SizedBox(),
                  CircleAvatar(
                    child: (corporateProvider.employeeList?[index]
                                .displayImageUrl?.isNotEmpty ??
                            false)
                        ? ClipOval(
                            child: SizedBox.expand(
                              // Add this to make image fill the circle
                              child: Image.network(
                                corporateProvider
                                    .employeeList![index].displayImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                  corporateProvider.employeeList?[index].name
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      "",
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
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
                          style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(corporateProvider.employeeList?[index].email ?? "",
                            style: typography.Caption),
                        Text(
                            corporateProvider.employeeList?[index].phone
                                    ?.toString() ??
                                "",
                            style: typography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  !showEnableDisableUser
                      ? const SizedBox()
                      : corporateProvider.isStatusLoading &&
                              selectedCompanyEmployeeListIndex == index
                          ? const Padding(
                              padding: EdgeInsets.only(top: 8.0, right: 8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Switch(
                              value: corporateProvider
                                      .employeeList?[index].status ??
                                  false,
                              onChanged: (value) {
                                print(corporateProvider
                                    .employeeList?[index].userId);
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
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
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
                                        .employeeList?[index].role ??
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    !showConnectionListUser
                        ? const SizedBox()
                        : TextButton.icon(
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
                            icon: const Icon(Icons.people),
                            label: Text('View Connections',
                                style: typography.Caption.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.white
                                        : AppColors.black)),
                          ),
                    const Spacer(),
                    !showEditUser
                        ? const SizedBox()
                        : corporateProvider.isEditViewEmployeeLoading &&
                                selectedCompanyEmployeeListIndex == index
                            ? Center(
                                child: Container(
                                    height: 20,
                                    width: 20,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: const CircularProgressIndicator()),
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                color: AppColors.primaryMain,
                                onPressed: () async {
                                  selectedCompanyEmployeeListIndex = index;
                                  String userId = corporateProvider
                                          .employeeList![index].userId ??
                                      '';
                                  await corporateProvider
                                      .viewCorporateUserEmployee(
                                          context, userId);
                                  log(corporateProvider.employees
                                      .toJson()
                                      .toString());
                                  companyImageUrl = corporateProvider
                                          .employees.displayImageUrl ??
                                      '';
                                  setState(() {
                                    corporateUserId = corporateProvider
                                        .employeeList![index].userId;
                                    _selectedScreen =
                                        Screens.corporateEmployeeEdit;
                                    clearFilters();
                                  });
                                },
                              ),
                    // Cannot delete self
                    !showDeleteUser ||
                            corporateProvider.employeeList?[index].userId ==
                                FirebaseAuth.instance.currentUser?.uid ||
                            corporateProvider
                                    .employeeList?[index].isSuperAdmin ==
                                true
                        ? const SizedBox()
                        : corporateProvider.isDeleteLoading &&
                                selectedCompanyEmployeeListIndex == index
                            ? Center(
                                child: Container(
                                    height: 20,
                                    width: 20,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: const CircularProgressIndicator()),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  selectedCompanyEmployeeListIndex = index;

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    // Important for full height or custom height
                                    backgroundColor: Colors.black,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) {
                                      final name = corporateProvider
                                              .employeeList?[index].name ??
                                          '';
                                      return SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                2.5,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 32, 24, 32),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Are you sure you want to delete "
                                                '$name?',
                                                style:
                                                    typography.Body1?.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Their data including Account, Sub-Account, SOV, and Location List, will be transferred to the assigned Admin.',
                                                style:
                                                    typography.Body1?.copyWith(
                                                  color: Colors.white70,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context); // Close sheet
                                                    corporateProvider
                                                        .deleteCompany(
                                                            context, [
                                                      corporateProvider
                                                              .employeeList?[
                                                                  index]
                                                              .userId ??
                                                          ''
                                                    ]).then((value) {
                                                      if (value) {
                                                        WidgetsBinding.instance
                                                            .addPostFrameCallback(
                                                                (_) {
                                                          setState(() {
                                                            corporateProvider
                                                                .employeeList
                                                                ?.removeAt(
                                                                    index);
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
                                                  child: const Text('Delete'),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    side: const BorderSide(
                                                        color: Colors.white24),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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

  _createCorporateUser() {
    var typography = CustomTypography(context);
    // Add Corporate User
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
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
                    Text(
                        LanguageService.getTranslated(
                            context, 'usermanagemet_cuser_create_titile'),
                        style: typography.Body1),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Text(
                        LanguageService.getTranslated(context,
                            'usermanagement_cuser_create_title_description'),
                        style: typography.Body2),
                    SizedBox(
                      height: CustomSpacing.six,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // If company image is not uploaded, show default image
                    employeeImageUrl == ''
                        ? const CircleAvatar(
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
                          LanguageService.getTranslated(context,
                              'usermanagement_app_corporate_create_image_text'),
                          style: typography.Body1.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                        Text(
                          LanguageService.getTranslated(
                              context, 'usermanagement_app_image_size'),
                          style: typography.BottomNavigationActiveLabel,
                          textAlign: TextAlign.center,
                        ),
                        // Add button
                        Consumer<EmployeeProvider>(
                            builder: (_, employeeProvider, child) {
                          return employeeProvider.isImageUploadLoading
                              ? const Center(
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
                                    LanguageService.getTranslated(context,
                                        'usermanagement_cuser_upload_image_btn'),
                                    style: typography.ButtonLarge,
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
                        labelText: LanguageService.getTranslated(
                            context, 'usermanagement_cuser_trow_name_label'),
                        labelStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == "") {
                          return LanguageService.getTranslated(context,
                              'usermanagement_cuser_trow_name_label_error');
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    TextFormField(
                      controller: _employeeDisplayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == "") {
                          return 'Display name is required';
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
                        return Stack(
                          children: [
                            TextField(
                              readOnly: true,
                              onTap: () async {
                                await _fetchRoles();
                                _openBottomSheet(context);
                              },
                              controller: _textEditingController,
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(
                                    context,
                                    'usermanagement_cuser_roles_label'),
                                hintText: _selectedRoles.isEmpty
                                    ? 'Select Roles'
                                    : "",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () async {
                                    await _fetchRoles();
                                    _openBottomSheet(context);
                                  },
                                ),
                              ),
                            ),
                            if (_isLoading)
                              Positioned.fill(
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                            Positioned(
                              top: 8.0,
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
                                                  label: Text(value.name ?? ''),
                                                  deleteIcon:
                                                      const Icon(Icons.cancel),
                                                  onDeleted: () =>
                                                      _removeCorporateChip(
                                                          value),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ))),
                            ),
                          ],
                        );
                      },
                    ),
                    // Consumer<CorporateProvider>(
                    //     builder: (_, employeeProvider, child) {
                    //   print(
                    //       'Selected Employee Type: $selectedCorporateTypeRole');
                    //   return Stack(
                    //     children: [
                    //       TextField(
                    //         readOnly: true,
                    //         onTap: () {
                    //           List<companyType.Roles> roles = [];
                    //
                    //           if (employeeProvider.roles != null) {
                    //             employeeProvider.roles!.forEach((role) {
                    //               roles.add(companyType.Roles(
                    //                 isForIndividual: role.isForIndividual,
                    //                 isMultipleRoleEnabled: role.isMultipleRoleEnabled,
                    //                 isApplicableForTrial: role.isApplicableForTrial,
                    //                 name: role.name,
                    //                 role: role.role,
                    //                 isApplicableForInternal: role.isApplicableForInternal,
                    //                 status: role.status,
                    //               ));
                    //             });
                    //           }
                    //
                    //           // Print roles
                    //           if (roles.isEmpty) {
                    //             print("No roles found!");
                    //           } else {
                    //             for (var role in roles) {
                    //               print("Role: ${role.name}, Status: ${role.status}");
                    //             }
                    //           }
                    //         },
                    //
                    //         controller: _textEditingController,
                    //         onChanged: (value) {
                    //           // Handle input changes
                    //         },
                    //         decoration: InputDecoration(
                    //           labelText: LanguageService.getTranslated(
                    //               context, 'usermanagement_cuser_roles_label'),
                    //           hintText:
                    //               _selectedRoles.isEmpty ? 'Select Roles' : "",
                    //           border: const OutlineInputBorder(),
                    //           suffixIcon: IconButton(
                    //             icon: const Icon(Icons.arrow_drop_down),
                    //             onPressed: () {
                    //               showModalBottomSheet(
                    //                 context: context,
                    //                 useSafeArea: true,
                    //                 isScrollControlled: true,
                    //                 builder: (BuildContext context) {
                    //                   List<companyType.Roles> roles = [];
                    //
                    //                   if (employeeProvider.roles != null) {
                    //                     employeeProvider.roles!.forEach((role) {
                    //                       roles.add(companyType.Roles(
                    //                         isForIndividual:
                    //                             role.isForIndividual,
                    //                         isMultipleRoleEnabled:
                    //                             role.isMultipleRoleEnabled,
                    //                         isApplicableForTrial:
                    //                             role.isApplicableForTrial,
                    //                         name: role.name,
                    //                         role: role.role,
                    //                         isApplicableForInternal:
                    //                             role.isApplicableForInternal,
                    //                         status: role.status,
                    //                       ));
                    //                     });
                    //                   }
                    //                   return CorporateTypeRolesBottomSheet(
                    //                     selectedRoles:
                    //                         selectedCorporateTypeRole,
                    //                     addChip: _addCorporateChip,
                    //                     removeChip: _removeCorporateChip,
                    //                     removeAllChips:
                    //                         _removeAllCorporateChips,
                    //                     roles: roles,
                    //                     isEnabled: true,
                    //                   );
                    //                 },
                    //               );
                    //             },
                    //           ),
                    //         ),
                    //       ),
                    //       Positioned(
                    //         top: 10.0,
                    //         left: 10.0,
                    //         right: 10.0,
                    //         child: Container(
                    //           margin: const EdgeInsets.only(right: 32.0),
                    //           child: SingleChildScrollView(
                    //             scrollDirection: Axis.horizontal,
                    //             child: Row(
                    //               children: selectedCorporateTypeRole
                    //                   .map(
                    //                     (value) => Padding(
                    //                       padding:
                    //                           const EdgeInsets.only(right: 8.0),
                    //                       child: Chip(
                    //                         label: Text(value.name ?? ''),
                    //                         deleteIcon:
                    //                             const Icon(Icons.cancel),
                    //                         onDeleted: () =>
                    //                             _removeCorporateChip(value),
                    //                       ),
                    //                     ),
                    //                   )
                    //                   .toList(),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   );
                    // }),

                    SizedBox(
                      height: CustomSpacing.four,
                    ),
                    // Email
                    TextFormField(
                      readOnly: false,
                      controller: _employeeEmailController,
                      decoration: InputDecoration(
                        labelText: LanguageService.getTranslated(
                            context, 'usermanagement_cuser_email_label'),
                        labelStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            regextest(value) == false) {
                          return LanguageService.getTranslated(
                              context, 'usermanagement_cuser_email_validator');
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
                          child: PhoneInput(
                            key: const Key('phone-field-employee'),
                            controller: corporateEmployeeMobileController,
                            shouldFormat: true,
                            defaultCountry: IsoCode.US,
                            decoration: InputDecoration(
                              labelText: LanguageService.getTranslated(
                                  context, "register_mobile_number"),
                              hintText: LanguageService.getTranslated(context,
                                  "register_non_corporate_mobilefield_placeholder"),
                              border: const OutlineInputBorder(),
                              counterText: '',
                            ),
                            countrySelectorNavigator:
                                const CountrySelectorNavigator.dialog(
                              showSearchInput: true,
                              searchInputDecoration: InputDecoration(
                                hintText: 'Search Country',
                              ),
                            ),
                            showFlagInInput: true,
                            flagShape: BoxShape.circle,
                            flagSize: 35,
                            onChanged: (PhoneNumber? p) {
                              if (p == null) {
                                return;
                              }
                              setState(() {
                                _selectedCountryCode = p.countryCode;
                              });
                              if (kDebugMode) {
                                print('changed ${p.countryCode}');
                              }
                            },
                            onSaved: (PhoneNumber? p) {
                              if (p == null) {
                                return;
                              }
                              setState(() {
                                _selectedCountryCode = p.countryCode;
                              });
                              if (kDebugMode) {
                                print('changed ${p.countryCode}');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: CustomSpacing.six),
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
                                          child:
                                              const CircularProgressIndicator(),
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
                                            if (kDebugMode) {
                                              print("ASDF");
                                            }
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
                                                    corporateEmployeeMobileController
                                                            .value?.nsn ??
                                                        "",
                                                "country_code":
                                                    corporateEmployeeMobileController
                                                            .value
                                                            ?.countryCode ??
                                                        "",
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
                                                print("API Completed1");
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  setState(() {
                                                    _selectedScreen = Screens
                                                        .corporateEmployeeList;
                                                    clearFilters();
                                                  });
                                                  //Clear all fields
                                                  _employeeNameController
                                                      .clear();
                                                  _employeeDisplayNameController
                                                      .clear();
                                                  _employeeEmailController
                                                      .clear();
                                                  corporateEmployeeMobileController
                                                      .reset();
                                                  _selectedRoles.clear();
                                                  _textEditingController
                                                      .clear();
                                                  employeeImageUrl = '';
                                                });
                                              }
                                            });
                                          } else {
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
                                                    corporateEmployeeMobileController
                                                            .value?.nsn ??
                                                        "",

                                                "email":
                                                    _employeeEmailController
                                                        .text,
                                                "country_code":
                                                    corporateEmployeeMobileController
                                                            .value
                                                            ?.countryCode ??
                                                        "",
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
                                                print("API Completed2");
                                                Provider.of<CorporateProvider>(
                                                        context,
                                                        listen: false)
                                                    .getCorporateUserList(
                                                        context);
                                                // Handle success
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
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
                                                  corporateEmployeeMobileController
                                                      .reset();
                                                  createEmployeePhoneController
                                                      .reset();
                                                  selectedCorporateTypeRole
                                                      .clear();
                                                  setState(() {
                                                    _selectedScreen = Screens
                                                        .corporateEmployeeList;
                                                    clearFilters();
                                                  });
                                                });
                                              }
                                            });
                                          }
                                        },
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              'usermanagement_cuser_submit_btn'),
                                          style: typography.ButtonLarge,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 8),
                                ),
                                child: Text(
                                  LanguageService.getTranslated(context,
                                      'usermanagemet_cuser_cancel_btn'),
                                  style: typography.ButtonLarge,
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
    var typography = CustomTypography(context);
    CorporateProvider corporateProvider =
        Provider.of<CorporateProvider>(context, listen: false);
    return FutureBuilder<UsersCorporate>(
      future: corporateProvider.viewCorporateUserEmployee(context, employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading user data"));
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
          _selectedCountryCode =
              currentUser.countryCode?.replaceAll('+', '') ?? "1";
          print('Selected Country Code: $_selectedCountryCode');
          print('isoCode: ${countryCodeToIsoCode[_selectedCountryCode]}');
          print('number: ${currentUser.phone}');
          createEmployeePhoneController.value = PhoneNumber(
              nsn: currentUser.phone ?? '',
              isoCode: countryCodeToIsoCode[_selectedCountryCode]?.first ??
                  IsoCode.US);
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
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
                          Text(
                              LanguageService.getTranslated(
                                  context, 'usermanagement_cuser_edit_title'),
                              style: typography.Body1),
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          Text(
                              LanguageService.getTranslated(context,
                                  'usermanagement_cuser_edit_title_description'),
                              style: typography.Body2),
                          SizedBox(
                            height: CustomSpacing.six,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // If company image is not uploaded, show default image
                          employeeImageUrl == null || employeeImageUrl == ''
                              ? const CircleAvatar(
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
                                LanguageService.getTranslated(context,
                                    'usermanagement_cuser_upload_image_label'),
                                style: typography.Body1.copyWith(
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: CustomSpacing.two,
                              ),
                              Text(
                                LanguageService.getTranslated(
                                    context, 'usermanagement_app_image_size'),
                                style: typography.BottomNavigationActiveLabel,
                                textAlign: TextAlign.center,
                              ),
                              // Add button
                              Consumer<CorporateProvider>(
                                  builder: (_, corporateProvider, child) {
                                return corporateProvider
                                        .isEditViewEmployeeLoading
                                    ? const Center(
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
                                          LanguageService.getTranslated(context,
                                              'usermanagement_cuser_upload_image_btn'),
                                          style: typography.ButtonLarge,
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
                              labelText: LanguageService.getTranslated(context,
                                  'usermanagement_cuser_trow_name_label'),
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == "") {
                                return LanguageService.getTranslated(context,
                                    'usermanagement_cuser_trow_name_label_error');
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
                                    labelText: LanguageService.getTranslated(
                                        context,
                                        'usermanagement_cuser_roles_label'),
                                    hintText: _selectedRoles.isEmpty
                                        ? LanguageService.getTranslated(context,
                                            'usermanagement_cuser_roles_hint')
                                        : "",
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.arrow_drop_down),
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
                                  top: 4.0,
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
                                                  label: Text(value.name ?? ''),
                                                  deleteIcon:
                                                      const Icon(Icons.cancel),
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
                          SizedBox(
                            height: CustomSpacing.four,
                          ),
                          // Email
                          TextFormField(
                            readOnly: true,
                            controller: _employeeEmailController,
                            decoration: InputDecoration(
                              labelText: LanguageService.getTranslated(
                                  context, 'usermanagement_cuser_email_label'),
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  regextest(value) == false) {
                                return LanguageService.getTranslated(context,
                                    'usermanagement_cuser_email_validator');
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
                                child: PhoneInput(
                                  key: const Key('phone-field-1'),
                                  controller: createEmployeePhoneController,
                                  shouldFormat: true,
                                  // set _selectedCountryCode to your country code if not null
                                  defaultCountry: IsoCode.US,
                                  decoration: InputDecoration(
                                    labelText: LanguageService.getTranslated(
                                        context,
                                        'usermanagement_cuser_trow_ph_number'),
                                    labelStyle: typography.Body1,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .color!,
                                      ),
                                    ),
                                    hintText: LanguageService.getTranslated(
                                        context,
                                        'usermanagement_cuser_trow_ph_number_placeholder'),
                                    border: const OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  countrySelectorNavigator:
                                      CountrySelectorNavigator.dialog(
                                    showSearchInput: true,
                                    searchInputDecoration: InputDecoration(
                                      hintText: 'Search Country',
                                    ),
                                  ),
                                  showFlagInInput: true,
                                  flagShape: BoxShape.circle,
                                  flagSize: 35,
                                  onChanged: (PhoneNumber? p) {
                                    if (p != null &&
                                        p.countryCode != _selectedCountryCode) {
                                      setState(() {
                                        _selectedCountryCode = p.countryCode;
                                      });
                                    }
                                  },
                                  onSaved: (PhoneNumber? p) {
                                    if (p != null &&
                                        p.countryCode != _selectedCountryCode) {
                                      setState(() {
                                        _selectedCountryCode = p.countryCode;
                                      });
                                    }
                                  },
                                  // onChanged: (PhoneNumber? p) {
                                  //   if (p == null) return;
                                  //   setState(() {
                                  //     _selectedCountryCode = p.countryCode;
                                  //   });
                                  //   print('changed ${p.countryCode}');
                                  // },
                                  // onSaved: (PhoneNumber? p) {
                                  //   if (p == null) return;
                                  //   setState(() {
                                  //     _selectedCountryCode = p.countryCode;
                                  //   });
                                  //   print('changed ${p.countryCode}');
                                  // },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: CustomSpacing.six),
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
                                                    const CircularProgressIndicator(),
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
                                                        createEmployeePhoneController
                                                                .value?.nsn ??
                                                            "",
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
                                                        createEmployeePhoneController
                                                                .value
                                                                ?.countryCode ??
                                                            "+1",
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
                                                        _selectedScreen = Screens
                                                            .corporateEmployeeList;
                                                        clearFilters();
                                                      });
                                                      //Clear all fields
                                                      _employeeNameController
                                                          .clear();
                                                      _employeeEmailController
                                                          .clear();
                                                      createEmployeePhoneController
                                                          .reset();
                                                      selectedCorporateTypeRole
                                                          .clear();
                                                      _textEditingController
                                                          .clear();
                                                      employeeImageUrl = '';
                                                    });
                                                  }
                                                });
                                              },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    'usermanagement_cuser_submit_btn'),
                                                style: typography.ButtonLarge,
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
                                        selectedCorporateTypeRole.clear();
                                        setState(() {
                                          _selectedScreen =
                                              Screens.corporateEmployeeList;
                                          clearFilters();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 8),
                                      ),
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagemet_cuser_cancel_btn'),
                                        style: typography.ButtonLarge,
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
          return const Center(child: Text("No user data available"));
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
    print(_selectedScreen);
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
    } else {
      return _corporateManagement();
    }
  }

  _getViewCompany() {
    return _editCompany(isView: true);
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
    var typography = CustomTypography(context);
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
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _nonCorporateSearchController,
                    onChanged: nonCorporateSearchClient,
                    decoration: InputDecoration(
                      hintText: LanguageService.getTranslated(context,
                          'usermanagement_search_field_lable_name_email_mobile'),
                      label: Text(
                          LanguageService.getTranslated(
                              context, "usermanagement_search_field_lable"),
                          style: typography.Body1),
                      hintStyle: typography.Body1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                child: const Icon(
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
                    LanguageService.getTranslated(
                        context, 'usermanagement_individual_users_all_tab'),
                    style: typography.BottomNavigationActiveLabel,
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
                        labelPadding: const EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          noncorporateProvider.allCount,
                          style:
                              typography.BottomNavigationActiveLabel.copyWith(
                                  height: -0.6),
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
                    LanguageService.getTranslated(
                        context, 'usermanagement_individual_users_active_tab'),
                    style: typography.BottomNavigationActiveLabel,
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
                        labelPadding: const EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          noncorporateProvider.activeCount,
                          style:
                              typography.BottomNavigationActiveLabel.copyWith(
                                  height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
          !showDeleteNonCorporate
              ? const SizedBox()
              : showCheckbox
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
                          Text(
                              LanguageService.getTranslated(context,
                                  "usermanagement_individual_users_select_all"),
                              style: typography.Body1),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Handle delete selected companies
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagement_individual_users_bulk_delete_dialog_title'),
                                        style: typography.H7),
                                    content: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagement_individual_users_bulk_delete_dialog_description'),
                                        style: typography.Body2),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(LanguageService.getTranslated(
                                            context,
                                            'usermanagement_individual_users_bulk_delete_dialog_cancel')),
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
                                                      .map(
                                                          (e) => e.userId ?? '')
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
                                        child: Text(LanguageService.getTranslated(
                                            context,
                                            'usermanagement_individual_users_bulk_delete_dialog_delete')),
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
                  : const SizedBox(),
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
                          builder: (context, nonCorporateProvider, child) {
                            return nonCorporateProvider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : nonCorporateProvider.employeeList!.isEmpty
                                    ? Center(
                                        child: Text(
                                          LanguageService.getTranslated(
                                            context,
                                            "usermanagement_individual_users_empty_list_text",
                                          ),
                                          style: typography.Body1,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: nonCorporateProvider
                                            .employeeList!.length,
                                        itemBuilder: (context, index) {
                                          if (index ==
                                              nonCorporateProvider
                                                      .employeeList!.length -
                                                  1) {
                                            // Check if it's the last item
                                            if (nonCorporateProvider
                                                .isNextPageLoading) {
                                              // Display loading indicator
                                              return const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            } else if (nonCorporateProvider
                                                        .page >=
                                                    nonCorporateProvider
                                                        .totalPages &&
                                                nonCorporateProvider
                                                    .employeeList!.isNotEmpty) {
                                              // End of list message
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Text(
                                                    'End of the list',
                                                    style: typography.Body1,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Fetch next page
                                              nonCorporateProvider.page += 1;
                                              nonCorporateProvider
                                                  .getNonCorporateUserList(
                                                context,
                                                searchText: "",
                                                roleFilter: "",
                                                isSearch: false,
                                              );
                                              return const SizedBox();
                                            }
                                          }
                                          return _nonCorporateListItem(
                                              index, nonCorporateProvider);
                                        },
                                      );
                          },
                        ),
                        // Active Tab
                        Consumer<NonCorporateProvider>(
                          builder: (context, nonCorporateProvider, child) {
                            return nonCorporateProvider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : nonCorporateProvider.employeeList!.isEmpty
                                    ? Center(
                                        child: Text(
                                          LanguageService.getTranslated(
                                            context,
                                            "usermanagement_individual_users_empty_list_text",
                                          ),
                                          style: typography.Body1,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: nonCorporateProvider
                                            .employeeList!.length,
                                        itemBuilder: (context, index) {
                                          if (index ==
                                              nonCorporateProvider
                                                      .employeeList!.length -
                                                  1) {
                                            // Check if it's the last item
                                            if (nonCorporateProvider
                                                .isNextPageLoading) {
                                              // Display loading indicator
                                              return const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            } else if (nonCorporateProvider
                                                        .page >=
                                                    nonCorporateProvider
                                                        .totalPages &&
                                                nonCorporateProvider
                                                    .employeeList!.isNotEmpty) {
                                              // End of list message
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Text(
                                                    'End of the list',
                                                    style: typography.Body1,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Fetch next page
                                              nonCorporateProvider.page += 1;
                                              nonCorporateProvider
                                                  .getNonCorporateUserList(
                                                context,
                                                searchText: "",
                                                roleFilter: "",
                                                isSearch: false,
                                              );
                                              return const SizedBox();
                                            }
                                          }
                                          return _nonCorporateListItem(
                                              index, nonCorporateProvider);
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
        ],
      );
    });
  }

  _nonCorporateListItem(int index, NonCorporateProvider nonCorporateProvider) {
    var typography = CustomTypography(context);
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: const EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: !showDeleteNonCorporate
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
                  !showDeleteNonCorporate
                      ? const SizedBox()
                      : showCheckbox
                          ? Checkbox(
                              value: nonCorporateProvider
                                  .employeeList![index].isSelected!,
                              onChanged: (value) {
                                // Handle checkbox value change
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    nonCorporateProvider.employeeList![index]
                                        .isSelected = value;
                                  });
                                });
                              },
                            )
                          : const SizedBox(),
                  CircleAvatar(
                    child: nonCorporateProvider
                                    .employeeList![index].displayImageUrl !=
                                null &&
                            nonCorporateProvider.employeeList![index]
                                .displayImageUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              nonCorporateProvider
                                  .employeeList![index].displayImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            (nonCorporateProvider
                                            .employeeList![index].displayName ??
                                        "")
                                    .isNotEmpty
                                ? nonCorporateProvider
                                    .employeeList![index].displayName!
                                    .substring(0, 1)
                                    .toUpperCase()
                                : (nonCorporateProvider
                                                .employeeList![index].name ??
                                            "")
                                        .isNotEmpty
                                    ? nonCorporateProvider
                                        .employeeList![index].name!
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : "",
                            style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
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
                          (nonCorporateProvider
                                          .employeeList![index].displayName ??
                                      "")
                                  .isNotEmpty
                              ? nonCorporateProvider
                                      .employeeList![index].displayName!
                                      .substring(0, 1)
                                      .toUpperCase() +
                                  nonCorporateProvider
                                      .employeeList![index].displayName!
                                      .substring(1)
                              : (nonCorporateProvider
                                              .employeeList![index].name ??
                                          "")
                                      .isNotEmpty
                                  ? nonCorporateProvider
                                          .employeeList![index].name!
                                          .substring(0, 1)
                                          .toUpperCase() +
                                      nonCorporateProvider
                                          .employeeList![index].name!
                                          .substring(1)
                                  : "",
                          style: typography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                            nonCorporateProvider
                                    .employeeList![index].displayName ??
                                "",
                            style: typography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  !showEnableDisableNonCorporate
                      ? const SizedBox()
                      : nonCorporateProvider.isStatusLoading &&
                              selectedNonCorporateListIndex == index
                          ? const Padding(
                              padding: EdgeInsets.only(top: 8.0, right: 8.0),
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
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
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
                        style: typography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black),
                      ),
                      Text(
                          nonCorporateProvider.employeeList![index].displayName
                              .toString(),
                          // .admins?.email ?? '',
                          style: typography.Caption),
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    !showNonCorporateConnectionList
                        ? const SizedBox()
                        : TextButton.icon(
                            onPressed: () {
                              // Handle view connections
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ConnectionsScreen(
                                        userId: nonCorporateProvider
                                                .employeeList![index].userId ??
                                            '',
                                        userName: nonCorporateProvider
                                                .employeeList![index]
                                                .displayName ??
                                            '',
                                      )));
                            },
                            icon: const Icon(Icons.people),
                            label: Text('View Connections',
                                style: typography.Caption.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.white
                                        : AppColors.black)),
                          ),
                    const Spacer(),
                    !showEditNonCorporate
                        ? const SizedBox()
                        : nonCorporateProvider.isEditViewEmployeeLoading &&
                                selectedNonCorporateListIndex == index
                            ? Center(
                                child: Container(
                                    height: 20,
                                    width: 20,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: const CircularProgressIndicator()),
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit),
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
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete),
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
                                        style: typography.H6),
                                    content: Text(
                                        'Are you sure you want to delete ${nonCorporateProvider.employeeList![index].displayName}?',
                                        style: typography.Body1),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
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
                                        child: const Text('Delete'),
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
    var typography = CustomTypography(context);
    NonCorporateProvider nonCorporateProvider =
        Provider.of<NonCorporateProvider>(context, listen: false);
    return FutureBuilder<UsersCorporate>(
      future: nonCorporateProvider.viewNonCorporateUser(context, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text(LanguageService.getTranslated(
                  context, 'usermanagement_individual_user_error')));
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
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
                          Text(
                              LanguageService.getTranslated(context,
                                  'usermanagement_individual_user_edit_title'),
                              style: typography.Body1),
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          Text(
                              LanguageService.getTranslated(context,
                                  'usermanagement_individual_user_edit_description'),
                              style: typography.Body2),
                          SizedBox(
                            height: CustomSpacing.six,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // If company image is not uploaded, show default image
                          employeeImageUrl == null || employeeImageUrl == ''
                              ? const CircleAvatar(
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
                                LanguageService.getTranslated(context,
                                    'usermanagement_individual_user_upload_image_text'),
                                style: typography.Body1.copyWith(
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: CustomSpacing.two,
                              ),
                              Text(
                                LanguageService.getTranslated(
                                    context, 'usermanagement_app_image_size'),
                                style: typography.BottomNavigationActiveLabel,
                                textAlign: TextAlign.center,
                              ),
                              // Add button
                              Consumer<CorporateProvider>(
                                  builder: (_, corporateProvider, child) {
                                return corporateProvider
                                        .isEditViewEmployeeLoading
                                    ? const Center(
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
                                          LanguageService.getTranslated(context,
                                              'usermanagement_individual_user_upload_image_button_text'),
                                          style: typography.ButtonLarge,
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
                              labelText: LanguageService.getTranslated(context,
                                  'usermanagement_individual_user_edit_name_label'),
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == "") {
                                return LanguageService.getTranslated(context,
                                    'usermanagement_individual_user_edit_name_error');
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
                                    labelText: LanguageService.getTranslated(
                                        context,
                                        'usermanagement_individual_user_edit_role_label'),
                                    hintText: _selectedRoles.isEmpty
                                        ? 'Select Roles'
                                        : "",
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.arrow_drop_down),
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
                                  top: 4.0,
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
                                                    deleteIcon: const Icon(
                                                        Icons.cancel),
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
                              labelText: LanguageService.getTranslated(context,
                                  'usermanagement_individual_user_edit_email_label'),
                              labelStyle: typography.Body1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  regextest(value) == false) {
                                return LanguageService.getTranslated(context,
                                    'usermanagement_individual_user_edit_email_placeholder');
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
                                    child: Container(),
                                    // clp.CountryListPicker(
                                    //   initialCountry: Countries.Australia,
                                    //   // Ensure this is correctly set or dynamically assigned
                                    //   border: InputBorder.none,
                                    //   flagSize: const Size(35, 30),
                                    //   onChanged: (code) {
                                    //     // This is typically triggered when a new selection is made in the picker
                                    //     setState(() {
                                    //       _selectedCountryCode =
                                    //           code; // Maintaining a state variable for other uses
                                    //       _employeeCountryCodeController.text =
                                    //           code; // Update the controller
                                    //     });
                                    //   },
                                    //   diallingCodeStyle: typography.Body1,
                                    //   isShowInputField: false,
                                    //   dialogTheme: clp.DialogThemeData(
                                    //     style: typography.Body1,
                                    //     isShowFloatButton: false,
                                    //   ),
                                    //   countryNameStyle: typography.Body1,
                                    //   isShowCountryName: false,
                                    //   onCountryChanged: (country) {
                                    //     // This may be triggered based on specific implementations of CountryListPicker
                                    //     print(
                                    //         'This is the country code: $country');
                                    //     setState(() {
                                    //       _selectedCountryCode =
                                    //           country.dialing_code;
                                    //       _employeeCountryCodeController.text =
                                    //           country.dialing_code;
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
                                  controller: _employeeMobileController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  // Numeric keyboard
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                    // Only allows digits
                                  ],
                                  decoration: InputDecoration(
                                    labelText: LanguageService.getTranslated(
                                        context,
                                        'usermanagement_individual_user_edit_mobile_label'),
                                    hintText: 'Enter your mobile number',
                                    border: const OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                                      return LanguageService.getTranslated(
                                          context,
                                          'usermanagement_individual_user_edit_mobile_error');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: CustomSpacing.six),
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
                                                    const CircularProgressIndicator(),
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
                                                LanguageService.getTranslated(
                                                    context,
                                                    'usermanagement_individual_user_edit_submit_button'),
                                                style: typography.ButtonLarge,
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 8),
                                      ),
                                      child: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagement_individual_user_edit_cancel_button'),
                                        style: typography.ButtonLarge,
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
          return const Center(child: Text("No user data available"));
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
    var typography = CustomTypography(context);
    return Builder(builder: (context) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CustomSpacing.four,
          ),
          Text(
              LanguageService.getTranslated(
                  context, 'usermanagement_emp_management_title'),
              style: typography.Body1),
          SizedBox(
            height: CustomSpacing.two,
          ),
          Text(
              LanguageService.getTranslated(
                  context, 'usermanagement_emp_management_descrption'),
              style: typography.Body2),
          SizedBox(
            height: CustomSpacing.four,
          ),
          // Add Search and filter dropdown in a row
          Row(
            children: [
              Expanded(
                flex: 7,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _employeeSearchController,
                    onChanged: employeeSearchClient,
                    decoration: InputDecoration(
                      hintText: LanguageService.getTranslated(context,
                          'usermanagement_app_employee_management_phone_hint'),
                      label: Text(
                          LanguageService.getTranslated(context,
                              'usermanagement_app_employee_management_search_text'),
                          style: typography.Body1),
                      hintStyle: typography.Body1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                child: const Icon(
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
                    LanguageService.getTranslated(context,
                        'usermanagement_app_employee_management_all_tab_title'),
                    style: typography.BottomNavigationActiveLabel,
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
                        labelPadding: const EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          employeeProvider.allCount.toString(),
                          style:
                              typography.BottomNavigationActiveLabel.copyWith(
                                  height: -0.6),
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
                    LanguageService.getTranslated(context,
                        'usermanagement_app_employee_management_active_tab_title'),
                    style: typography.BottomNavigationActiveLabel,
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
                        labelPadding: const EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          employeeProvider.activeCount.toString(),
                          style:
                              typography.BottomNavigationActiveLabel.copyWith(
                                  height: -0.6),
                        ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
          !showDeleteEmployee
              ? const SizedBox()
              : showCheckbox
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
                          Text(
                              LanguageService.getTranslated(context,
                                  "usermanagement_app_employee_management_select_all_text"),
                              style: typography.Body1),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // Handle delete selected companies
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagement_app_employee_management_bulk_delete_dialog_title'),
                                        style: typography.H7),
                                    content: Text(
                                        LanguageService.getTranslated(context,
                                            'usermanagement_app_employee_management_bulk_delete_dialog_description'),
                                        style: typography.Body2),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(LanguageService.getTranslated(
                                            context,
                                            'usermanagement_app_employee_management_bulk_delete_dialog_cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          employeeProvider
                                              .deleteMultipleEmployees(
                                                  context,
                                                  (employeeProvider
                                                              .employeeList ??
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
                                                  (employeeProvider
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
                                        child: Text(LanguageService.getTranslated(
                                            context,
                                            'usermanagement_app_employee_management_bulk_delete_dialog_delete')),
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
                  : const SizedBox(),
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
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : employeeProvider.employeeList!.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No employees found',
                                          style: typography.Body1,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: employeeProvider
                                            .employeeList!.length,
                                        itemBuilder: (context, index) {
                                          if (index ==
                                              employeeProvider
                                                      .employeeList!.length -
                                                  1) {
                                            // Check if it's the last item
                                            if (employeeProvider
                                                .isNextPageLoading) {
                                              // Display loading indicator
                                              return const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            } else if (employeeProvider.page >=
                                                    employeeProvider
                                                        .totalPages &&
                                                employeeProvider
                                                    .employeeList!.isNotEmpty) {
                                              // Display end of list message
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Text(
                                                    'End of the list',
                                                    style: typography.Body1,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Trigger fetching the next page
                                              employeeProvider.page += 1;
                                              employeeProvider.getAllEmployees(
                                                context,
                                                searchText: "",
                                                // Pass appropriate parameters
                                                roleFilter: "",
                                                isSearch: false,
                                              );
                                              return const SizedBox();
                                            }
                                          }
                                          return _employeeManagementListItem(
                                              index, employeeProvider);
                                        },
                                      ),

                            // Active Tab
                            employeeProvider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : employeeProvider.employeeList!.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No employees found',
                                          style: typography.Body1,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: employeeProvider
                                            .employeeList!.length,
                                        itemBuilder: (context, index) {
                                          if (index ==
                                              employeeProvider
                                                      .employeeList!.length -
                                                  1) {
                                            // Check if it's the last item
                                            if (employeeProvider
                                                .isNextPageLoading) {
                                              // Display loading indicator
                                              return const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            } else if (employeeProvider.page >=
                                                    employeeProvider
                                                        .totalPages &&
                                                employeeProvider
                                                    .employeeList!.isNotEmpty) {
                                              // Display end of list message
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                  child: Text(
                                                    'End of the list',
                                                    style: typography.Body1,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Trigger fetching the next page
                                              employeeProvider.page += 1;
                                              employeeProvider.getAllEmployees(
                                                context,
                                                searchText: "",
                                                // Pass appropriate parameters
                                                roleFilter: "",
                                                isSearch: false,
                                              );
                                              return const SizedBox();
                                            }
                                          }
                                          return _employeeManagementListItem(
                                              index, employeeProvider);
                                        },
                                      ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  _employeeManagementListItem(int index, EmployeeProvider employeeProvider) {
    var typography = CustomTypography(context);
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Container(
      margin: const EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: !showDeleteEmployee
            ? null
            : () {
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
                  !showDeleteEmployee
                      ? const SizedBox()
                      : showCheckbox
                          ? Checkbox(
                              value: employeeProvider
                                  .employeeList?[index].isSelected!,
                              onChanged: (value) {
                                // Handle checkbox value change
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    employeeProvider.employeeList?[index]
                                        .isSelected = value!;
                                  });
                                });
                              },
                            )
                          : const SizedBox(),
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
                          style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(employeeProvider.employeeList?[index].email ?? "",
                            style: typography.Caption),
                        Text(employeeProvider.employeeList?[index].phone ?? "",
                            style: typography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  !showEnableDisableEmployee
                      ? const SizedBox()
                      : employeeProvider.isStatusLoading &&
                              selectedEmployeeListIndex == index
                          ? const Padding(
                              padding: EdgeInsets.only(top: 8.0, right: 8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Switch(
                              value: employeeProvider
                                      .employeeList?[index].status ??
                                  false,
                              onChanged: (value) {
                                // Handle switch value change
                                selectedEmployeeListIndex = index;
                                employeeProvider
                                    .changeEmployeeStatus(
                                        context,
                                        employeeProvider
                                                .employeeList?[index].id ??
                                            '',
                                        value)
                                    .then((value) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      employeeProvider
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with text
                    !showConnectionListEmployee
                        ? const SizedBox()
                        : TextButton.icon(
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
                            icon: const Icon(Icons.people),
                            label: Text('View Connections',
                                style: typography.Caption.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.white
                                        : AppColors.black)),
                          ),
                    const Spacer(),
                    !showEditEmployee
                        ? const SizedBox()
                        : employeeProvider.isEditViewEmployeeLoading &&
                                selectedEmployeeListIndex == index
                            ? Center(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 20,
                                  height: 20,
                                  child: const CircularProgressIndicator(),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                color: AppColors.primaryMain,
                                onPressed: () async {
                                  /// Handle edit company
                                  selectedEmployeeListIndex = index;
                                  await employeeProvider.viewEmployee(
                                      context,
                                      employeeProvider
                                              .employeeList?[index].id ??
                                          '');
                                  log(employeeProvider.employees
                                      .toJson()
                                      .toString());
                                  // Prefill values
                                  employeeImageUrl = employeeProvider
                                          .employees.displayImageUrl ??
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
                                                isApplicableForInternal: role
                                                    .isApplicableForInternal,
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
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator()),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete),
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
                                        style: typography.H6),
                                    content: Text(
                                        'Are you sure you want to delete ${employeeProvider.employeeList?[index].name}?',
                                        style: typography.Body1),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
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
                                        child: const Text('Delete'),
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

  Widget _createEmployee() {
    var typography = CustomTypography(context);
    // Add Employee
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
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
                    Text(
                        LanguageService.getTranslated(context,
                            "usermanagement_app_employee_create_account_title"),
                        style: typography.Body1),
                    SizedBox(
                      height: CustomSpacing.two,
                    ),
                    Text(
                        LanguageService.getTranslated(context,
                            'usermanagement_app_employee_create_account_description'),
                        style: typography.Body2),
                    SizedBox(
                      height: CustomSpacing.six,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // If company image is not uploaded, show default image
                    employeeImageUrl == null || employeeImageUrl == ''
                        ? const CircleAvatar(
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
                          LanguageService.getTranslated(
                              context, 'usermanagement_upload_image_txt'),
                          style: typography.Body1.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                        Text(
                          LanguageService.getTranslated(
                              context, 'usermanagement_app_image_size'),
                          style: typography.BottomNavigationActiveLabel,
                          textAlign: TextAlign.center,
                        ),
                        // Add button
                        Consumer<EmployeeProvider>(
                            builder: (_, employeeProvider, child) {
                          return employeeProvider.isImageUploadLoading
                              ? const Center(
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
                                    LanguageService.getTranslated(context,
                                        'usermanagement_upload_image_btn'),
                                    style: typography.ButtonLarge,
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
                        labelText: LanguageService.getTranslated(
                            context, 'usermanagement_name_field_label'),
                        labelStyle: typography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == "") {
                          return LanguageService.getTranslated(
                              context, 'usermanagement_name_field_label_error');
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
                              labelText: LanguageService.getTranslated(
                                  context, 'usermanagement_roles_label'),
                              hintText:
                                  _selectedRoles.isEmpty ? 'Select Roles' : "",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
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
                                            deleteIcon:
                                                const Icon(Icons.cancel),
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
                      readOnly: true,
                      keyboardType: TextInputType.emailAddress,
                      controller: _employeeEmailController,
                      decoration: InputDecoration(
                        labelText: LanguageService.getTranslated(
                            context, 'usermanagement_email_field_label'),
                        labelStyle: typography.Body1,
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
                            child: Container(),

                            //     Center(
                            //   child: clp.CountryListPicker(
                            //     initialCountry: Countries.United_States,
                            //     border: InputBorder.none,
                            //     flagSize: const Size(35, 30),
                            //     onChanged: (code) {
                            //       setState(() {
                            //         _selectedCountryCode = code;
                            //       });
                            //     },
                            //     diallingCodeStyle: typography.Body1,
                            //     isShowInputField: false,
                            //     dialogTheme: clp.DialogThemeData(
                            //       style: typography.Body1,
                            //       isShowFloatButton: false,
                            //     ),
                            //     countryNameStyle: typography.Body1,
                            //     isShowCountryName: false,
                            //     onCountryChanged: (country) {
                            //       print('This is the country code: $country');
                            //       setState(() {
                            //         _selectedCountryCode = country.dialing_code;
                            //       });
                            //     },
                            //   ),
                            // ),
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
                              labelText: LanguageService.getTranslated(context,
                                  'usermanagement_app_employee_create_account_mobile_label'),
                              hintText: LanguageService.getTranslated(context,
                                  'usermanagement_app_employee_create_account_mobile_placeholder'),
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
                    SizedBox(height: CustomSpacing.six),
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
                                          child:
                                              const CircularProgressIndicator(),
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
                                          LanguageService.getTranslated(context,
                                              'usermanagement_app_employee_create_account_submit'),
                                          style: typography.ButtonLarge,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 8),
                                ),
                                child: Text(
                                  LanguageService.getTranslated(context,
                                      'usermanagement_app_employee_create_account_cancel'),
                                  style: typography.ButtonLarge,
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

  _verificationRequestsUI() {
    var typography = CustomTypography(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.paperElavation25
              : AppColors.paperElavation25Light,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          )),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CustomSpacing.five,
          ),
          Text('Verification Requests', style: typography.H7),
          SizedBox(
            height: CustomSpacing.three,
          ),
          Text('Manage all accounts request from this panel',
              style: typography.Body2),
          SizedBox(
            height: CustomSpacing.two,
          ),
          // two tabs for Corporate verification and user verification
          TabBar(
            controller: _tabVerificationController,
            tabs: verificationTabsService.verificationTabs(context),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabVerificationController,
              children: [
                // Corporate Tab
                if (showCorporateVerificationTab)
                  RefreshIndicator(
                    onRefresh: _refreshCorporateRequests,
                    // onRefresh: () async {
                    //   Provider.of<VerificationProvider>(context, listen: false)
                    //       .getAllCorporateRequests(context);
                    // },
                    child: Column(
                      children: [
                        SizedBox(
                          height: CustomSpacing.four,
                        ),
                        Expanded(
                          child: Consumer<VerificationProvider>(
                              builder: (context, verificationProvider, child) {
                            print(
                                verificationProvider.corporateRequests.length);
                            return verificationProvider.isCorporateLoading
                                ? Center(
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      child: const CircularProgressIndicator(),
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
                                                  style: typography.Body1,
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
                                      child: const CircularProgressIndicator(),
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
                                                  LanguageService.getTranslated(
                                                      context,
                                                      'usermanagement_app_user_verification_no_requests'),
                                                  style: typography.Body1,
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

  Future<void> _refreshCorporateRequests() async {
    await Provider.of<VerificationProvider>(context, listen: false)
        .getAllCorporateRequests(context);
  }

  _verificationCorporateRequestsListItem(
      int index, VerificationProvider verificationProvider) {
    var typography = CustomTypography(context);
    return Container(
      margin: const EdgeInsets.only(top: 0.0, bottom: 8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: CustomSpacing.one),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '“${verificationProvider.corporateRequests[index].admin?.name ?? ""}”',
                          style: typography.Body1_5.copyWith(
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
                          style: typography.Body1_5,
                        ),
                        TextSpan(
                          text:
                              '“${verificationProvider.corporateRequests[index].companyName}”',
                          style: typography.Body1_5.copyWith(
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
                  SizedBox(height: CustomSpacing.one),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomChip(
                          label: Text(
                            verificationProvider
                                    .corporateRequests[index].admin?.email ??
                                "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                          label: Text(
                            verificationProvider
                                    .corporateRequests[index].admin?.phone ??
                                "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                          label: Text(
                            verificationProvider
                                    .corporateRequests[index].companyTypeName ??
                                "",
                            style: typography.InputLabel,
                          ),
                        ),
                        SizedBox(width: CustomSpacing.two),
                        CustomChip(
                          label: Text('Admin', style: typography.InputLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  verificationProvider.isCorporateAcceptLoading &&
                          selectedCorporateVerificationAcceptListIndex == index
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : CustomButton(
                          type: ButtonType.outlined,
                          onPressed: () async {
                            selectedCorporateVerificationAcceptListIndex =
                                index;
                            final ok = await verificationProvider
                                .changeCorporateVerificationStatus(
                              context,
                              verificationProvider
                                      .corporateRequests[index].id ??
                                  "",
                              true,
                            );
                            if (ok) {
                              await verificationProvider
                                  .getAllCorporateRequests(context);
                              if (mounted) {
                                setState(() {
                                  selectedCorporateVerificationAcceptListIndex =
                                      -1;
                                  selectedCorporateVerificationRejectListIndex =
                                      -1;
                                });
                              }
                            }
                          },
                          child: Text(
                            'Accept',
                            style:
                                typography.BottomNavigationActiveLabel.copyWith(
                                    color: AppColors.primaryMain),
                          ),
                        ),
                  SizedBox(width: CustomSpacing.two),
                  verificationProvider.isCorporateRejectLoading &&
                          selectedCorporateVerificationRejectListIndex == index
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : CustomButton(
                          type: ButtonType.text,
                          onPressed: () async {
                            selectedCorporateVerificationRejectListIndex =
                                index;
                            final ok = await verificationProvider
                                .changeCorporateVerificationStatus(
                              context,
                              verificationProvider
                                      .corporateRequests[index].id ??
                                  "",
                              false,
                            );
                            if (ok) {
                              await _refreshCorporateRequests(); // <--- automatically refresh list
                              if (mounted) {
                                setState(() {
                                  selectedCorporateVerificationAcceptListIndex =
                                      -1;
                                  selectedCorporateVerificationRejectListIndex =
                                      -1;
                                });
                              }
                            }
                          },

                          // onPressed: () async {
                          //
                          //   selectedCorporateVerificationRejectListIndex = index;
                          //   final ok = await verificationProvider
                          //       .changeCorporateVerificationStatus(
                          //     context,
                          //     verificationProvider
                          //         .corporateRequests[index].id ??
                          //         "",
                          //     false,
                          //   );
                          //   if (ok) {
                          //     print("object");
                          //     Provider.of<VerificationProvider>(context, listen: false)
                          //         .getAllUserRequests(context);
                          //     if (mounted) {
                          //       Provider.of<VerificationProvider>(context, listen: false)
                          //           .getAllUserRequests(context);
                          //     }
                          //   }
                          // },
                          child: Text(
                            'Reject',
                            style:
                                typography.BottomNavigationActiveLabel.copyWith(
                                    color: AppColors.primaryMain),
                          ),
                        ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: CustomSpacing.two),
                      Text(
                        formatCreatedAt(
                          verificationProvider.corporateRequests[index],
                        ),
                        style: typography.Caption,
                      ),
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

  // _verificationCorporateRequestsListItem(
  //     int index, VerificationProvider verificationProvider) {
  //   var typography = CustomTypography(context);
  //   return Container(
  //     margin: const EdgeInsets.only(top: 0.0, bottom: 8),
  //     child: Card(
  //       child: Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               children: [
  //                 SizedBox(
  //                   height: CustomSpacing.one,
  //                 ),
  //                 //Use rich Text and color inverted values to white
  //                 RichText(
  //                   text: TextSpan(
  //                     children: [
  //                       TextSpan(
  //                         text:
  //                             '“${verificationProvider.corporateRequests[index].admin?.name ?? ""}”',
  //                         style: typography.Body1_5.copyWith(
  //                           color:
  //                               Theme.of(context).brightness == Brightness.dark
  //                                   ? AppColors.white
  //                                   : AppColors.black,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                       TextSpan(
  //                         text:
  //                             ' has requested to create new corporate account for company name ',
  //                         style: typography.Body1_5,
  //                       ),
  //                       TextSpan(
  //                         text:
  //                             '“${verificationProvider.corporateRequests[index].companyName}”',
  //                         style: typography.Body1_5.copyWith(
  //                           color:
  //                               Theme.of(context).brightness == Brightness.dark
  //                                   ? AppColors.white
  //                                   : AppColors.black,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 SizedBox(
  //                   height: CustomSpacing.one,
  //                 ),
  //                 SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: [
  //                       CustomChip(
  //                           label: Text(
  //                               verificationProvider.corporateRequests[index]
  //                                       .admin?.email ??
  //                                   "",
  //                               style: typography.InputLabel)),
  //                       SizedBox(width: CustomSpacing.two),
  //                       CustomChip(
  //                           label: Text(
  //                               verificationProvider.corporateRequests[index]
  //                                       .admin?.phone ??
  //                                   "",
  //                               style: typography.InputLabel)),
  //                       SizedBox(width: CustomSpacing.two),
  //                       CustomChip(
  //                           label: Text(
  //                               verificationProvider.corporateRequests[index]
  //                                       .companyTypeName ??
  //                                   "",
  //                               style: typography.InputLabel)),
  //                       SizedBox(width: CustomSpacing.two),
  //                       CustomChip(
  //                           label: Text('Admin', style: typography.InputLabel)),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Container(
  //             decoration: BoxDecoration(
  //               color: Theme.of(context).colorScheme.surface,
  //               // bottom left and right corners curved
  //               borderRadius: const BorderRadius.only(
  //                 bottomLeft: Radius.circular(8),
  //                 bottomRight: Radius.circular(8),
  //               ),
  //             ),
  //             padding: const EdgeInsets.symmetric(horizontal: 8),
  //             child: Row(
  //               children: [
  //                 verificationProvider.isCorporateAcceptLoading &&
  //                         selectedCorporateVerificationAcceptListIndex == index
  //                     ? Center(
  //                         child: Container(
  //                           margin: const EdgeInsets.only(left: 24),
  //                           height: 20,
  //                           width: 20,
  //                           child: const CircularProgressIndicator(),
  //                         ),
  //                       )
  //                     : CustomButton(
  //                         type: ButtonType.outlined,
  //                         onPressed: () {
  //                           // Handle accept
  //                           selectedCorporateVerificationAcceptListIndex =
  //                               index;
  //                           verificationProvider
  //                               .changeCorporateVerificationStatus(
  //                                   context,
  //                                   verificationProvider
  //                                           .corporateRequests[index].id ??
  //                                       "",
  //                                   true)
  //                               .then((value) {
  //                             if (value) {
  //                               if (value) {
  //                                 verificationProvider
  //                                     .getAllCorporateRequests(context);
  //                               }
  //                             }
  //                           });
  //                         },
  //                         child: Text('Accept',
  //                             style: typography.BottomNavigationActiveLabel
  //                                 .copyWith(color: AppColors.primaryMain)),
  //                       ),
  //                 SizedBox(width: CustomSpacing.two),
  //                 verificationProvider.isCorporateRejectLoading &&
  //                     selectedCorporateVerificationRejectListIndex == index
  //                     ? const Center(
  //                   child: SizedBox(
  //                     height: 20,
  //                     width: 20,
  //                     child: CircularProgressIndicator(),
  //                   ),
  //                 )
  //                     : CustomButton(
  //                   type: ButtonType.text,
  //                   onPressed: () async {
  //                     selectedCorporateVerificationRejectListIndex = index;
  //                     final success =
  //                     await verificationProvider.changeCorporateVerificationStatus(
  //                       context,
  //                       verificationProvider.corporateRequests[index].id ?? "",
  //                       false,
  //                     );
  //                     if (success) {
  //                       // Re-fetch data (reload list)
  //                       await verificationProvider.getAllCorporateRequests(context);
  //                       if (mounted) {
  //                         setState(() {}); // Force UI rebuild if needed
  //                       }
  //                     }
  //                   },
  //                   child: Text(
  //                     'Reject',
  //                     style: typography.BottomNavigationActiveLabel
  //                         .copyWith(color: AppColors.primaryMain),
  //                   ),
  //                 ),
  //                 // verificationProvider.isCorporateRejectLoading &&
  //                 //         selectedCorporateVerificationRejectListIndex == index
  //                 //     ? Center(
  //                 //         child: Container(
  //                 //           margin: const EdgeInsets.only(left: 16),
  //                 //           height: 20,
  //                 //           width: 20,
  //                 //           child: const CircularProgressIndicator(),
  //                 //         ),
  //                 //       )
  //                 //     : CustomButton(
  //                 //         type: ButtonType.text,
  //                 //         onPressed: () {
  //                 //           // Handle reject
  //                 //           selectedCorporateVerificationRejectListIndex =
  //                 //               index;
  //                 //           verificationProvider
  //                 //               .changeCorporateVerificationStatus(
  //                 //                   context,
  //                 //                   verificationProvider
  //                 //                           .corporateRequests[index].id ??
  //                 //                       "",
  //                 //                   false)
  //                 //               .then((value) {
  //                 //             if (value) {
  //                 //               if (value) {
  //                 //                 verificationProvider
  //                 //                     .getAllCorporateRequests(context);
  //                 //               }
  //                 //             }
  //                 //           });
  //                 //         },
  //                 //         child: Text('Reject',
  //                 //             style: typography.BottomNavigationActiveLabel
  //                 //                 .copyWith(color: AppColors.primaryMain)),
  //                 //       ),
  //                 const Spacer(),
  //                 //date
  //                 Row(
  //                   children: [
  //                     const Icon(Icons.calendar_today),
  //                     SizedBox(width: CustomSpacing.two),
  //                     Text(
  //                         formatCreatedAt(
  //                             verificationProvider.corporateRequests[index]),
  //                         style: typography.Caption),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String formatCreatedAt(Company? company) {
    DateTime dateTime = company?.createdAt?.toDateTime() ?? DateTime.now();
    DateFormat dateFormat = DateFormat('MMM d, yyyy HH:mm');
    return dateFormat.format(dateTime.toLocal());
  }

  _verificationUserRequestsListItem(
      int index, VerificationProvider verificationProvider) {
    DateTime dateTime =
        verificationProvider.userRequests[index]?.createdAt?.toDateTime() ??
            DateTime.now();
    DateFormat dateFormat = DateFormat('MMM d, yyyy HH:mm');
    String? date = dateFormat.format(dateTime.toLocal());
    var typography = CustomTypography(context);
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
      int totalTrialUsers = userProfileProvider.trialInfo['totalUsers'] ?? 0;
      int totalUsersVerified =
          userProfileProvider.trialInfo['totalUsersVerified'] ?? 0;
      return Container(
        margin: const EdgeInsets.only(top: 0.0, bottom: 8),
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
                            style: typography.Body1_5.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: LanguageService.getTranslated(context,
                                'usermanagement_app_corporate_verification_request_text'),
                            style: typography.Body1_5,
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
                                  style: typography.InputLabel)),
                          SizedBox(width: CustomSpacing.two),
                          CustomChip(
                              label: Text(
                                  verificationProvider
                                          .userRequests[index].phone ??
                                      "",
                                  style: typography.InputLabel)),
                          SizedBox(width: CustomSpacing.two),
                          CustomChip(
                              onPressed: () {
                                //future implementations
                                //Show a dialog with outlined dropdown with allRoles, user can save or cancel (as column)
                                // showDialog(
                                //   context: context,
                                //   builder: (context) {
                                //     return AlertDialog(
                                //       title: Text('Select Role',
                                //           style: typography.H6),
                                //       content: Column(
                                //         mainAxisSize: MainAxisSize.min,
                                //         children: [
                                //           SizedBox(
                                //             height: CustomSpacing.two,
                                //           ),
                                //           DropdownButtonFormField(
                                //             items: allRoles
                                //                 .where((role) =>
                                //                     role.isApplicableForInternal ==
                                //                     true) // Filter out roles where isApplicableForTrial is not true
                                //                 .map((role) {
                                //               return DropdownMenuItem(
                                //                 child: Text(role.name ?? ""),
                                //                 value: role,
                                //               );
                                //             }).toList(),
                                //             onChanged: (value) {
                                //               // Handle dropdown value change
                                //               selectedRole =
                                //                   value as roleModel.Roles;
                                //             },
                                //             value: selectedRole,
                                //             decoration: InputDecoration(
                                //               border: OutlineInputBorder(
                                //                 borderRadius:
                                //                     BorderRadius.circular(8),
                                //               ),
                                //             ),
                                //           ),
                                //           SizedBox(
                                //             height: CustomSpacing.two,
                                //           ),
                                //           Column(
                                //             mainAxisAlignment:
                                //                 MainAxisAlignment.spaceEvenly,
                                //             children: [
                                //               Row(
                                //                 children: [
                                //                   Expanded(
                                //                     child: CustomButton(
                                //                       type: ButtonType.filled,
                                //                       onPressed: () {
                                //                         // Handle save role
                                //                         Navigator.pop(context);
                                //                       },
                                //                       child: Text('Save',
                                //                           style: typography
                                //                               .BottomNavigationActiveLabel),
                                //                     ),
                                //                   ),
                                //                 ],
                                //               ),
                                //               Row(
                                //                 children: [
                                //                   Expanded(
                                //                     child: CustomButton(
                                //                       type: ButtonType.text,
                                //                       onPressed: () {
                                //                         // Handle cancel
                                //                         Navigator.pop(context);
                                //                       },
                                //                       child: Text('Cancel',
                                //                           style: typography
                                //                                   .BottomNavigationActiveLabel
                                //                               .copyWith(
                                //                                   color: AppColors
                                //                                       .primaryMain)),
                                //                     ),
                                //                   ),
                                //                 ],
                                //               ),
                                //             ],
                                //           ),
                                //         ],
                                //       ),
                                //     );
                                //   },
                                // );
                              },
                              label: Text(
                                  verificationProvider
                                          .userRequests[index].role ??
                                      "",
                                  style: typography.InputLabel)),
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    verificationProvider.isCorporateAcceptLoading &&
                            selectedUserVerificationAcceptListIndex == index
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.only(left: 24),
                              height: 20,
                              width: 20,
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : CustomButton(
                            type: ButtonType.outlined,
                            onPressed: () {
                              print(
                                  'Total Users Verified: $totalUsersVerified');
                              print('Total Trial Users: $totalTrialUsers');
                              print('Trial Status: $trialStatus');
                              if (trialStatus.isNotEmpty &&
                                  (totalUsersVerified >= totalTrialUsers)) {
                                showDialog(
                                  context: context,
                                  barrierColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLowest,
                                  builder: (BuildContext context) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                        MessageCard(
                                          isUpgrade: true,
                                          messageTextSpans: [
                                            TextSpan(
                                              text: 'You have ',
                                              style: CustomTypography(context)
                                                  .Body1,
                                            ),
                                            TextSpan(
                                              text: 'reached the maximum limit',
                                              style: CustomTypography(context)
                                                  .Body1
                                                  .copyWith(
                                                    color: AppColors.warning,
                                                  ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' of users for your account. Please upgrade your account to add more users.',
                                              style: CustomTypography(context)
                                                  .Body1,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return;
                              }
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
                                style: typography.BottomNavigationActiveLabel
                                    .copyWith(color: AppColors.primaryMain)),
                          ),
                    SizedBox(width: CustomSpacing.two),
                    verificationProvider.isUserRejectLoading &&
                            selectedUserVerificationRejectListIndex == index
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.only(left: 16),
                              height: 20,
                              width: 20,
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : verificationProvider.isUserRejectLoading &&
                                selectedUserVerificationRejectListIndex == index
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              )
                            : CustomButton(
                                type: ButtonType.text,
                                onPressed: () async {
                                  setState(() {
                                    selectedUserVerificationRejectListIndex =
                                        index;
                                  });

                                  final rejected = await verificationProvider
                                      .changeUserVerificationStatus(
                                    context,
                                    verificationProvider
                                            .userRequests[index].id ??
                                        "",
                                    false,
                                  );

                                  if (rejected) {
                                    await verificationProvider
                                        .getAllUserRequests(context);
                                    // If corporate counts depend on user changes
                                    await Provider.of<VerificationProvider>(
                                      context,
                                      listen: false,
                                    ).getAllCorporateRequests(context);
                                  }

                                  if (mounted) {
                                    setState(() {
                                      selectedUserVerificationRejectListIndex =
                                          -1;
                                      selectedUserVerificationAcceptListIndex =
                                          -1;
                                    });
                                  }
                                },
                                child: Text(
                                  'Reject',
                                  style: typography.BottomNavigationActiveLabel
                                      .copyWith(color: AppColors.primaryMain),
                                ),
                              ),
                    const Spacer(),
                    //date
                    // uncomment for time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        SizedBox(width: CustomSpacing.two),
                        Text('$date',
                            //'Mar 7, 2024 23:26',
                            style: typography.Caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  buildDropdownMenuItems() {
    var typography = CustomTypography(context);
    return [
      DropdownMenuItem(
        child: Row(
          children: [
            const Icon(Icons.apartment),
            SizedBox(width: CustomSpacing.two),
            Text(
              'Corporate Management',
              style: typography.BottomNavigationActiveLabel,
            ),
          ],
        ),
        value: 'Corporate',
      ),
      showCorporateList
          ? DropdownMenuItem(
              child: Text(
                'Companies',
                style: typography.BottomNavigationActiveLabel,
              ),
              value: 'Companies',
            )
          : Container(
              height: 0,
              child: DropdownMenuItem(
                child: Text(
                  'Companies',
                  style: typography.BottomNavigationActiveLabel,
                ),
                value: 'Companies',
              ),
            ),
      showCorporateUserListDropdown
          ? DropdownMenuItem(
              child: Text(
                'Users',
                style: typography.BottomNavigationActiveLabel,
              ),
              value: 'Users',
            )
          : const SizedBox(),
      showViewCorporate
          ? DropdownMenuItem(
              child: Text(
                'Company Profiles',
                style: typography.BottomNavigationActiveLabel,
              ),
              value: 'Company Profiles',
            )
          : const SizedBox(),
      showCorporateVerificationTab || showUserVerificationTab
          ? DropdownMenuItem(
              child: Text(
                'Verification Requests',
                style: typography.BottomNavigationActiveLabel,
              ),
              value: 'Verification Requests',
            )
          : const SizedBox(),
    ];
  }

  String? getCountryCodeFromName(String countryName) {
    return countryNameToCodeMap[countryName];
  }
}
