import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
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
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {

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
      print('Tab Index: ${_tabController?.index} Selected Screen: $_selectedScreen');
    });
  }

  @override
  Widget build(BuildContext context1) {
    return Consumer<ThemeProvider>(builder: (buildContext, themeProvider, child) {
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
        floatingActionButton: _selectedScreen == Screens.connectionList
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
          canPop: _selectedScreen == Screens.connectionList,
          onPopInvoked: (canPop) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
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
                          Text('Connections of Amit Didwania',
                              style: CustomTypography.H5_Regular),
                          SizedBox(height: CustomSpacing.two),
                          Text('Manage all connections from this panel',
                              style: CustomTypography.Body2),
                          // Add 3 tabs
                          SizedBox(
                            height: CustomSpacing.two,
                          ),
                          TabBar(isScrollable: true,
                            controller: _tabController,
                            labelStyle: CustomTypography
                                .BottomNavigationActiveLabel,
                            tabs: [
                              Tab(
                                child: InkWell(
                                  onTap: () {
                                    _tabController?.animateTo(0);
                                    _selectedScreen =
                                        Screens.connectionList;
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tab(text: 'Connections', ),
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
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
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(1);
                                  _selectedScreen =
                                      Screens.requestList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tab(text: 'Requests', ),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
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
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(2);
                                  _selectedScreen =
                                      Screens.chatList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tab(text: 'Chats', ),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
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
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(3);
                                  _selectedScreen =
                                      Screens.networkList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tab(text: 'Networking', ),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
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
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _tabController?.animateTo(4);
                                  _selectedScreen =
                                      Screens.blockedList;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tab(text: 'Blocked', ),
                                    SizedBox(
                                      width: CustomSpacing.two,
                                    ),
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
                                ),
                              ),
                            ],
                          ),

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
                      )
                  ),
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
                                  border:
                                  Border.all(color: Colors.white.withOpacity(0.5)),
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
                                hintText: _selectedRoles.isEmpty ? 'Select Roles' : "",
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
                                          onOptionChanged: (SignUpOptions signUpOptions) {
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
                                        padding: const EdgeInsets.only(right: 8.0),
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
                          items: ['Active', 'Inactive']
                              .map((String value) {
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
                                  padding:
                                  EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
                                type: ButtonType.filled, child: Text('Add Filter', style: CustomTypography.ButtonLarge,),
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
      *//*shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),*//*
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
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return _connectionsCardUI();
            },
          ),
        ),
      ],
    );
  }

  Widget _connectionsCardUI() {
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
                            backgroundImage: AssetImage('assets/images/loginImage.png'),
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


  _getRequestsUI() {
    return Column(
      children: [
        SizedBox(height: CustomSpacing.two),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return _requestsCardUI();
            },
          ),
        ),
      ],
    );
  }

  Widget _requestsCardUI() {
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
                            radius: 24,
                            backgroundImage: AssetImage('assets/images/loginImage.png'),
                          ),
                        ),
                        //filled check icon in green circle, top right
                        Positioned(
                          top: 2,
                          right: 8,
                          child: SvgPicture.asset(
                            'assets/images/check_circle.svg',
                            semanticsLabel: 'Check Circle',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Amit Didwania', style: CustomTypography.Body1.copyWith(color: Theme.of(context).brightness==Brightness.dark?AppColors.white:AppColors.black)),
                              Text(
                                ' wants to connect!',
                                maxLines: 2,
                                style: CustomTypography.Body1.copyWith(
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: CustomSpacing.two),
                          Text('Risk Manager', style: CustomTypography.Body2),
                          Text('BHSI - Insurers', style: CustomTypography.Body2),
                          SizedBox(height: CustomSpacing.two),
                          Row(
                            children: [
                              Icon(Icons.message,),
                              SizedBox(width: CustomSpacing.two),
                              Expanded(child: Container(margin: EdgeInsets.only(right: 8), child: Text('Hey there! I am looking for a Cat Modeler service, would love to connect?', style: CustomTypography.Body2, softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 2,))),
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
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
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
                        padding:
                        EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
                        Navigator.pop(context);
                      },
                      type: ButtonType.filled, child: Text('Accept', style: CustomTypography.ButtonLarge,),
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
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return _networkingCardUI();
            },
          ),
        ),
      ],
    );
  }

  Widget _networkingCardUI() {
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
                        backgroundImage: AssetImage('assets/images/loginImage.png'),
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
                    child:  //change to custom button
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
                      type: ButtonType.filled, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: CustomSpacing.two),
                          Text('Connect', style: CustomTypography.ButtonLarge,),
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
          Text('Amit Didwania', style: CustomTypography.H5_Regular),
          SizedBox(height: CustomSpacing.two),
          Text('Risk Manager', style: CustomTypography.Body2),
          Text('Green', style: CustomTypography.Body2),
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
      Text('Personalized Message (Optional)', style: CustomTypography.Body2),
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
                    padding:
                    EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
                  type: ButtonType.filled, child: Text('Send', style: CustomTypography.ButtonLarge,),
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
