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
import '../../providers/theme_provider.dart';

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ConnectionsScreen(
      {super.key, required this.userId, required this.userName});

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

  @override
  void initState() {
    super.initState();
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

    _connectionsTabController = TabController(length: 2, vsync: this);
    _connectionsTabController?.addListener(() {
      print('Connections Tab Index: ${_connectionsTabController?.index}');
    });
    _getData();
  }

  _getData() {
    // Fetch data from API
    Provider.of<ConnectionsProvider>(context, listen: false)
        .getAllConnections(context, widget.userId);
    Provider.of<ConnectionsProvider>(context, listen: false)
        .getAllRequests(context, widget.userId);
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
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      // Open bottom sheet of filters
                      _showFiltersBottomSheet(_scaffoldKey.currentContext!);
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
              )
            : SizedBox(),
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
                _tabController?.animateTo(0);
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
                          EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Connections of ${widget.userName.substring(0, 1).toUpperCase()}${widget.userName.substring(1)}',
                              style: CustomTypography.H5_Regular),
                          SizedBox(height: CustomSpacing.two),
                          Text('Manage all connections from this panel',
                              style: CustomTypography.Body2),
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          Consumer<ConnectionsProvider>(
                              builder: (context, connectionsProvider, child) {
                            return TabBar(
                              isScrollable: true,
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // make tab dropdown with title connections but user can select from corporate and non corporate
                                        Tab(
                                          child: DropdownButton(
                                            alignment: Alignment.center,
                                            underline: Container(),
                                            isDense: true,
                                            hint: Text('Connections',
                                                style: CustomTypography.Body1
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? AppColors.white
                                                            : AppColors.black)),
                                            items: [
                                              DropdownMenuItem(
                                                child: Text('Corporate',
                                                    style: CustomTypography.Body1
                                                        .copyWith(
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? AppColors
                                                                    .white
                                                                : AppColors
                                                                    .black)),
                                                value: 'Corporate',
                                              ),
                                              DropdownMenuItem(
                                                child: Text('Non Corporate',
                                                    style: CustomTypography.Body1
                                                        .copyWith(
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? AppColors
                                                                    .white
                                                                : AppColors
                                                                    .black)),
                                                value: 'Non Corporate',
                                              ),
                                            ],
                                            onChanged: (String? value) {
                                              setState(() {
                                                if (value == 'Corporate') {
                                                  _selectedScreen = Screens
                                                      .corporateConnectionList;
                                                } else if (value ==
                                                    'Non Corporate') {
                                                  _selectedScreen = Screens
                                                      .nonCorporateConnectionList;
                                                }
                                              });
                                            },
                                          ),
                                        ),
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
                                                  .totalConnections,
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
                                    _selectedScreen = Screens.requestList;
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tab(
                                        text: 'Requests',
                                      ),
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      SizedBox(
                                        height: 25,
                                        width: 35,
                                        child: Chip(
                                          labelPadding: EdgeInsets.all(0),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                                InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(2);
                                    _selectedScreen = Screens.chatList;
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tab(
                                        text: 'Chats',
                                      ),
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      SizedBox(
                                        height: 25,
                                        width: 35,
                                        child: Chip(
                                          labelPadding: EdgeInsets.all(0),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          label: Text(
                                            '0',
                                            style: CustomTypography
                                                    .BottomNavigationActiveLabel
                                                .copyWith(height: -0.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(3);
                                    _selectedScreen = Screens.networkList;
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tab(
                                        text: 'Networking',
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tab(
                                        text: 'Blocked',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),

                          // Add 3 tab views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Connections
                                _getConnectionsUI(),
                                // Requests
                                _getRequestsUI(),
                                // Chats
                                _getChatsUI(),
                                // Networking
                                _getNetworkingUI(),
                                //Blocked
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

  _getConnectionsUI() {
    return Column(
      children: [
        SizedBox(
          height: CustomSpacing.two,
        ),
        _selectedScreen == Screens.corporateConnectionList
            ? _getCorporateConnectionsUI()
            : _getNonCorporateConnectionsUI(),
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
                          child: Text("No corporate connections"),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount:
                          connectionsProvider.corporateConnections.length,
                      itemBuilder: (context, index) {
                        return _corporateConnectionsCardUI(
                            connectionsProvider, index);
                      },
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
                          child: Text("No non corporate connections"),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount:
                          connectionsProvider.nonCorporateConnections.length,
                      itemBuilder: (context, index) {
                        return _nonCorporateConnectionsCardUI(
                            connectionsProvider, index);
                      },
                    );
        },
      ),
    );
  }

  Widget _connectionsCardUIOLD() {
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
                      style: CustomTypography.Body2.copyWith(
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
                            Text('Amit Didwania',
                                style: CustomTypography.Body1),
                            SizedBox(height: CustomSpacing.two),
                            Text('Risk Manager', style: CustomTypography.Body2),
                            Text('Green', style: CustomTypography.Body2),
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
                          'Request Pending',
                          style: CustomTypography.Body2.copyWith(
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
                              style: CustomTypography.Body2.copyWith(
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
                                style: CustomTypography.Caption),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: CustomSpacing.two,
                      ),
                      // show like 4 (Star icon)
                      Row(
                        children: [
                          Text(
                            connectionsProvider
                                    .corporateConnections[index].rating
                                    ?.toString() ??
                                "",
                            style: CustomTypography.Caption,
                          ),
                          Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 28,
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
                            connectionsProvider
                                    .corporateConnections[index].companyName ??
                                "",
                            style: CustomTypography.Body2.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black),
                          ),
                          Text(
                              connectionsProvider
                                      .corporateConnections[index].role?[0] ??
                                  "",
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
                              style: CustomTypography.Caption.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black)),
                        ),
                        Spacer(),
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
                        IconButton(
                          onPressed: () {
                            // Handle send message
                          },
                          icon: Icon(Icons.mail),
                          color: AppColors.primaryMain,
                        ),
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
                        IconButton(
                          icon: Icon(Icons.exit_to_app_outlined),
                          color: AppColors.primaryMain,
                          onPressed: () {},
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
    );
  }

  Widget _nonCorporateConnectionsCardUI(
      ConnectionsProvider connectionsProvider, int index) {
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
                          'Request Pending',
                          style: CustomTypography.Body2.copyWith(
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
                              style: CustomTypography.Body2.copyWith(
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
                                style: CustomTypography.Caption),
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
                                style: CustomTypography.Body1,
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 20,
                              ),
                              Text(
                                '\'s',
                                style: CustomTypography.Body1,
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
                            style: CustomTypography.Body2.copyWith(
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
                                  style: CustomTypography.Caption)
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
                        (connectionsProvider.nonCorporateConnections[index]
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
                                label: Text('View Connections',
                                    style: CustomTypography.Caption.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.white
                                            : AppColors.black)),
                              ),
                        (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : Spacer(),
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
                        (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : IconButton(
                                onPressed: () {
                                  // Handle send message
                                },
                                icon: Icon(Icons.mail),
                                color: AppColors.primaryMain,
                              ),
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
                        (connectionsProvider.nonCorporateConnections[index]
                                    .requestPending ??
                                false)
                            ? SizedBox()
                            : IconButton(
                                icon: Icon(Icons.exit_to_app_outlined),
                                color: AppColors.primaryMain,
                                onPressed: () {},
                              ),
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
                                      'Send Reminder',
                                      style: CustomTypography.Caption.copyWith(
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
                            child: Text("No requests"),
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
                              Text(
                                  connectionsProvider
                                          .requestUsers[index].name ??
                                      "",
                                  style: CustomTypography.Body1.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black)),
                              Text(
                                ' wants to connect!',
                                maxLines: 2,
                                style: CustomTypography.Body1.copyWith(),
                              ),
                            ],
                          ),
                          SizedBox(height: CustomSpacing.two),
                          connectionsProvider.requestUsers[index].role != null
                              ? Text(
                                  connectionsProvider.requestUsers[index].role!
                                      .map((e) =>
                                          e[0].toUpperCase() + e.substring(1))
                                      .join(', '),
                                  style: CustomTypography.Caption)
                              : SizedBox(),
                          Text(
                              connectionsProvider
                                      .requestUsers[index].companyName ??
                                  "",
                              style: CustomTypography.Caption),
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
                                        style: CustomTypography.Body2,
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
            connectionsProvider.isRequestLoading
                ? Row(
                    children: [
                      Expanded(
                          child: Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator())))
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
                                    "reject_request");
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 22, vertical: 8),
                          ),
                          child: Text(
                            'Ignore',
                            style: CustomTypography.ButtonLarge,
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
                            'Accept',
                            style: CustomTypography.ButtonLarge,
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
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Chat $index'),
        );
      },
    );
  }

  _getNetworkingUI() {
    return Column(
      children: [
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: searchNetworks,
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
          ],
        ),
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: Consumer<ConnectionsProvider>(
            builder: (context, connectionsProvider, child) {
              return connectionsProvider.isNetworkLoading
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
                  : ListView.builder(
                itemCount: connectionsProvider.networkingUsers.length,
                itemBuilder: (context, index) {
                  return _networkingCardUI(connectionsProvider, index);
                },
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _networkingCardUIOld(ConnectionsProvider connectionsProvider, int index) {
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
                        Text('Amit Didwania', style: CustomTypography.Body1),
                        SizedBox(height: CustomSpacing.two),
                        Text('Risk Manager', style: CustomTypography.Body2),
                        Text('Green', style: CustomTypography.Body2),
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
                          builder: (dialogContext) {
                            return AlertDialog(
                              content: _addNetworkDialogUI(dialogContext ,connectionsProvider, index),
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
                            style: CustomTypography.ButtonLarge,
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

  Widget _networkingCardUI(ConnectionsProvider connectionsProvider, int index) {
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                  CircleAvatar(
                    child: connectionsProvider
                        .networkingUsers[index]
                        .displayImageUrl !=
                        null &&
                        connectionsProvider
                            .networkingUsers[index]
                            .displayImageUrl !=
                            ''
                        ? ClipOval(
                      child: Image.network(
                        connectionsProvider
                            .networkingUsers[index]
                            .displayImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      connectionsProvider
                          .networkingUsers[index].name
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
                              .networkingUsers[index].name
                              ?.substring(0, 1)
                              .toUpperCase() ??
                              "") +
                              (connectionsProvider
                                  .networkingUsers[index].name
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
                            connectionsProvider
                                .networkingUsers[index]
                                .companyTypeName ??
                                "",
                            style: CustomTypography.Caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.two,
                  ),
                  // show like 4 (Star icon)
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            connectionsProvider
                                .networkingUsers[index].rating
                                ?.toString() ??
                                "",
                            style: CustomTypography.Body1,
                          ),
                          Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 20,
                          ),
                          Text(
                            '\'s',
                            style: CustomTypography.Body1,
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
                        connectionsProvider.networkingUsers[index]
                            .companyName ??
                            "",
                        style: CustomTypography.Body2.copyWith(
                            color: Theme.of(context).brightness ==
                                Brightness.dark
                                ? AppColors.white
                                : AppColors.black),
                      ),
                      // , separated roles with 1st letter capital
                      connectionsProvider
                          .networkingUsers[index].role !=
                          null
                          ? Text(
                          connectionsProvider
                              .networkingUsers[index].role!
                              .map((e) =>
                          e[0].toUpperCase() + e.substring(1))
                              .join(', '),
                          style: CustomTypography.Caption)
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Icon with text
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              content: _addNetworkDialogUI(dialogContext, connectionsProvider, index),
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Connect',
                          style: CustomTypography.Caption.copyWith(
                              color: Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black)),
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

  _addNetworkDialogUI(BuildContext dialogContext, ConnectionsProvider connectionsProvider, int index) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Avatar of user to connect, name, role, company, rating, below it textbox with title message above it as Personalized Message(Optional), hint as Say something nice!, below it two cuttons for cancel and Send Request
          // Avatar
          CircleAvatar(
            radius: 48,
            child: connectionsProvider
                .networkingUsers[index]
                .displayImageUrl !=
                null &&
                connectionsProvider
                    .networkingUsers[index]
                    .displayImageUrl !=
                    ''
                ? ClipOval(
              child: Image.network(
                connectionsProvider
                    .networkingUsers[index]
                    .displayImageUrl!,
                fit: BoxFit.cover,
              ),
            )
                : Text(
              connectionsProvider
                  .networkingUsers[index].name
                  ?.substring(0, 1)
                  .toUpperCase() ??
                  "",
            ),
          ),
          SizedBox(height: CustomSpacing.four),
          Text(connectionsProvider.networkingUsers[index].name??"" , style: CustomTypography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          connectionsProvider
                          .networkingUsers[index].role !=
                          null
                          ? Text(
                          connectionsProvider
                              .networkingUsers[index].role!
                              .map((e) =>
                          e[0].toUpperCase() + e.substring(1))
                              .join(', '),
                          style: CustomTypography.Body2)
                          : SizedBox(),
          Text(connectionsProvider.networkingUsers[index].companyName??"", style: CustomTypography.Body2),
          SizedBox(height: CustomSpacing.two),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingBar(rating: connectionsProvider.networkingUsers[index].rating??0, maxRating: 5),
            ],
          ),
          SizedBox(height: CustomSpacing.four),
          // Personalized Message make it bigger in size
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Personalized Message (Optional)',
                  style: CustomTypography.Body2),
            ],
          ),
          TextFormField(
            maxLines: 4,
            controller: _messageController,
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
                    Navigator.of(dialogContext).pop();
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
                child: connectionsProvider.isConnectLoading? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
                ) : CustomButton(
                  onPressed: () {
                    connectionsProvider.connectUser(
                        context,
                        connectionsProvider.networkingUsers[index].id ?? "",
                        _messageController.text).then((value) {
                      if (value) {
                        Navigator.of(dialogContext).pop();
                      }
                    });
                  },
                  type: ButtonType.filled,
                  child: Text(
                    'Send',
                    style: CustomTypography.ButtonLarge,
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
}
