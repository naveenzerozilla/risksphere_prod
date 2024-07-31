import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/rating_slider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/providers/location_list_provider.dart';
import 'package:green/screens/listings/add_location_screen.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/listings/widgets/animated_progress_indicatiors.dart';
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
  final String accountId;
  final String subAccountId;
  final String subAccountName;
  final String sovId;
  final String sovName;
  final String rating;

  const LocationList({
    super.key,
    required this.userId,
    required this.companyName,
    required this.accountId,
    required this.subAccountId,
    required this.subAccountName,
    required this.sovId,
    required this.sovName,
    required this.rating,
  });

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList> with TickerProviderStateMixin {
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
  String locationQuery = '';

  bool showSelectAll = false;

  Timer? deBouncer;

  void debounce(VoidCallback callback, {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void locationSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      locationQuery = query;
      Provider.of<LocationListProvider>(context, listen: false).fetchLocationList(
        context,
        widget.accountId,
        widget.subAccountId,
        widget.sovId,
        query,
        0,
        40,
        countries: [], // Add your filter parameters here
        state: "",
        propertyType: [],
        constructionType: [],
        certifications: [],
        hazard: [],
        rating: [],
      );
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
        _selectedScreen = Screens.locationList;
      } else {
        _selectedScreen = Screens.certifiedLocationList;
      }
      setState(() {});
    });

    _getData();
  }

  _getData() async {
    // Fetch data from API
    Provider.of<LocationListProvider>(context, listen: false).fetchLocationList(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      "",
      0,
      40,
      countries: [], // Add your filter parameters here
      state: "",
      propertyType: [],
      constructionType: [],
      certifications: [],
      hazard: [],
      rating: [],
    );
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
                !showSelectAll
                    ? SizedBox()
                    : FloatingActionButton(
                  onPressed: () {},
                  child: Icon(Icons.upload_rounded),
                ),
                !showSelectAll ? SizedBox() : SizedBox(height: CustomSpacing.two),
                FloatingActionButton(
                  onPressed: () {
                    _selectedScreen = Screens.addLocation;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddLocationScreen(
                        accountId: widget.accountId,
                        subAccountId: widget.subAccountId,
                        sovId: widget.sovId,
                      ),
                    ));
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
              Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: CustomSpacing.two),
                        Row(
                          children: [
                            Text(widget.companyName, style: CustomTypography.Body1),
                            Text(' > ', style: CustomTypography.Body1),
                            Text(widget.subAccountName, style: CustomTypography.Body1),
                            Text(' > ', style: CustomTypography.Body1),
                          ],
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Consumer<LocationListProvider>(
                            builder: (context, locationListProvider, child) {
                              return Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.sovName == ''
                                          ? ""
                                          : '${widget.sovName.substring(0, 1).toUpperCase()}${widget.sovName.substring(1)}',
                                      style: CustomTypography.H5_Regular,
                                    ),
                                  ),
                                  SizedBox(width: CustomSpacing.two),
                                  RatingBar(
                                    rating: 0,
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
                                          for (int i = 0; i < locationListProvider.summaryList.length; i++)
                                            TextSpan(
                                              text: '• ${locationListProvider.summaryList[i]}\n',
                                              style: CustomTypography.Subtitle1,
                                            ),
                                        ],
                                        style: CustomTypography.Subtitle1,
                                      ),
                                      child: Icon(
                                        Icons.info,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                        ),
                        SizedBox(height: CustomSpacing.two),
                        Wrap(
                          children: [
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
                                    text: widget.companyName == ''
                                        ? ""
                                        : '${widget.companyName.substring(0, 1).toUpperCase()}${widget.companyName.substring(1)}',
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
                        SizedBox(height: CustomSpacing.two),
                        showSelectAll
                            ? Row(
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
                            : Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _locationSearchController,
                                  onChanged: locationSearchClient,
                                  decoration: InputDecoration(
                                    hintText: LanguageService.getTranslated(
                                        context, 'locationlist_search_field_hint_text'),
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
                            SizedBox(width: CustomSpacing.four),
                            Builder(builder: (context) {
                              return InkWell(
                                onTap: () {
                                  // Show end drawer
                                  Scaffold.of(context).openEndDrawer();
                                },
                                child: Icon(
                                  Icons.filter_list,
                                  size: 28,
                                ),
                              );
                            }),
                            SizedBox(width: CustomSpacing.four),
                          ],
                        ),
                        Consumer<LocationListProvider>(
                            builder: (context, locationListProvider, child) {
                              return TabBar(
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
                                                context, "locationlist_app_connections_tab_all"),
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
                                                locationListProvider.locationHits.toString(),
                                                style: CustomTypography.BottomNavigationActiveLabel
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
                                              context, "locationlist_app_connections_tab_certified"),
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
                                              style: CustomTypography.BottomNavigationActiveLabel
                                                  .copyWith(height: -0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        SizedBox(height: CustomSpacing.four),
                        Expanded(
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
                  ),
                ],
              ),
            ],
          ),
          endDrawer: Drawer(
            child: SafeArea(
              child: ListingsFilterScreen(
                accountId: widget.accountId,
                subAccountId: widget.subAccountId,
                sovId: widget.sovId,
                searchQuery: locationQuery,
              ),
            ),
          ),
        );
      },
    );
  }

  _getLocationListAllUI() {
    return Consumer<LocationListProvider>(
      builder: (context, locationListProvider, child) {
        return locationListProvider.isLoading
            ? Column(
          children: [
            SizedBox(
              height: 100,
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        )
            : locationListProvider.locationList.isEmpty
            ? Center(
          child: Text(
            LanguageService.getTranslated(
                context, "location_list_app_no_accounts_text"),
            style: CustomTypography.Body1,
          ),
        )
            : ListView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: locationListProvider.locationList.length,
          itemBuilder: (context, index) {
            if (index == locationListProvider.locationList.length - 1) {
              // Check if it's the last item
              if (locationListProvider.isNextPageLoading) {
                // Display loading indicator
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (locationListProvider.page >=
                  locationListProvider.totalPages &&
                  locationListProvider.locationList.isNotEmpty) {
                // Display end of list message
                print("location list: ${locationListProvider.locationList}");
                return Column(
                  children: [
                    locationListCard(index, locationListProvider),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          LanguageService.getTranslated(
                              context, "location_list_end_of_list"),
                          style: CustomTypography.Body1,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Trigger fetching the next page
                locationListProvider.page =
                    locationListProvider.page + 1;
                print("Fetching page ${locationListProvider.page}");
                print(
                    "Query: $locationQuery, Page: ${locationListProvider.page}");
                locationListProvider.fetchLocationList(
                  context,
                  widget.accountId,
                  widget.subAccountId,
                  widget.sovId,
                  locationQuery,
                  // Pass the search query if any
                  locationListProvider.page,
                  40, // Page size
                  countries: [], // Add your filter parameters here
                  state: "",
                  propertyType: [],
                  constructionType: [],
                  certifications: [],
                  hazard: [],
                  rating: [],
                );
                return SizedBox();
              }
            }

            return locationListCard(index, locationListProvider);
          },
        );
      },
    );
  }

  Widget locationListCard(int index, LocationListProvider locationListProvider) {
    return InkWell(
      onTap: () {
        // Open location details screen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LocationProfile(
            accountId: widget.accountId,
            accountName: widget.companyName,
            subAccountId: widget.subAccountId,
            subAccountName: widget.subAccountName,
            sovId: widget.sovId,
            sovName: widget.sovName,
            locationId: locationListProvider.locationList[index].locationId ?? "",
            locationName: locationListProvider.locationList[index].locationName ?? "",
            locationIdForRef: locationListProvider.locationList[index].locationIdForRef ?? "",
          ),
        )).then((_) {
          // Call getData after pop
          _getData();
        });
      },
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
            /*leading: CircleAvatar(
              backgroundColor: AppColors.paperElavation25,
              backgroundImage: locationListProvider.locationList[index].images?[0] != null &&
                  locationListProvider.locationList[index].images![0].isNotEmpty
                  ? NetworkImage(locationListProvider.locationList[index].images![0])
                  : null,
              child: locationListProvider.locationList[index].images?[0] == null ||
                  locationListProvider.locationList[index].images![0].isEmpty
                  ? SvgPicture.asset(
                'assets/images/locationDefaultIcon.svg', // Replace with your SVG asset path
                height: 25,
                fit: BoxFit.cover,
              )
                  : null,
            ),*/
            title: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationListProvider.locationList[index].locationIdForRef ?? '',
                      style: CustomTypography.Body1,
                    ),
                    locationListProvider.locationList[index].campusId!=null && locationListProvider.locationList[index].campusId!.isNotEmpty?
                    Chip(
                      padding: EdgeInsets.all(0),
                      label: Text(
                        locationListProvider.locationList[index].campusId?? '',
                        style: CustomTypography.Subtitle2,
                      ),
                    ): SizedBox(),
                  ],
                ),
                Spacer(),
                (locationListProvider.locationList[index].score ?? 0) == 5
                    ? SvgPicture.asset(
                  'assets/images/certified.svg',
                  semanticsLabel: 'Verified',
                  height: 35,
                )
                    : SizedBox(),
                SizedBox(width: CustomSpacing.four),
                AnimatedProgressIndicator(
                  percent: locationListProvider.locationList[index].percent ?? "0",
                ),
              ],
            ),
            children: [
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Geocoding', style: CustomTypography.Body1),
                    RatingSlider(
                      progress: locationListProvider.locationList[index].score ?? 0,
                      total: 5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      progressColor: [
                        Colors.red[800]!,
                        Colors.orange[100]!,
                        Colors.blue[200]!,
                        Colors.green[200]!,
                        Colors.yellow[100]!
                      ][(locationListProvider.locationList[index].score ?? 1) - 1],
                      thumbColor: [
                        Colors.red[800]!,
                        Colors.orange[800]!,
                        Colors.blue[700]!,
                        Colors.green[800]!,
                        Colors.yellow[700]!
                      ][(locationListProvider.locationList[index].score ?? 1) - 1],
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hazard', style: CustomTypography.Body1),
                    RatingSlider(
                      progress: 5,
                      total: 5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      isDisabled: true,
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
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Occupancy', style: CustomTypography.Body1),
                    RatingSlider(
                      progress: 5,
                      total: 5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      isDisabled: true,
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
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Construction', style: CustomTypography.Body1),
                    RatingSlider(
                      progress: 5,
                      total: 5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      isDisabled: true,
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
                      textColor: Colors.white,
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

  _getLocationListCertifiedUI() {
    return Consumer<LocationListProvider>(
      builder: (context, locationListProvider, child) {
        return locationListProvider.isLoading
            ? Column(
          children: [
            SizedBox(
              height: 100,
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        )
            : locationListProvider.locationList.isEmpty
            ? Center(
          child: Text(
            LanguageService.getTranslated(
                context, "location_list_app_no_accounts_text"),
            style: CustomTypography.Body1,
          ),
        )
            : ListView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: locationListProvider.locationList.length,
          itemBuilder: (context, index) {
            if (index == locationListProvider.locationList.length - 1) {
              // Check if it's the last item
              if (locationListProvider.isNextPageLoading) {
                // Display loading indicator
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (locationListProvider.page >=
                  locationListProvider.totalPages &&
                  locationListProvider.locationList.isNotEmpty) {
                // Display end of list message
                print("location list: ${locationListProvider.locationList}");
                return Column(
                  children: [
                    locationListCard(index, locationListProvider),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          LanguageService.getTranslated(
                              context, "location_list_end_of_list"),
                          style: CustomTypography.Body1,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Trigger fetching the next page
                locationListProvider.page =
                    locationListProvider.page + 1;
                print("Fetching page ${locationListProvider.page}");
                print(
                    "Query: $locationQuery, Page: ${locationListProvider.page}");
                locationListProvider.fetchLocationList(
                  context,
                  widget.accountId,
                  widget.subAccountId,
                  widget.sovId,
                  locationQuery,
                  // Pass the search query if any
                  locationListProvider.page,
                  40, // Page size
                  countries: [], // Add your filter parameters here
                  state: "",
                  propertyType: [],
                  constructionType: [],
                  certifications: [],
                  hazard: [],
                  rating: [],
                );
                return SizedBox();
              }
            }

            return locationListCard(index, locationListProvider);
          },
        );
      },
    );
  }
}
