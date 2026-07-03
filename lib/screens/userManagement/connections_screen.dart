import '../../utils/global_imports.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/repo/constants.dart';
import '../../models/initial_data_model.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int selectedTabIndex;

  const ConnectionsScreen(
      {super.key,
      required this.userId,
      required this.userName,
      this.selectedTabIndex = 0});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
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
  TextEditingController _messageController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TabController? _connectionsTabController;

  int requestActionIndex = 0;

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

  Timer? deBouncer;

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void connectionsSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
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
      await Provider.of<ConnectionsProvider>(context, listen: false)
          .getAllConnections(context, widget.userId,
              searchText: searchText,
              companyType: companyTypeFilter,
              roleFilter: roleFilter,
              isSearch: isSearch);
    });
  }

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
    print('User ID: ${widget.userId}');
    print('User Name: ${widget.userName}');
    _tabController = TabController(length: 5, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        setState(() {
          _selectedScreen = Screens.networkList;
        });
      } else if (_tabController?.index == 1) {
        setState(() {
          _selectedScreen = Screens.connectionList;
        });
      } else if (_tabController?.index == 2) {
        setState(() {
          _selectedScreen = Screens.requestList;
        });
      } else if (_tabController?.index == 3) {
        setState(() {
          _selectedScreen = Screens.chatList;
        });
      } else if (_tabController?.index == 4) {
        setState(() {
          _selectedScreen = Screens.blockedList;
        });
      }
      print(
          'Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
    if (widget.selectedTabIndex != 0) {
      _tabController?.animateTo(widget.selectedTabIndex);
      if (widget.selectedTabIndex == 0) {
        _selectedScreen = Screens.networkList;
      } else if (widget.selectedTabIndex == 1) {
        _selectedScreen = Screens.connectionList;
      } else if (widget.selectedTabIndex == 2) {
        _selectedScreen = Screens.requestList;
      } else if (widget.selectedTabIndex == 3) {
        _selectedScreen = Screens.chatList;
      } else if (widget.selectedTabIndex == 4) {
        _selectedScreen = Screens.blockedList;
      }
    }

    _connectionsTabController = TabController(length: 2, vsync: this);
    _connectionsTabController?.addListener(() {
      print('Connections Tab Index: ${_connectionsTabController?.index}');
    });
    _getData();
  }

  _getData() async {
    // Fetch data from API
    Provider.of<ConnectionsProvider>(context, listen: false).nextPageToken =
        null;
    Provider.of<ConnectionsProvider>(context, listen: false).nextPageExists =
        true;
    Provider.of<ConnectionsProvider>(context, listen: false)
        .getAllConnections(context, widget.userId);
    await Provider.of<ConnectionsProvider>(context, listen: false)
        .getUserSuggestions(context, "query");
    Provider.of<ConnectionsProvider>(context, listen: false)
        .getAllConnections(context, widget.userId);
    Provider.of<ConnectionsProvider>(context, listen: false)
        .getAllRequests(context, widget.userId);

    filterRoleList = await Provider.of<RoleProvider>(context, listen: false)
        .getAllRoles(context);
  }

  void searchNetworks(String query) async => debounce(() async {
        if (!mounted) return;
        await Provider.of<ConnectionsProvider>(context, listen: false)
            .getUserSuggestions(context, query);
      });

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
    return Consumer<ThemeProvider>(
        builder: (buildContext, themeProvider, child) {
      return SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: themeProvider.getTheme.colorScheme.background,
          appBar: CustomAppBar(
            isExpanded: _isExpanded,
            canNavigateToConnections: false,
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
          // floatingActionButton: _selectedScreen == Screens.connectionList ||
          //         _selectedScreen == Screens.corporateConnectionList ||
          //         _selectedScreen == Screens.nonCorporateConnectionList
          //     ? Builder(builder: (contextLocal) {
          //         return Column(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             FloatingActionButton(
          //               onPressed: () {
          //                 // Open bottom sheet of filters
          //                 print(
          //                     'Show Filters Bottom Sheet: $_selectedScreen, $context1, $buildContext, ${_scaffoldKey.currentContext}');
          //                 _showFiltersBottomSheet(contextLocal);
          //               },
          //               child: Icon(Icons.filter_alt_outlined),
          //             ),
          //             SizedBox(
          //               height: CustomSpacing.two,
          //             ),
          //             FloatingActionButton(
          //               onPressed: () {
          //                 _tabController?.animateTo(3);
          //                 _selectedScreen = Screens.networkList;
          //               },
          //               child: Icon(Icons.add),
          //             ),
          //           ],
          //         );
          //       })
          //     : SizedBox(),
          body: PopScope(
            canPop: _selectedScreen == Screens.connectionList ||
                _selectedScreen == Screens.corporateConnectionList,
            onPopInvoked: (canPop) {
              print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
              if (_selectedScreen == Screens.nonCorporateConnectionList) {
                setState(() {
                  _selectedScreen = Screens.corporateConnectionList;
                });
              } else if (_selectedScreen == Screens.requestList) {
                setState(() {
                  _tabController?.animateTo(1);
                  _selectedScreen = Screens.corporateConnectionList;
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
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName == ''
                                  ? LanguageService.getTranslated(context,
                                      "connections_user_connection_connections_tab")
                                  : '${LanguageService.getTranslated(context, "connections_user_connection_connections_tab")} ${widget.userName.substring(0, 1).toUpperCase()}${widget.userName.substring(1)}',
                              style: typography.H5_Regular,
                            ),
                            SizedBox(height: CustomSpacing.two),
                            Text(
                              LanguageService.getTranslated(context,
                                  "connections_user connections_sub_title_description"),
                              style: typography.Body2,
                            ),
                            SizedBox(height: CustomSpacing.two),
                            Consumer<ConnectionsProvider>(
                              builder: (context, connectionsProvider, child) {
                                return TabBar(
                                  isScrollable: true,
                                  controller: _tabController,
                                  labelStyle:
                                      typography.BottomNavigationActiveLabel,
                                  tabs: [
                                    InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(0);
                                        _selectedScreen = Screens.networkList;
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Tab(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "connections_user_connection_networking_tab"),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: InkWell(
                                        onTap: () {
                                          _tabController?.animateTo(1);
                                          _selectedScreen =
                                              Screens.connectionList;
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Tab(
                                              child: DropdownButton(
                                                underline: SizedBox(),
                                                value: LanguageService
                                                    .getTranslated(context,
                                                        "connections_user_connection_connections_tab"),
                                                items: [
                                                  DropdownMenuItem(
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.apartment),
                                                        SizedBox(
                                                            width: CustomSpacing
                                                                .two),
                                                        Text(
                                                          LanguageService
                                                              .getTranslated(
                                                                  context,
                                                                  "connections_user_connection_connections_tab"),
                                                          style: typography
                                                              .BottomNavigationActiveLabel,
                                                        ),
                                                      ],
                                                    ),
                                                    value: LanguageService
                                                        .getTranslated(context,
                                                            "connections_user_connection_connections_tab"),
                                                  ),
                                                  DropdownMenuItem(
                                                    child: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "connections_user_connection_corporate_connections_filed_label"),
                                                      style: typography
                                                          .BottomNavigationActiveLabel,
                                                    ),
                                                    value: 'Corporate',
                                                  ),
                                                  DropdownMenuItem(
                                                    child: Text(
                                                      LanguageService
                                                          .getTranslated(
                                                              context,
                                                              "non_corporate"),
                                                      style: typography
                                                          .BottomNavigationActiveLabel,
                                                    ),
                                                    value: 'Non Corporate',
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (value ==
                                                        'Non Corporate') {
                                                      _selectedScreen = Screens
                                                          .corporateConnectionList;
                                                    } else if (value ==
                                                        'Corporate') {
                                                      _selectedScreen = Screens
                                                          .nonCorporateConnectionList;
                                                    }
                                                    _tabController
                                                        ?.animateTo(1);
                                                  });
                                                },
                                              ),
                                            ),
                                            connectionsProvider.totalConnections
                                                        .toString() ==
                                                    "0"
                                                ? Container()
                                                : SizedBox(
                                                    height: 25,
                                                    width: 35,
                                                    child: Chip(
                                                      labelPadding:
                                                          EdgeInsets.all(0),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      label: Text(
                                                        connectionsProvider
                                                            .totalConnections,
                                                        style: typography
                                                                .BottomNavigationActiveLabel
                                                            .copyWith(
                                                                height: -0.6),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(2);
                                        _selectedScreen = Screens.requestList;
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Tab(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "connections_user_connection_requests__tab"),
                                          ),
                                          if (connectionsProvider
                                                  .requestReceivedCount
                                                  .toString() !=
                                              "0") ...[
                                            SizedBox(width: CustomSpacing.two),
                                            SizedBox(
                                              height: 25,
                                              width: 35,
                                              child: Chip(
                                                labelPadding: EdgeInsets.all(0),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                label: Text(
                                                  connectionsProvider
                                                      .requestReceivedCount,
                                                  style: typography
                                                          .BottomNavigationActiveLabel
                                                      .copyWith(height: -0.6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(3);
                                        _selectedScreen = Screens.chatList;
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Tab(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "connections_user_connection_chats__tab"),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(4);
                                        _selectedScreen = Screens.blockedList;
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Tab(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "connections_user_connection_blocked_tab"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _getNetworkingUI(),
                                  _getConnectionsUI(),
                                  _getRequestsUI(),
                                  _getChatsUI(),
                                  _getBlockedUI(),
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
                                  child: Text(
                                    LanguageService.getTranslated(context,
                                        'connections_user_connection_clear_filter_filed_label'),
                                  ),
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
                                            'user_profile_user_management_name_filed_label'),
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
                                      controller: _filterEmailController,
                                      decoration: InputDecoration(
                                        labelText: LanguageService.getTranslated(
                                            context,
                                            "user_profile_user_management_email_field_label"),
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
                                        labelText:
                                            LanguageService.getTranslated(
                                                context,
                                                "register_mobile_number"),
                                        hintText: LanguageService.getTranslated(
                                            context,
                                            "register_enter_mobile_number"),
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
                                    // TextFormField(
                                    //   controller: _filterCompanyController,
                                    //   decoration: InputDecoration(
                                    //     labelText: LanguageService.getTranslated(
                                    //         context,
                                    //         "usermangement_corp_trow_comp_name"),
                                    //     labelStyle: typography.Body1,
                                    //     border: OutlineInputBorder(
                                    //       borderRadius:
                                    //           BorderRadius.circular(8),
                                    //     ),
                                    //   ),
                                    // ),
                                    // SizedBox(height: CustomSpacing.two),
                                    // // Role Dropdown
                                    // (_selectedScreen == Screens.corporateList)
                                    //     ? SizedBox()
                                    //     : DropdownButtonFormField<
                                    //         roleModel.Roles>(
                                    //         decoration: InputDecoration(
                                    //           labelText:
                                    //               LanguageService.getTranslated(
                                    //                   context,
                                    //                   "register_corporate_role_field_label"),
                                    //           border: OutlineInputBorder(
                                    //             borderRadius:
                                    //                 BorderRadius.circular(8),
                                    //           ),
                                    //         ),
                                    //         items: filterRoleList
                                    //             .map((roleModel.Roles value) {
                                    //           return DropdownMenuItem<
                                    //               roleModel.Roles>(
                                    //             value: value,
                                    //             child: Text(value.name ?? ''),
                                    //           );
                                    //         }).toList(),
                                    //         onChanged:
                                    //             (roleModel.Roles? value) {
                                    //           // Handle role change
                                    //           setState(() {
                                    //             selectedRoleForFilter = value;
                                    //           });
                                    //         },
                                    //       ),
                                    //
                                    // SizedBox(height: CustomSpacing.two),
                                    // // Status
                                    // DropdownButtonFormField<String>(
                                    //   decoration: InputDecoration(
                                    //     labelText: LanguageService.getTranslated(
                                    //         context,
                                    //         "categorymanagement_trow_status"),
                                    //     border: OutlineInputBorder(
                                    //       borderRadius:
                                    //           BorderRadius.circular(8),
                                    //     ),
                                    //   ),
                                    //   items: ['Active', 'Inactive']
                                    //       .map((String value) {
                                    //     return DropdownMenuItem<String>(
                                    //       value: value,
                                    //       child: Text(value),
                                    //     );
                                    //   }).toList(),
                                    //   onChanged: (String? value) {
                                    //     // Handle status change
                                    //     setState(() {
                                    //       selectedStatus = value!;
                                    //     });
                                    //   },
                                    // ),
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
                                              addFilter(
                                                  selectedStatus, 'status');
                                              selectedStatus = '';
                                            }
                                            // call api and close the drawer
                                            if (_selectedScreen ==
                                                    Screens.connectionList ||
                                                _selectedScreen ==
                                                    Screens
                                                        .corporateConnectionList ||
                                                _selectedScreen ==
                                                    Screens
                                                        .nonCorporateConnectionList) {
                                              connectionsSearchClient("");
                                              Scaffold.of(context)
                                                  .closeEndDrawer();
                                            }
                                          },
                                          type: ButtonType.filled,
                                          child: Text(
                                            'Add Filter',
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
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 22, vertical: 8),
                                          ),
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
                                                "user_profile_user_management_btn_cancel"),
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

  _getConnectionsUI() {
    return Column(
      children: [
        SizedBox(
          height: CustomSpacing.two,
        ),
        _selectedScreen == Screens.corporateConnectionList
            ? _getNonCorporateConnectionsUI()
            : _getCorporateConnectionsUI()
        // : _getNonCorporateConnectionsUI(),
      ],
    );
  }

  Widget _getCorporateConnectionsUI() {
    return Expanded(
      child: Consumer<ConnectionsProvider>(
        builder: (context, connectionsProvider, child) {
          return connectionsProvider.isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                )
              : connectionsProvider.corporateConnections.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Center(
                          child: Text(
                            LanguageService.getTranslated(
                                context, "connection_no_corporate_connection"),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await connectionsProvider.getAllConnections(
                            context, widget.userId);
                      },
                      child: ListView.builder(
                        itemCount:
                            connectionsProvider.corporateConnections.length,
                        itemBuilder: (context, index) {
                          if (index ==
                              connectionsProvider.corporateConnections.length -
                                  1) {
                            return Column(
                              children: [
                                _corporateConnectionsCardUI(
                                    connectionsProvider, index),
                                SizedBox(
                                  height: CustomSpacing.twentyEight,
                                ),
                              ],
                            );
                          }
                          return _corporateConnectionsCardUI(
                              connectionsProvider, index);
                        },
                      ),
                    );
        },
      ),
    );
  }

  Widget _getNonCorporateConnectionsUI() {
    return Expanded(
      child: Consumer<ConnectionsProvider>(
        builder: (context, connectionsProvider, child) {
          return connectionsProvider.isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    ),
                  ],
                )
              : connectionsProvider.nonCorporateConnections.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Center(
                          child: Text(
                            LanguageService.getTranslated(context,
                                "connection_no_non_corporate_connection"),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await connectionsProvider.getAllConnections(
                            context, widget.userId);
                      },
                      child: ListView.builder(
                        itemCount:
                            connectionsProvider.nonCorporateConnections.length,
                        itemBuilder: (context, index) {
                          return _nonCorporateConnectionsCardUI(
                              connectionsProvider, index);
                        },
                      ),
                    );
        },
      ),
    );
  }

  Widget _connectionsCardUIOLD() {
    var typography = CustomTypography(context);
    //profile avatar, role, company, rating out of 5, actions are in popupmenu (send message, connections, remove connection)
    return Container(
      margin: EdgeInsets.only(bottom: CustomSpacing.two),
      child: Card(
        child: Column(
          children: [
            // Stack with request pending container top left
            Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Request Pending',
                      style: typography.Body2.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),
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
                            RatingBar(
                              rating: 4,
                              maxRating: 5,
                              iconSize: 18,
                            ),
                          ],
                        ),
                        Spacer(),
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.mail),
                                    SizedBox(width: CustomSpacing.two),
                                    Text('Send Message'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.people),
                                    SizedBox(width: CustomSpacing.two),
                                    Text('Connections'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.exit_to_app),
                                    SizedBox(width: CustomSpacing.two),
                                    Text('Remove Connection'),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),
          ],
        ),
      ),
    );
  }

  Widget _corporateConnectionsCardUI(
      ConnectionsProvider connectionsProvider, int index) {
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Card(
          child: Stack(
            children: [
              (connectionsProvider.corporateConnections[index].requestPending ??
                      false)
                  ? Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          LanguageService.getTranslated(context,
                              "connections_user_connection_connect_requestpending"),
                          style: typography.Body2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: CustomSpacing.four,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: CustomSpacing.four,
                      ),
                      CircleAvatar(
                        child: connectionsProvider.corporateConnections[index]
                                        .displayImageUrl !=
                                    null &&
                                connectionsProvider.corporateConnections[index]
                                        .displayImageUrl !=
                                    ''
                            ? ClipOval(
                                child: Image.network(
                                  connectionsProvider
                                      .corporateConnections[index]
                                      .displayImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                connectionsProvider
                                        .corporateConnections[index].name
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
                              (connectionsProvider
                                          .corporateConnections[index].name
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      "") +
                                  (connectionsProvider
                                          .corporateConnections[index].name
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
                            Text(
                                connectionsProvider.corporateConnections[index]
                                        .companyTypeName ??
                                    "",
                                style: typography.Caption),
                          ],
                        ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: CustomSpacing.two,
                            ),
                            Text(
                              connectionsProvider.corporateConnections[index]
                                      .companyName ??
                                  "",
                              style: typography.Body2.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black),
                            ),
                            Text(
                                connectionsProvider
                                    .corporateConnections[index].role
                                    .toString(),
                                style: typography.Caption),
                            SizedBox(
                              height: CustomSpacing.two,
                            ),
                          ],
                        ),
                      ),
                      // show like 4 (Star icon)
                      // Row(
                      //   children: [
                      //     Text(
                      //       connectionsProvider
                      //           .corporateConnections[index].rating
                      //           ?.toString() ??
                      //           "",
                      //       style: typography.Caption,
                      //     ),
                      //     Icon(
                      //       Icons.star,
                      //       color: Colors.yellow,
                      //       size: 28,
                      //     ),
                      //   ],
                      // ),
                      SizedBox(
                        width: CustomSpacing.two,
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
                        /* TextButton.icon(
                          onPressed: () {
                            // Handle view employees
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ConnectionsScreen(
                                      userId: connectionsProvider
                                              .corporateConnections[index].id ??
                                          "",
                                      userName: connectionsProvider
                                              .corporateConnections[index]
                                              .name ??
                                          "",
                                    )));
                          },
                          icon: Icon(Icons.people),
                          label: Text('View Connections',
                              style: typography.Caption.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black)),
                        ),*/
                        /*Spacer(),*/
                        /*employeeProvider.isEditViewEmployeeLoading
                            ? Center(
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : */
                        // Chats Hidden
                        /*IconButton(
                          onPressed: null,
                          icon: Icon(Icons.mail),
                          color: AppColors.primaryMain,
                        ),*/
                        /*employeeProvider.isDeleteLoading &&
                            selectedCompanyListIndex == index
                            ? Center(
                          child: Container(
                              height: 20,
                              width: 20,
                              margin: EdgeInsets.only(right: 8),
                              child: CircularProgressIndicator()),
                        )
                            : */
                        /*IconButton(
                          icon: Icon(Icons.exit_to_app_outlined),
                          color: AppColors.primaryMain,
                          onPressed: () {},
                        ),*/
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nonCorporateConnectionsCardUI(
      ConnectionsProvider connectionsProvider, int index) {
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Card(
          child: Stack(
            children: [
              (connectionsProvider
                          .nonCorporateConnections[index].requestPending ??
                      false)
                  ? Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          LanguageService.getTranslated(context,
                              "connections_user_connection_connect_requestpending"),
                          style: typography.Body2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
              Column(
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
                      CircleAvatar(
                        child: connectionsProvider
                                        .nonCorporateConnections[index]
                                        .displayImageUrl !=
                                    null &&
                                connectionsProvider
                                        .nonCorporateConnections[index]
                                        .displayImageUrl !=
                                    ''
                            ? ClipOval(
                                child: Image.network(
                                  connectionsProvider
                                      .nonCorporateConnections[index]
                                      .displayImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                connectionsProvider
                                        .nonCorporateConnections[index].name
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
                              (connectionsProvider
                                          .nonCorporateConnections[index].name
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      "") +
                                  (connectionsProvider
                                          .nonCorporateConnections[index].name
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
                            Text(
                                connectionsProvider
                                        .nonCorporateConnections[index]
                                        .companyTypeName ??
                                    "",
                                style: typography.Caption),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: CustomSpacing.two,
                      ),
                      // show like 4 (Star icon)
                      Column(
                        children: [
                          (connectionsProvider.nonCorporateConnections[index]
                                      .requestPending ??
                                  false)
                              ? SizedBox(
                                  height: CustomSpacing.three,
                                )
                              : SizedBox(),
                          Row(
                            children: [
                              Text(
                                connectionsProvider
                                        .nonCorporateConnections[index].rating
                                        ?.toString() ??
                                    "",
                                style: typography.Body1,
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 20,
                              ),
                              Text(
                                '\'s',
                                style: typography.Body1,
                              ),
                            ],
                          ),
                        ],
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
                            connectionsProvider.nonCorporateConnections[index]
                                    .companyName ??
                                "",
                            style: typography.Body2.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black),
                          ),
                          // , separated roles with 1st letter capital
                          connectionsProvider
                                      .nonCorporateConnections[index].role !=
                                  null
                              ? Text(
                                  connectionsProvider
                                      .nonCorporateConnections[index].role!
                                      .map((e) =>
                                          e[0].toUpperCase() + e.substring(1))
                                      .join(', '),
                                  style: typography.Caption)
                              : SizedBox(),
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
                        /* (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : TextButton.icon(
                                onPressed: () {
                                  // Handle view employees
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ConnectionsScreen(
                                            userId: connectionsProvider
                                                    .nonCorporateConnections[
                                                        index]
                                                    .id ??
                                                "",
                                            userName: connectionsProvider
                                                    .nonCorporateConnections[
                                                        index]
                                                    .name ??
                                                "",
                                          )));
                                },
                                icon: Icon(Icons.people),
                                label: Text(
                                    LanguageService.getTranslated(
                                        context, "view_connections"),
                                    style: typography.Caption.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.white
                                            : AppColors.black)),
                              ),*/
                        /*(connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : Spacer(),*/
                        /*employeeProvider.isEditViewEmployeeLoading
                            ? Center(
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : */
                        /* (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : IconButton(
                                onPressed: () {
                                  // Handle send message
                                },
                                icon: Icon(Icons.mail),
                                color: AppColors.primaryMain,
                              ),*/
                        /*employeeProvider.isDeleteLoading &&
                            selectedCompanyListIndex == index
                            ? Center(
                          child: Container(
                              height: 20,
                              width: 20,
                              margin: EdgeInsets.only(right: 8),
                              child: CircularProgressIndicator()),
                        )
                            : */
                        /*(connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : IconButton(
                                icon: Icon(Icons.exit_to_app_outlined),
                                color: AppColors.primaryMain,
                                onPressed: () {},
                              ),*/
                        (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? Center(
                                child: CustomButton(
                                type: ButtonType.text,
                                onPressed: () {
                                  // Handle accept request
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_none),
                                    SizedBox(width: CustomSpacing.two),
                                    Text(
                                      LanguageService.getTranslated(context,
                                          "connections_user_connection_connect_sendreminder"),
                                      style: typography.Caption.copyWith(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.white
                                              : AppColors.black),
                                    ),
                                  ],
                                ),
                              ))
                            : SizedBox(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getRequestsUI() {
    return Column(
      children: [
        SizedBox(height: CustomSpacing.two),
        Consumer<ConnectionsProvider>(
            builder: (context, connectionsProvider, child) {
          return Expanded(
            child: connectionsProvider.isRequestLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Center(
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ),
                    ],
                  )
                : connectionsProvider.requestUsers.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Center(
                            child: Text(
                              LanguageService.getTranslated(
                                  context, "connections_no_requests"),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: connectionsProvider.requestUsers.length,
                        itemBuilder: (context, index) {
                          return _requestsCardUI(connectionsProvider, index);
                        },
                      ),
          );
        }),
      ],
    );
  }

  Widget _requestsCardUI(ConnectionsProvider connectionsProvider, int index) {
    var typography = CustomTypography(context);
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
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            child: connectionsProvider.requestUsers[index]
                                            .displayImageUrl !=
                                        null &&
                                    connectionsProvider.requestUsers[index]
                                            .displayImageUrl !=
                                        ''
                                ? ClipOval(
                                    child: Image.network(
                                      connectionsProvider
                                          .requestUsers[index].displayImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    connectionsProvider.requestUsers[index].name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        "",
                                  ),
                          ),
                        ),
                        //filled check icon in green circle, top right
                        /* Positioned(
                          top: 2,
                          right: 8,
                          child: SvgPicture.asset(
                            'assets/images/check_circle.svg',
                            semanticsLabel: 'Check Circle',
                            width: 22,
                            height: 22,
                          ),
                        ),*/
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: (connectionsProvider
                                                        .requestUsers[index]
                                                        .name
                                                        ?.substring(0, 1)
                                                        .toUpperCase() ??
                                                    "") +
                                                (connectionsProvider
                                                        .requestUsers[index]
                                                        .name
                                                        ?.substring(1) ??
                                                    ""),
                                            style: typography.Body2.copyWith(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black),
                                          ),
                                          TextSpan(
                                            text: ' ',
                                          ),
                                          TextSpan(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "connections_user_connection_request_submit"),
                                            style: typography.Body2.copyWith(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: CustomSpacing.two),
                          connectionsProvider.requestUsers[index].role != null
                              ? Text(
                                  connectionsProvider
                                          .requestUsers[index].role[0]
                                          .toString() ??
                                      "",
                                  /* .map((e) =>
                                          e[0].toUpperCase() + e.substring(1))
                                      .join(', '),*/
                                  style: typography.Caption)
                              : SizedBox(),
                          Text(
                              connectionsProvider
                                      .requestUsers[index].companyName ??
                                  "",
                              style: typography.Caption),
                          SizedBox(height: CustomSpacing.two),
                          Row(
                            children: [
                              Icon(
                                Icons.message,
                              ),
                              SizedBox(width: CustomSpacing.two),
                              Expanded(
                                  child: Container(
                                      margin: EdgeInsets.only(right: 8),
                                      child: Text(
                                        connectionsProvider
                                                .requestUsers[index].message ??
                                            "",
                                        style: typography.Body2,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(),
            connectionsProvider.isRequestActionLoading &&
                    requestActionIndex == index
                ? Row(
                    children: [
                      Expanded(
                          child: Center(
                              child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator()),
                      )))
                    ],
                  )
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Handle submit button
                            setState(() {
                              requestActionIndex = index;
                            });
                            Provider.of<ConnectionsProvider>(context,
                                    listen: false)
                                .acceptRejectRequest(
                                    context,
                                    connectionsProvider
                                            .requestUsers[index].id ??
                                        "",
                                    "reject_request")
                                .then((value) {
                              _getData();
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
                            LanguageService.getTranslated(context,
                                "usermanagement_verification_req_ignore_btn"),
                            style: typography.ButtonLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: CustomSpacing.two),
                      Expanded(
                        child: CustomButton(
                          onPressed: () {
                            setState(() {
                              requestActionIndex = index;
                            });
                            Provider.of<ConnectionsProvider>(context,
                                    listen: false)
                                .acceptRejectRequest(
                                    context,
                                    connectionsProvider
                                            .requestUsers[index].id ??
                                        "",
                                    "accept_request");
                          },
                          type: ButtonType.filled,
                          child: Text(
                            LanguageService.getTranslated(context,
                                "connections_user_connection_accept_btn"),
                            style: typography.ButtonLargeBlack,
                          ),
                        ),
                      ),
                    ]),
                  ),
            SizedBox(height: CustomSpacing.two),
          ],
        ),
      ),
    );
  }

  _getChatsUI() {
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

  _getNetworkingUI() {
    var typography = CustomTypography(context);
    return Column(
      children: [
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextField(
                  onChanged: searchNetworks,
                  decoration: InputDecoration(
                    hintText: LanguageService.getTranslated(context,
                        'usermanagement_search_field_lable_name_email_mobile'),
                    label: Text('Search', style: typography.Body1),
                    hintStyle: typography.Body1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: Consumer<ConnectionsProvider>(
              builder: (context, connectionsProvider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                // Call API to reload data
                Provider.of<ConnectionsProvider>(context, listen: false)
                    .getAllConnections(
                        context,
                        widget
                            .userId); //getAllNetworkingUsers(context, widget.userId);
              },
              child: connectionsProvider.isNetworkLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Center(
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ],
                    )
                  : connectionsProvider.networkingUsers.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Center(
                              child: Text("No users"),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 180, // ✅ CONTROL HEIGHT HERE
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: connectionsProvider.networkingUsers.length,
                          itemBuilder: (context, index) {
                            return _networkingCardUI(
                                connectionsProvider, index);
                          },
                        ),
            );
          }),
        ),
      ],
    );
  }

  Widget _networkingCardUI(ConnectionsProvider connectionsProvider, int index) {
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Card(
          clipBehavior: Clip.antiAlias, // 👈 IMPORTANT for rounded bottom
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 🔹 TOP CONTENT
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerRow(connectionsProvider, index),
                    const SizedBox(height: 8),
                    _companyInfo(connectionsProvider, index),
                  ],
                ),
              ),

              // 🔹 PUSH BUTTON TO BOTTOM
              const Spacer(),

              // 🔹 BOTTOM ACTION BAR
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            content: _addNetworkDialogUI(
                              dialogContext,
                              connectionsProvider,
                              index,
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      LanguageService.getTranslated(
                        context,
                        "connections_user_connection_connect_btn",
                      ),
                      style:
                          TextStyle(color: AppColors.primaryMain, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _addNetworkDialogUI(BuildContext dialogContext,
      ConnectionsProvider connectionsProvider, int index) {
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
            child: connectionsProvider.networkingUsers[index].displayImageUrl !=
                        null &&
                    connectionsProvider
                            .networkingUsers[index].displayImageUrl !=
                        ''
                ? ClipOval(
                    child: Image.network(
                      connectionsProvider
                          .networkingUsers[index].displayImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    connectionsProvider.networkingUsers[index].name
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        "",
                  ),
          ),
          SizedBox(height: CustomSpacing.four),
          Text(connectionsProvider.networkingUsers[index].name ?? "",
              style: typography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          connectionsProvider.networkingUsers[index].role != null
              ? Text(
                  connectionsProvider.networkingUsers[index].role!
                      .map((e) => e[0].toUpperCase() + e.substring(1))
                      .join(', '),
                  style: typography.Body2)
              : SizedBox(),
          Text(connectionsProvider.networkingUsers[index].companyName ?? "",
              style: typography.Body2),
          SizedBox(height: CustomSpacing.two),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     RatingBar(
          //         rating:
          //             connectionsProvider.networkingUsers[index].rating ?? 0,
          //         maxRating: 5),
          //   ],
          // ),
          // SizedBox(height: CustomSpacing.four),
          // Personalized Message make it bigger in size
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Text('Personalized Message (Optional)', style: typography.Body2),
          //   ],
          // ),
          TextFormField(
            maxLines: 4,
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Personalized Message (Optional)',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),

          SizedBox(height: CustomSpacing.two),
          // Cancel and Send Request Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 SEND BUTTON / LOADER
              Consumer<ConnectionsProvider>(
                builder: (context, provider, _) {
                  return provider.isConnectLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : CustomButton(
                          onPressed: () async {
                            final success = await provider.connectUser(
                              context,
                              provider.networkingUsers[index].id ?? "",
                              _messageController.text,
                            );

                            if (success) {
                              _getData();
                              Navigator.of(dialogContext).pop();
                              _messageController.clear();
                            }
                          },
                          type: ButtonType.filled,
                          child: Text(
                            "Send",
                            style: typography.ButtonLargeBlack,
                          ),
                        );
                },
              ),
              SizedBox(height: CustomSpacing.two),

              OutlinedButton(
                onPressed: () {
                  _messageController.clear();
                  Navigator.of(dialogContext).pop();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(
                  LanguageService.getTranslated(
                    context,
                    "connections_user_connection_cancel",
                  ),
                  style: typography.ButtonLarge,
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

  Widget _headerRow(
    ConnectionsProvider connectionsProvider,
    int index,
  ) {
    final user = connectionsProvider.networkingUsers[index];
    final typography = CustomTypography(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child:
              user.displayImageUrl != null && user.displayImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.displayImageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      (user.name?.substring(0, 1).toUpperCase() ?? ""),
                      style: typography.Body2,
                    ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.Body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.companyTypeName ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.Caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _companyInfo(
    ConnectionsProvider connectionsProvider,
    int index,
  ) {
    final user = connectionsProvider.networkingUsers[index];
    final typography = CustomTypography(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.companyName ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.Body2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.black,
          ),
        ),
        if (user.role != null && user.role!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.role!
                .map((e) => e[0].toUpperCase() + e.substring(1))
                .join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.Caption,
          ),
        ],
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
}
