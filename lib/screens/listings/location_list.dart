/*
import 'dart:async';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/providers/connections_provider.dart';
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
import '../../models/initial_data_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:green/models/role_model.dart' as roleModel;

import '../../service/language_service.dart';

class LocationList extends StatefulWidget {
  final String userId;
  final String companyName;
  final int selectedTabIndex;

  const LocationList(
      {super.key,
        required this.userId,
        required this.companyName,
        this.selectedTabIndex = 0});

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.connectionList;
  TextEditingController _locationSearchController = TextEditingController();
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

  void locationSearchClient(String query) async {
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
      */
/*bool isSearch = searchText.isNotEmpty ||
            filterCompanies.isNotEmpty ||
            filterRoles.isNotEmpty;*//*


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
    print('User Name: ${widget.companyName}');
    _tabController = TabController(length: 5, vsync: this);
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
      } else if (_tabController?.index == 3) {
        setState(() {
          _selectedScreen = Screens.networkList;
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
        _selectedScreen = Screens.connectionList;
      } else if (widget.selectedTabIndex == 1) {
        _selectedScreen = Screens.requestList;
      } else if (widget.selectedTabIndex == 2) {
        _selectedScreen = Screens.chatList;
      } else if (widget.selectedTabIndex == 3) {
        _selectedScreen = Screens.networkList;
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
    Provider.of<ConnectionsProvider>(context, listen: false).nextPageExists = true;
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
            floatingActionButton: _selectedScreen == Screens.connectionList ||
                _selectedScreen == Screens.corporateConnectionList ||
                _selectedScreen == Screens.nonCorporateConnectionList
                ? Builder(builder: (contextLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      // Open bottom sheet of filters
                      print(
                          'Show Filters Bottom Sheet: $_selectedScreen, $context1, $buildContext, ${_scaffoldKey.currentContext}');
                      _showFiltersBottomSheet(contextLocal);
                    },
                    child: Icon(Icons.filter_alt_outlined),
                  ),
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      _tabController?.animateTo(3);
                      _selectedScreen = Screens.networkList;
                    },
                    child: Icon(Icons.add),
                  ),
                ],
              );
            })
                : SizedBox(),
            body: Stack(
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
                        EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // logo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/jpmorganlogo.svg',
                                  semanticsLabel: 'J.P.Morgan',
                                  height: 30,
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.two),
                            // title
                            Row(
                              children: [
                                Text(
                                  widget.companyName == ''
                                      ? LanguageService.getTranslated(context,
                                      "connections_user_connection_connections_tab")
                                      : '${LanguageService.getTranslated(context, "connections_user_connection_connections_tab")} ${widget.companyName.substring(0, 1).toUpperCase()}${widget.companyName.substring(1)}',
                                  style: CustomTypography.H5_Regular,
                                ),
                                SizedBox(width: CustomSpacing.two),
                                RatingBar(
                                  rating: 4,
                                ),
                                SizedBox(width: CustomSpacing.two),
                               Tooltip(
                                 // message is pointwise
                                  message: "• JP Morgan has a total of 6,234 locations.\n• 90% of the locations have above 3-star ratings.\n• 3,231 locations have a 5-star rating overall.\n• 4,820 locations have rooftop geocoding.",
                                  textStyle: CustomTypography.Subtitle1,
                                  child: Icon(
                                    Icons.info,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.two),
                            // description
                            RichText(text:
                              TextSpan(
                                text: '• ',
                                style: CustomTypography.Subtitle1,
                                children: [
                                  TextSpan(
                                    text: LanguageService.getTranslated(context, "locationlist_app_sub_title_description_pt_1"),
                                    style: CustomTypography.Subtitle1,
                                  ),
                                  TextSpan(
                                    text: widget.companyName == ''?"":'${widget.companyName.substring(0, 1).toUpperCase()}${widget.companyName.substring(1)}',
                                    style: CustomTypography.Subtitle1,
                                  ),
                                  TextSpan(
                                    text: LanguageService.getTranslated(context, "locationlist_app_sub_title_description_pt_2"),
                                    style: CustomTypography.Subtitle1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: CustomSpacing.two),
                            // search bar
                            Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: TextField(
                                    controller: _locationSearchController,
                                    onChanged: locationSearchClient,
                                    decoration: InputDecoration(
                                      hintText: LanguageService.getTranslated(context,
                                          'locationlist_search_field_hint_text'),
                                      label: Text(
                                          LanguageService.getTranslated(
                                              context, 'usermanagement_search_field_lable'),
                                          style: CustomTypography.Body1),
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
                                    //Show end drawer
                                    Scaffold.of(context).openEndDrawer();
                                  },
                                  child: Icon(
                                    Icons.filter_list,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            Consumer<ConnectionsProvider>(
                              builder: (context, connectionsProvider, child) {
                                return TabBar(
                                  isScrollable: true,
                                  controller: _tabController,
                                  labelStyle: CustomTypography
                                      .BottomNavigationActiveLabel,
                                  tabs: [
                                    Tab(
                                      child: InkWell(
                                        onTap: () {
                                          _tabController?.animateTo(0);
                                        },
                                        child:  Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Tab(
                                              text: LanguageService.getTranslated(
                                                  context,
                                                  "locationlist_app_connections_tab_all"),
                                            ),
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
                                                  "15",
                                                  style: CustomTypography
                                                      .BottomNavigationActiveLabel
                                                      .copyWith(height: -0.6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(1);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Tab(
                                            text: LanguageService.getTranslated(
                                                context,
                                                "locationlist_app_connections_tab_certified"),
                                          ),
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
                                                style: CustomTypography
                                                    .BottomNavigationActiveLabel
                                                    .copyWith(height: -0.6),
                                              ),
                                            ),
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
                                  _getLocationListAllUI(),
                                  _getlocationListCertifiedUI(),
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
            endDrawer: Drawer(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
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
                      // Search bar for filters, Eg items: Expandable container for Geographical, child items will be Country and State auto complete
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _filterNameController,
                          onChanged: (value) {
                            addFilter(value, 'name');
                          },
                          decoration: InputDecoration(
                            hintText: LanguageService.getTranslated(context,
                                'locationlist_search_field_hint_text'),
                            label: Text(
                                LanguageService.getTranslated(
                                    context, 'usermanagement_search_field_lable'),
                                style: CustomTypography.Body1),
                            hintStyle: CustomTypography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Example of the Geographical filter
                      // Country
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CountryListPick(
                          appBar: AppBar(
                            title: Text('Select Country', style: CustomTypography.Body1,),
                          ),
                          theme: CountryTheme(
                            isShowFlag: true,
                            isShowTitle: true,
                            isShowCode: true,
                            isDownIcon: true,
                            showEnglishName: true,
                          ),
                          initialSelection: '+1',
                          onChanged: (CountryCode? code) {
                            print('Country Code: ${code?.name}');
                            _selectedCountryCode = code?.phoneCode ?? '+1';
                          },
                        ),
                      ),
                      // State
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _filterEmailController,
                          onChanged: (value) {
                            addFilter(value, 'email');
                          },
                          decoration: InputDecoration(
                            hintText: LanguageService.getTranslated(context,
                                'locationlist_search_field_hint_text'),
                            label: Text(
                                LanguageService.getTranslated(
                                    context, 'usermanagement_search_field_lable'),
                                style: CustomTypography.Body1),
                            hintStyle: CustomTypography.Body1,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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

  void _showFiltersBottomSheet(BuildContext context) {
    // show modal bottom sheet using scaffold key
    */
/*showAdaptiveDialog(
      *//*
 */
/*shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),*//*
 */
/*
      context: context,
      builder: (context) {
        return ;
      },
    );*//*

    Scaffold.of(context).openEndDrawer();
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
*/
