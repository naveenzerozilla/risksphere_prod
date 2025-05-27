import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/components/rating_half_stars.dart';
import 'package:RiskSphere/design_system/components/rating_slider.dart';
import 'package:RiskSphere/providers/connections_provider.dart';
import 'package:RiskSphere/providers/location_list_provider.dart';
import 'package:RiskSphere/providers/location_profile_provider.dart';
import 'package:RiskSphere/screens/listings/add_location_screen.dart';
import 'package:RiskSphere/screens/listings/location_profile.dart';
import 'package:RiskSphere/screens/listings/widgets/animated_progress_indicatiors.dart';
import 'package:RiskSphere/screens/listings/widgets/listings_filter_screen.dart';
import 'package:RiskSphere/screens/listings/widgets/mapping_screen.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_button.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/rating_bar.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../models/location_list_model.dart';
import '../../providers/configuration_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:RiskSphere/models/role_model.dart' as roleModel;
import '../../providers/upload_sov_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../service/language_service.dart';
import '../../service/shared_preference_service.dart';
import 'widgets/geocoding_list_card.dart';

class LocationList extends StatefulWidget {
  final String userId;
  final String companyName;
  final String accountId;
  final String accountName;
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
    required this.accountName,
    required this.subAccountId,
    required this.subAccountName,
    required this.sovId,
    required this.sovName,
    required this.rating,
  });

  @override
  State<LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<LocationList>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.connectionList;
  // TextEditingController _locationSearchController = TextEditingController();
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
  bool isAllSelected = false; // State variable to manage "Select All"

  Timer? deBouncer;

  List<Location> selectedLocations = [];

  String? _uploadedFileName;
  TextEditingController _sovNameController = TextEditingController();
  late File files;
  String isMaintenance = "";

  TabController? _mainTabController;
  int selectedMainTab = 0;

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void locationSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      locationQuery = query;
      Provider.of<LocationListProvider>(context, listen: false)
          .fetchLocationList(
        context,
        widget.accountId,
        widget.subAccountId,
        widget.sovId,
        query,
        0,
        "forward",
        40,
        countries: [],
        // Add your filter parameters here
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

    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController?.addListener(() {
      setState(
          () {}); // This ensures that the widget rebuilds when the tab changes
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.index == 0) {
        _selectedScreen = Screens.locationList;
        Provider.of<LocationListProvider>(context, listen: false).page = 0;
        Provider.of<LocationListProvider>(context, listen: false)
            .fetchLocationList(
          context,
          widget.accountId,
          widget.subAccountId,
          widget.sovId,
          locationQuery,
          0,
          "forward",
          40,
        );
      } else {
        _selectedScreen = Screens.certifiedLocationList;
        Provider.of<LocationListProvider>(context, listen: false).page = 0;
        Provider.of<LocationListProvider>(context, listen: false)
            .fetchCertifiedLocationList(
          context,
          widget.accountId,
          widget.subAccountId,
          widget.sovId,
          locationQuery,
          0,
          40,
        );
      }
      setState(() {});
    });
    _getData();
  }

  @override
  void dispose() {
    // Cancel the debouncer timer if it's active
    deBouncer?.cancel();

    mobileController.dispose();
    _sovNameController.dispose();

    // Dispose TabControllers if not null
    _tabController?.dispose();
    _mainTabController?.dispose();
    _connectionsTabController?.dispose();

    // Nullify file if needed (no dispose, but cleanup reference)
    // files = null; // Optional, if you want to release it

    // Finally call super
    super.dispose();
  }

  void _getData() async {
    // Fetch data from API
    Provider.of<LocationListProvider>(context, listen: false)
        .fetchLocationList(
          context,
          widget.accountId,
          widget.subAccountId,
          widget.sovId,
          "",
          0,
          "forward",
          40,
          countries: [],
          // Add your filter parameters here
          state: "",
          propertyType: [],
          constructionType: [],
          certifications: [],
          hazard: [],
          rating: [],
        )
        .then((value) => setState(() {}));
    Provider.of<LocationListProvider>(context, listen: false)
        .fetchCertifiedLocationList(
      context,
      widget.accountId,
      widget.subAccountId,
      widget.sovId,
      "",
      0,
      40,
    );
    Provider.of<LocationListProvider>(context, listen: false)
        .fetchCampusIds(widget.accountId, widget.subAccountId, widget.sovId);
  }
  Future<void> _setClaims() async {
    final results = await Future.wait([
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASTC),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASTU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASCR),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASCO),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASUO),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMLL),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.CAMVU),
      SharedPreferenceService.getClaimForSubfeature(
          SharedPreferenceService.DASVR),
    ]);

    print(results.toString());

    print("results.toString()");



    bool showCorporateVerificationRequests = results[5] ?? false;
    bool showUserVerificationRequests = results[6] ?? false;


    _getData1();
    _getMaintainancePeriod();
    setState(() {});
  }
  Future<void> _getMaintainancePeriod() async {
    isMaintenance =
        await SharedPreferenceService.getScheduleInProgress() ?? "false";
  }
  Future<void> _getData1() async {
    final dashboardProvider =
    Provider.of<DashboardProvider>(context, listen: false);
    final userProfileProvider =
    Provider.of<UserProfileProvider>(context, listen: false);
    final configurationProvider =
    Provider.of<ConfigurationProvider>(context, listen: false);

    try {
      final results = await Future.wait([
        dashboardProvider.getDashboardData(context),
        userProfileProvider.getAllUserData(context, "", ""),
        configurationProvider.getConfiguration(
            accountId: null, subAccountId: null),
        configurationProvider.getVendors(),
      ]);

      userProfileProvider.fetchTrialInfo();

      var config = configurationProvider.configurations['result'] ?? {};
      // subscriptions = config['subscribe'] ?? {};

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            // vendorList = configurationProvider.vendors['result'] ?? [];
          });
        });
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  void searchNetworks(String query) async => debounce(() async {
        if (!mounted) return;
        /*await Provider.of<ConnectionsProvider>(context, listen: false)
        .getUserSuggestions(context, query);*/
      });

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
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
            ),
            drawer: CustomDrawer(),
            floatingActionButton: Builder(builder: (contextLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  !showSelectAll
                      ? SizedBox()
                      : FloatingActionButton(
                          onPressed: () {
                            if (selectedLocations.isEmpty) {
                              // Show a toast or snackbar message to select locations
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'No locations selected for deletion.'),
                                ),
                              );
                              return;
                            }

                            showDeleteConfirmationDialog(
                                context, _bulkDeleteLocations);
                          }, // Trigger bulk delete
                          child: Icon(Icons.delete), // Change icon to delete
                        ),
                  !showSelectAll
                      ? SizedBox()
                      : SizedBox(height: CustomSpacing.two),
                  SpeedDial(
                    icon: Icons.upload,
                    activeIcon: Icons.close,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    children: [
                      /*SpeedDialChild(
                        child: Icon(Icons.upload_file),
                        label: 'Upload Full List',
                        onTap: () {
                          // Add your logic for uploading full list
                          print('Upload Full List tapped');
                        },
                      ),*/
                      SpeedDialChild(
                        child: Icon(Icons.upload),
                        label: 'Upload Partial List',
                        onTap: () async {
                          setState(() {
                            _uploadedFileName = null;
                            _sovNameController.clear();
                          });
                          _showUploadDialog(widget.accountId,
                              widget.subAccountId, widget.sovId);
                        },
                      ),
                      SpeedDialChild(
                        child: Icon(Icons.add),
                        label: 'Add Single Location',
                        onTap: () {
                          _selectedScreen = Screens.addLocation;
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) =>
                                AddLocationScreen(
                              accountId: widget.accountId,
                              subAccountId: widget.subAccountId,
                              sovId: widget.sovId,
                              accountName: widget.companyName,
                              subAccountName: widget.subAccountName,
                            ),
                          ))
                              .then((value) {

                            _setClaims();
                            _getData();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            }),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/mesh.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          /*SizedBox(height: CustomSpacing.two),
                          Row(
                            children: [
                              Text(widget.companyName, style: typography.Body1),
                              Text(' > ', style: typography.Body1),
                              Text(widget.subAccountName, style: typography.Body1),
                              Text(' > ', style: typography.Body1),
                            ],
                          ),*/

                          SizedBox(height: CustomSpacing.two),
                          Container(
                            margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            padding: EdgeInsets.fromLTRB(8, 8, 0, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                // Set your border color here
                                width: 1.0, // Set the width of the border
                              ),
                              //color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            ),
                            child: Consumer<LocationListProvider>(builder:
                                (context, locationListProvider, child) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.sovName == ''
                                                ? ""
                                                : '${widget.sovName.substring(0, 1).toUpperCase()}${widget.sovName.substring(1)}',
                                            style: typography.Body1,
                                          ),
                                        ),
                                        SizedBox(width: CustomSpacing.two),
                                        RatingHalfStars(
                                          rating: widget.rating == ''
                                              ? 0
                                              : (double.parse(widget.rating) *
                                                      5) /
                                                  100,
                                          maxRating: 5,
                                          iconSize: 18,
                                        ),
                                        SizedBox(width: CustomSpacing.two),
                                        TooltipTheme(
                                          data: TooltipThemeData(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
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
                                                for (int i = 0;
                                                    i <
                                                        locationListProvider
                                                            .summaryList.length;
                                                    i++)
                                                  TextSpan(
                                                    text:
                                                        '• ${locationListProvider.summaryList[i]}\n',
                                                    style: typography.Subtitle1,
                                                  ),
                                              ],
                                              style: typography.Subtitle1,
                                            ),
                                            child: Icon(
                                              Icons.info,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(itemBuilder: (context) => []),
                                ],
                              );
                            }),
                          ),
                          SizedBox(height: CustomSpacing.two),
                          showSelectAll
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Checkbox(
                                      value: isAllSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          isAllSelected = value ?? false;
                                          if (isAllSelected) {
                                            // Select all locations
                                            selectedLocations = List.from(
                                                Provider.of<LocationListProvider>(
                                                        context,
                                                        listen: false)
                                                    .locationList);
                                          } else {
                                            // Deselect all locations
                                            selectedLocations.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      LanguageService.getTranslated(context,
                                          "locationlist_app_select_all"),
                                      style: typography.Body1,
                                    ),
                                  ],
                                )
                              : /*Row(
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
                                          style: typography.Body1),
                                      hintStyle: typography.Body1,
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
                          )*/
                              SizedBox(),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              borderRadius:
                                  BorderRadius.circular(16), // Rounded edges
                            ),
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            child: DefaultTabController(
                              length: 3,
                              child: Builder(builder: (context) {
                                return Column(
                                  children: <Widget>[
                                    // Container for the TabBar with arrows
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                      ),
                                      child: TabBar(
                                        controller: _mainTabController,
                                        dividerColor: Colors.transparent,
                                        indicatorPadding: EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 8.0),
                                        indicator: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          // Makes the tab rounded
                                          color: AppColors.primaryMain.withOpacity(
                                              0.16), // Background color for the selected tab
                                        ),
                                        //indicatorColor: Colors.lightBlueAccent,
                                        labelColor: AppColors.primaryMain,
                                        isScrollable: true,
                                        tabAlignment: TabAlignment.start,
                                        unselectedLabelColor: Colors.grey,
                                        tabs: [
                                          Tab(
                                            icon: _buildTabIcon(
                                              context,
                                              'assets/images/overall_tab_icon.svg',
                                              'Overall Score',
                                              0,
                                            ),
                                          ),
                                          Tab(
                                            icon: _buildTabIcon(
                                                context,
                                                'assets/images/geocoding_tab_icon.svg',
                                                'Geocoding Score',
                                                1),
                                          ),
                                          Tab(
                                            icon: _buildTabIcon(
                                                context,
                                                'assets/images/risk_tab_icon.svg',
                                                'Risk Score',
                                                2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          Consumer<LocationListProvider>(
                            builder: (context, locationListProvider, child) {
                              return TabBar(
                                controller: _tabController,
                                labelStyle:
                                    typography.BottomNavigationActiveLabel,
                                tabs: [
                                  Tab(
                                    child: InkWell(
                                      onTap: () {
                                        _tabController?.animateTo(0);
                                      },
                                      child: Row(
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
                                            child: Chip(
                                              labelPadding: EdgeInsets.all(0),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              label: Text(
                                                locationListProvider
                                                    .locationHits
                                                    .toString(),
                                                style: typography
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
                                      if (locationListProvider
                                          .isCertifiedTabAllowed()) {
                                        _tabController?.animateTo(1);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            "Please include a rating of 5 in filter to view certified locations.",
                                            style: typography.Body1,
                                          ),
                                        ));
                                      }
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
                                          child: Chip(
                                            labelPadding: EdgeInsets.all(0),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            label: Text(
                                              locationListProvider
                                                  .certifiedLocationHits
                                                  .toString(),
                                              style: typography
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
      ),
    );
  }

  Widget _buildTabIcon(
      BuildContext context, String iconPath, String label, int tabIndex) {
    // Check if TabController exists and whether this tab is selected
    bool isSelected = _mainTabController?.index == tabIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      // Adjust padding to control spacing
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            height: 36,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? AppColors.primaryMain
                  : Colors.white.withOpacity(0.56),
              BlendMode.srcIn,
            ),
          ),
          if (isSelected) ...[
            SizedBox(width: 4), // Reduce the space between icon and label
            Text(
              label,
              style: TextStyle(
                color: AppColors.primaryMain,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  _getLocationListAllUI() {
    var typography = CustomTypography(context);
    return Consumer<LocationListProvider>(
      builder: (context, locationListProvider, child) {
        return Container();
        //   locationListProvider.isLoading
        //     ? Column(
        //         children: [
        //           SizedBox(
        //             height: 100,
        //           ),
        //           Center(
        //             child: CircularProgressIndicator(),
        //           ),
        //         ],
        //       )
        //     : locationListProvider.locationList.isEmpty
        //         ? Center(
        //             child: Text(
        //               LanguageService.getTranslated(
        //                   context, "location_list_app_no_accounts_text"),
        //               style: typography.Body1,
        //             ),
        //           )
        //         :
        // ListView.builder(
        //             physics: ClampingScrollPhysics(),
        //             shrinkWrap: true,
        //             itemCount: locationListProvider.locationList.length,
        //             itemBuilder: (context, index) {
        //               if (index ==
        //                   locationListProvider.locationList.length - 1) {
        //                 // Check if it's the last item
        //                 if (locationListProvider.isNextPageLoading) {
        //                   // Display loading indicator
        //                   return Padding(
        //                     padding: const EdgeInsets.all(8.0),
        //                     child: Center(
        //                       child: CircularProgressIndicator(),
        //                     ),
        //                   );
        //                 } else if (locationListProvider.page >=
        //                         locationListProvider.totalPages &&
        //                     locationListProvider.locationList.isNotEmpty) {
        //                   // Display end of list message
        //                   print(
        //                       "location list: ${locationListProvider.locationList}");
        //                   return Column(
        //                     children: [
        //                       locationListCard(
        //                           index, locationListProvider.locationList),
        //                       Padding(
        //                         padding: const EdgeInsets.all(8.0),
        //                         child: Center(
        //                           child: Text(
        //                             LanguageService.getTranslated(
        //                                 context, "location_list_end_of_list"),
        //                             style: typography.Body1,
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   );
        //                 } else {
        //                   // Trigger fetching the next page
        //                   locationListProvider.page =
        //                       locationListProvider.page + 1;
        //                   print("Fetching page ${locationListProvider.page}");
        //                   print(
        //                       "Query: $locationQuery, Page: ${locationListProvider.page}");
        //                   locationListProvider.fetchLocationList(
        //                     context,
        //                     widget.accountId,
        //                     widget.subAccountId,
        //                     widget.sovId,
        //                     locationQuery,
        //                     // Pass the search query if any
        //                     locationListProvider.page,
        //                     "forward",
        //                     40,
        //                     // Page size
        //                     countries: [],
        //                     // Add your filter parameters here
        //                     state: "",
        //                     propertyType: [],
        //                     constructionType: [],
        //                     certifications: [],
        //                     hazard: [],
        //                     rating: [],
        //                   );
        //                   return SizedBox();
        //                 }
        //               }
        //
        //               return
        //                 locationListCard(
        //                   index, locationListProvider.locationList);
        //             },
        //           );
      },
    );
  }

  Widget locationListCard(int index, List<Location> locationList) {
    var typography = CustomTypography(context);
    return InkWell(
      onTap: () {
        print('Going to page $index');
        deBouncer!.cancel();
        var locationListProvider =
            Provider.of<LocationListProvider>(context, listen: false);
        // Open location details screen
        Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext newContext) => LocationProfile(

            accountId: widget.accountId,
            accountName: widget.companyName,
            subAccountId: widget.subAccountId,
            subAccountName: widget.subAccountName,
            sovId: widget.sovId,
            sovName: widget.sovName,
            searchQuery: locationQuery,
            page: (index).toString(),
            totalPages: locationListProvider.locationHits.toString(),

          ),
        ))
            .then((_) {

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
            leading: showSelectAll
                ? Checkbox(
                    value: selectedLocations.contains(locationList[index]),
                    onChanged: (isSelected) {
                      setState(() {
                        if (isSelected == true) {
                          selectedLocations.add(locationList[index]);
                        } else {
                          selectedLocations.remove(locationList[index]);
                        }

                        // Update the select all checkbox
                        isAllSelected =
                            selectedLocations.length == locationList.length;
                      });
                    },
                  )
                : null,
            title: Row(
              children: [
                (locationList[index].score ?? 0) == 5
                    ? Container(
                        margin: EdgeInsets.only(right: 8),
                        child: SvgPicture.asset(
                          'assets/images/certified.svg',
                          semanticsLabel: 'Verified',
                          height: 35,
                        ),
                      )
                    : SizedBox(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationList[index].locationIdForRef ?? '',
                      style: typography.Body1,
                    ),
                    locationList[index].campusId != null &&
                            locationList[index].campusId!.isNotEmpty
                        ? Chip(
                            padding: EdgeInsets.all(0),
                            label: Text(
                              locationList[index].campusId ?? '',
                              style: typography.Subtitle2,
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
                Spacer(),
                SizedBox(width: CustomSpacing.four),
                AnimatedProgressIndicator(
                  percent: locationList[index].percent ?? "0",
                ),
              ],
            ),
            children: [
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Geocoding', style: typography.Body1),
                    RatingSlider(
                      progress: locationList[index].score ?? 0,
                      total: 5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      progressColor: [
                        Colors.red[800]!,
                        Colors.orange[100]!,
                        Colors.blue[200]!,
                        Colors.green[200]!,
                        Colors.yellow[100]!
                      ][(locationList[index].score ?? 1) - 1],
                      thumbColor: [
                        Colors.red[800]!,
                        Colors.orange[800]!,
                        Colors.blue[700]!,
                        Colors.green[800]!,
                        Colors.yellow[700]!
                      ][(locationList[index].score ?? 1) - 1],
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hazard', style: typography.Body1),
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
                    Text('Occupancy', style: typography.Body1),
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
                    Text('Construction', style: typography.Body1),
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
    var typography = CustomTypography(context);
    return Consumer<LocationListProvider>(
      builder: (context, locationListProvider, child) {
        return locationListProvider.isLoading
            ? Column(
                children: [
                  SizedBox(height: 100),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : locationListProvider.certifiedLocationList.isEmpty
                ? Center(
                    child: Text(
                        LanguageService.getTranslated(
                            context, "location_list_app_no_accounts_text"),
                        style: typography.Body1),
                  )
                : ListView.builder(
                    physics: ClampingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        locationListProvider.certifiedLocationList.length,
                    itemBuilder: (context, index) {
                      if (index ==
                          locationListProvider.certifiedLocationList.length -
                              1) {
                        if (locationListProvider.isNextPageLoading) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (locationListProvider.page >=
                                locationListProvider.totalPages &&
                            locationListProvider
                                .certifiedLocationList.isNotEmpty) {
                          return Column(
                            children: [
                              locationListCard(index,
                                  locationListProvider.certifiedLocationList),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                        LanguageService.getTranslated(context,
                                            "location_list_end_of_list"),
                                        style: typography.Body1)),
                              ),
                            ],
                          );
                        } else {
                          locationListProvider.page =
                              locationListProvider.page + 1;
                          locationListProvider.fetchCertifiedLocationList(
                            context,
                            widget.accountId,
                            widget.subAccountId,
                            widget.sovId,
                            locationQuery,
                            locationListProvider.page,
                            40,
                          );
                          return SizedBox();
                        }
                      }

                      /*return locationListCard(index,
                locationListProvider.certifiedLocationList);*/
                      return GeoCodingListCard();
                    },
                  );
      },
    );
  }

  void showDeleteConfirmationDialog(BuildContext context, Function onDelete) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.paperElevation2, // Dark background
          title: Text(
            'Are you sure you want to delete specified locations?',
            style: TextStyle(color: Colors.white), // White text
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 50,
              ),
              SizedBox(height: 16),
              Text(
                'This action is irreversible. Please proceed with caution.',
                style: TextStyle(color: Colors.white70), // Light grey text
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white), // White text
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            Consumer<LocationListProvider>(
                builder: (context, locationListProvider, child) {
              return locationListProvider.isDeleteLocationLoading
                  ? CircularProgressIndicator()
                  : CustomButton(
                      type: ButtonType.danger,
                      child: Text('Delete',
                          style: typography.Body1.copyWith(
                              fontWeight: FontWeight.w500)),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        onDelete(); // Trigger the delete action
                      },
                    );
            }),
          ],
        );
      },
    );
  }

  Future<void> _bulkDeleteLocations() async {
    var typography = CustomTypography(context);
    try {
      // Construct the list of location details for deletion
      List<Map<String, String>> locationList =
          selectedLocations.map((location) {
        return {
          "location_id": location.locationId ?? '',
          "owner_id": widget.userId, // Assuming owner_id is userId
        };
      }).toList();

      // Make API call to delete locations
      await Provider.of<LocationListProvider>(context, listen: false)
          .deleteLocations(context, widget.accountId, widget.subAccountId,
              widget.sovId, locationList);

      // Clear selections
      setState(() {
        selectedLocations.clear();
        showSelectAll = false;
        isAllSelected = false;
      });
    } catch (e) {
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete locations: ${e.toString()}')),
      );
    }
  }

  void _showUploadDialog(String accountId, String subAccountId, String sovId) {
    var typography = CustomTypography(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                return false; // Disable the back button
              },
              child: AlertDialog(
                backgroundColor: Colors.black87,
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Upload Partial List",
                          textAlign: TextAlign.start, style: typography.Body1),
                      SizedBox(height: 20),
                      _uploadedFileName == null
                          ? GestureDetector(
                              onTap: () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['xls', 'xlsx'],
                                );
                                if (result != null) {
                                  File file = File(result.files.single.path!);
                                  setState(() {
                                    files = file;
                                    String fileNameWithExtension =
                                        file.path.split('/').last;
                                    _uploadedFileName =
                                        fileNameWithExtension.split('.').first;
                                    _sovNameController.text =
                                        _uploadedFileName!;
                                  });
                                }
                              },
                              child: Container(
                                height: 150,
                                width: MediaQuery.of(context).size.width / 1.2,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          color: Colors.white),
                                      SizedBox(height: 10),
                                      Text(
                                        LanguageService.getTranslated(context,
                                            "account_list_app_account_upload_drag_and_drop"),
                                        style: typography.Body1,
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.white54),
                                          SizedBox(width: 3),
                                          Text('Max file size is 200 MB',
                                              style: typography.Body1),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 150,
                              width: MediaQuery.of(context).size.width / 1.2,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.description, size: 25),
                                  SizedBox(height: 10),
                                  Text(
                                    _sovNameController.text,
                                    style: typography.Body1,
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedFileName = null;
                                        _sovNameController.clear();
                                      });
                                    },
                                    child: Text(
                                      LanguageService.getTranslated(context,
                                          "account_list_app_cancel_text"),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                ],
                              ),
                            ),
                      SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer<LocationListProvider>(
                              builder: (_, locationListProvider, child) {
                            return locationListProvider.isImageUploadLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: CustomButton(
                                      onPressed: () async {
                                        String success = (await Provider.of<
                                                    LocationListProvider>(
                                                context,
                                                listen: false)
                                            .uploadSovAccount(
                                                context,
                                                files,
                                                accountId,
                                                subAccountId,
                                                sovId));

                                        print('Success: $success');
                                        // contain symbol +
                                        if (success.isNotEmpty &&
                                            success.contains('+')) {
                                          print('Inside + success: $success');
                                          // Show popup with title Empty SoV, body: Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort? with 2 buttons: [create empty SOV]   [abort]
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                    /*LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_empty_sov_title")*/
                                                    'Empty SOV',
                                                    style:
                                                        typography.H5_Regular,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        /* LanguageService.getTranslated(
                                                            context,
                                                            "account_list_app_empty_sov_text"),*/
                                                        'Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort?',
                                                        style: typography.Body1,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            CustomSpacing.two,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Consumer<
                                                                  UploadSovProvider>(
                                                              builder: (context,
                                                                  uploadSovProvider,
                                                                  child) {
                                                            return uploadSovProvider
                                                                    .isLoading
                                                                ? const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  )
                                                                : CustomButton(
                                                                    onPressed:
                                                                        () async {
                                                                      // Create empty SOV
                                                                      var provider = Provider.of<
                                                                              UploadSovProvider>(
                                                                          context,
                                                                          listen:
                                                                              false);
                                                                      await provider.createEmptySov(
                                                                          context,
                                                                          success);
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Text(
                                                                      /*LanguageService.getTranslated(
                                                                      context,
                                                                      "account_list_app_empty_sov_create"),*/
                                                                      'Create',
                                                                      style: typography
                                                                          .ButtonLarge,
                                                                    ),
                                                                    type: ButtonType
                                                                        .elevated,
                                                                  );
                                                          }),
                                                          CustomButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              /*LanguageService.getTranslated(
                                                                  context,
                                                                  "account_list_app_empty_sov_abort")*/
                                                              'Abort',
                                                              style: typography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                                ButtonType.text,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              });
                                        } else if (success.isNotEmpty) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => MappingScreen(
                                                    subAccountName: widget.subAccountName ??"",
                                                        tempId: success,
                                                        accountId:
                                                            widget.accountId,
                                                        accountName: widget
                                                                .accountName ??
                                                            "",

                                                      )));
                                        }
                                      },
                                      type: ButtonType.filled,
                                      child: Text(
                                        LanguageService.getTranslated(
                                            context, "login_submit_button"),
                                        style: typography.ButtonLarge,
                                      ),
                                    ),
                                  );
                          }),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.2,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _uploadedFileName = null;
                                  _sovNameController.clear();
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                  LanguageService.getTranslated(
                                      context, "account_list_app_cancel_text"),
                                  style: typography.Body1),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}
