import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/rating_slider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/screens/listings/add_location_screen.dart';
import 'package:green/screens/listings/widgets/listings_filter_screen.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
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
  TextEditingController mobileController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TabController? _connectionsTabController;

  int requestActionIndex = 0;

  List<roleModel.Roles> filterRoleList = [];

  List<roleModel.Roles> filterRoles = [];
  List<String> filterNames = [];
  List<String> filterEmails = [];
  List<String> filterPhones = [];
  List<String> filterCompanies = [];
  List<String> filterStatus = [];
  roleModel.Roles? selectedRoleForFilter;
  String selectedStatus = '';

  bool showSelectAll = false;

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
bool isSearch = searchText.isNotEmpty ||
            filterCompanies.isNotEmpty ||
            filterRoles.isNotEmpty;


      await Provider.of<ConnectionsProvider>(context, listen: false)
          .getAllConnections(context, widget.userId,
          searchText: searchText,
          companyType: companyTypeFilter,
          roleFilter: roleFilter,
          isSearch: isSearch);
    });
  }


  @override
  void initState() {
    super.initState();
    print('User ID: ${widget.userId}');
    print('User Name: ${widget.companyName}');
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        // Call API

      } else if (_tabController?.index == 1) {
        // Call API
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

  }

  void searchNetworks(String query) async => debounce(() async {
    if (!mounted) return;
    /*await Provider.of<ConnectionsProvider>(context, listen: false)
        .getUserSuggestions(context, query);*/
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
            floatingActionButton: Builder(builder: (contextLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  !showSelectAll?SizedBox():FloatingActionButton(
                    onPressed: () {
                    },
                    child: Icon(Icons.upload_rounded),
                  ),
                  !showSelectAll?SizedBox():SizedBox(
                    height: CustomSpacing.two,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      _selectedScreen = Screens.addLocation;
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddLocationScreen()));
                    },
                    child: Icon(Icons.add),
                  ),
                ],
              );
            }),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/mesh.png',
                    fit: BoxFit.cover,
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      forceMaterialTransparency: true,
                      pinned: true,
                      expandedHeight: 250.0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                          children: [
                            SizedBox(height: CustomSpacing.two),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.companyName == ''
                                        ? ""
                                        : '${widget.companyName.substring(0, 1).toUpperCase()}${widget.companyName.substring(1)}',
                                    style: CustomTypography.H5_Regular,
                                  ),
                                ),
                                SizedBox(width: CustomSpacing.two),
                                RatingBar(
                                  rating: 4,
                                ),
                                SizedBox(width: CustomSpacing.two),
                                TooltipTheme(
                                  data: TooltipThemeData(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                    padding: EdgeInsets.all(8),
                                    verticalOffset: 20,
                                    preferBelow: false,
                                  ),
                                  child: Tooltip(
                                    showDuration: Duration(seconds: 5),
                                    triggerMode: TooltipTriggerMode.tap,
                                    preferBelow: true,
                                    richMessage: TextSpan(
                                      children: [
                                        TextSpan(text: '• JP Morgan has a total of 6,234 locations.\n'),
                                        TextSpan(text: '• 90% of the locations have above 3-star ratings.\n'),
                                        TextSpan(text: '• 3,231 locations have a 5-star rating overall.\n'),
                                        TextSpan(text: '• 4,820 locations have rooftop geocoding.'),
                                      ],
                                      style: CustomTypography.Subtitle1,
                                    ),
                                    child: Icon(
                                      Icons.info,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: CustomSpacing.two),
                            RichText(
                              text: TextSpan(
                                text: '',
                                style: CustomTypography.Subtitle1,
                                children: [
                                  TextSpan(
                                    text: LanguageService.getTranslated(context, "locationlist_app_sub_title_description_pt_1"),
                                    style: CustomTypography.Subtitle1,
                                  ),
                                  TextSpan(
                                    text: widget.companyName == '' ? "" : '${widget.companyName.substring(0, 1).toUpperCase()}${widget.companyName.substring(1)}',
                                    style: CustomTypography.Subtitle1,
                                  ),
                                  TextSpan(
                                    text: LanguageService.getTranslated(context, "locationlist_app_sub_title_description_pt_2"),
                                    style: CustomTypography.Subtitle1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: Size.fromHeight(60.0),
                        child: Column(
                          children: [
                            showSelectAll ?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Checkbox(
                                  value: false,
                                  onChanged: (value) {
                                    // Select all from model or deselect all from model
                                  },
                                ),
                                Text(
                                  LanguageService.getTranslated(context, "locationlist_app_select_all"),
                                  style: CustomTypography.Body1,
                                ),
                              ],
                            )
                                :
                            Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: SizedBox(
                                    height: 50,
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
                            TabBar(
                              controller: _tabController,
                              labelStyle: CustomTypography.BottomNavigationActiveLabel,
                              tabs: [
                                Tab(
                                  child: InkWell(
                                    onTap: () {
                                      _tabController?.animateTo(0);
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                            MaterialTapTargetSize.shrinkWrap,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                          MaterialTapTargetSize.shrinkWrap,
                                          label: Text(
                                            "5",
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _getLocationListAllUI(),
                          _getLocationListCertifiedUI(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            endDrawer: Drawer(
              child: SafeArea(
                child: ListingsFilterScreen(),
              ),
            ),
          );
        });
  }


  _getLocationListAllUI() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      itemBuilder: (context, index) {
        return index == 0?Column(
          children: [
            SizedBox(height: CustomSpacing.six),
            locationListCard(index)
          ],
        ):
        locationListCard(index);
      },
    );
  }

  Widget locationListCard(int index) {
    return InkWell(
      onLongPress: () {
        setState(() {
          showSelectAll = !showSelectAll;
        });
      },
      child: Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.paperElavation25,
                child: Text(
                  'JP',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Row(
                children: [
                  Text('RS/0000$index'),
                  Spacer(),

                  SvgPicture.asset(
                    'assets/images/certified.svg',
                    semanticsLabel: 'Verified',
                    height: 35,
                  ),
                  SizedBox(width: CustomSpacing.four),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          value: 0.5,
                          backgroundColor: Color(0x12FFFFFF),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
                          strokeWidth: 4,
                        ),
                      ),
                      Text(
                          '50%',
                          style: CustomTypography.Subtitle2.copyWith(
                            color: AppColors.primaryMain,
                            fontSize: 10,
                          )
                      ),
                    ],
                  ),
                ],
              ),

              children: [
                ListTile(
                  title: Text('Geocoding'),
                  subtitle:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      RatingSlider(progress: 5, total: 5,
                        width: MediaQuery.of(context).size.width * 0.79,
                        progressColor: [
                          Colors.red[800]!,
                          Colors.orange[100]!,
                          Colors.blue[200]!,
                          Colors.green[200]!,
                          Colors.yellow[100]!
                        ][4],
                        thumbColor: [
                          Colors.red[800]!,
                          Colors.orange[800]!,
                          Colors.blue[700]!,
                          Colors.green[800]!,
                          Colors.yellow[700]!
                        ][4],
                        textColor: Colors.white,),
                    ],
                  ),


                ),
                ListTile(
                  title: Text('Hazard'),
                  subtitle:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      RatingSlider(progress: 5, total: 5,
                        width: MediaQuery.of(context).size.width * 0.79,
                        progressColor: [
                          Colors.red[800]!,
                          Colors.orange[100]!,
                          Colors.blue[200]!,
                          Colors.green[200]!,
                          Colors.yellow[100]!
                        ][4],
                        thumbColor: [
                          Colors.red[800]!,
                          Colors.orange[800]!,
                          Colors.blue[700]!,
                          Colors.green[800]!,
                          Colors.yellow[700]!
                        ][4],
                        textColor: Colors.white,),
                    ],
                  ),


                ),
                ListTile(
                  title: Text('Occupancy'),
                  subtitle:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      RatingSlider(progress: 5, total: 5,
                        width: MediaQuery.of(context).size.width * 0.79,
                        progressColor: [
                          Colors.red[800]!,
                          Colors.orange[100]!,
                          Colors.blue[200]!,
                          Colors.green[200]!,
                          Colors.yellow[100]!
                        ][4],
                        thumbColor: [
                          Colors.red[800]!,
                          Colors.orange[800]!,
                          Colors.blue[700]!,
                          Colors.green[800]!,
                          Colors.yellow[700]!
                        ][4],
                        textColor: Colors.white,),
                    ],
                  ),


                ),
                ListTile(
                  title: Text('Construction'),
                  subtitle:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: CustomSpacing.four),
                      RatingSlider(progress: 5, total: 5,
                        width: MediaQuery.of(context).size.width * 0.79,
                        progressColor: [
                          Colors.red[800]!,
                          Colors.orange[100]!,
                          Colors.blue[200]!,
                          Colors.green[200]!,
                          Colors.yellow[100]!
                        ][4],
                        thumbColor: [
                          Colors.red[800]!,
                          Colors.orange[800]!,
                          Colors.blue[700]!,
                          Colors.green[800]!,
                          Colors.yellow[700]!
                        ][4],
                        textColor: Colors.white,),
                    ],
                  ),


                ),
              ],
            ),
          ),
        ),
    );
  }

  _getLocationListCertifiedUI() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemCount: 10,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return index == 0?Column(
          children: [
            SizedBox(height: CustomSpacing.six),
            locationListCard(index)
          ],
        ):
        locationListCard(index);
      },
    );
  }
}
