import 'package:country_list_picker/country_list_picker.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/roles_bottom_sheet.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/providers/company_provider.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/repo/constants.dart';
import '../../models/initial_data_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;

  // Create Company Form
  List<Categories> _selectedRoles = [];
  TextEditingController _textEditingController = TextEditingController();
  SignUpOptions? _selectedOption;
  String _selectedCountryCode = '+1';
  TextEditingController mobileController = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _getData();
    super.initState();
  }

  Future<void> _getData() async {
    await Provider.of<CompanyProvider>(context, listen: false)
        .getAllCompanies("searchText", "filter");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add User
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Management', style: CustomTypography.H5_Regular),
                  // Add 3 tabs
                  SizedBox(
                    height: CustomSpacing.two,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 2,
                      child: TabBar(
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
                                    'Categories',
                                    style: CustomTypography
                                        .BottomNavigationActiveLabel,
                                  ),
                                  value: 'Categories',
                                ),
                                DropdownMenuItem(
                                  child: Text(
                                    'Leads',
                                    style: CustomTypography
                                        .BottomNavigationActiveLabel,
                                  ),
                                  value: 'Leads',
                                ),
                              ],
                              onChanged: (value) {
                                // Handle dropdown item selection
                                if (value == 'Corporate') {
                                  // Perform action for Corporate Management
                                } else if (value == 'AnotherOption') {
                                  // Handle another option
                                }
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people),
                              SizedBox(
                                width: CustomSpacing.two,
                              ),
                              Tab(text: 'Non Corporate Management'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_circle),
                              SizedBox(
                                width: CustomSpacing.two,
                              ),
                              Tab(text: 'Employee Management'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add 3 tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Corporate Management
                        //_corporateManagement(),
                        _createCompany(),
                        // Non Corporate Management
                        ListView(
                          children: [
                            ListTile(
                              title: Text('Add Non Corporate'),
                              onTap: () {
                                // Add Non Corporate
                              },
                            ),
                            ListTile(
                              title: Text('View Non Corporate'),
                              onTap: () {
                                // View Non Corporate
                              },
                            ),
                          ],
                        ),
                        // Employee Management
                        ListView(
                          children: [
                            ListTile(
                              title: Text('Add Employee'),
                              onTap: () {
                                // Add Employee
                              },
                            ),
                            ListTile(
                              title: Text('View Employee'),
                              onTap: () {
                                // View Employee
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _corporateManagement() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: CustomSpacing.four,
        ),
        Text('Companies', style: CustomTypography.Body1),
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
  }

  _companyListItem() {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (value) {
            // Handle checkbox value change
          },
        ),
        title: Text('Company Name', style: CustomTypography.Body1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Type', style: CustomTypography.Body1),
            Text('Admin Name', style: CustomTypography.Body1),
            Text('Email', style: CustomTypography.Body1),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: true,
              onChanged: (value) {
                // Handle switch value change
              },
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('View Employees'),
                    onTap: () {
                      // Handle view employees
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Company'),
                    onTap: () {
                      // Handle edit company
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _createCompany() {
    // Add Company
    return SingleChildScrollView(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: CustomSpacing.four,
            ),
            Text('Create new corporate account', style: CustomTypography.Body1),
            SizedBox(
              height: CustomSpacing.two,
            ),
            Text(
                'Please provide the necessary information to establish a new corporate account.',
                style: CustomTypography.Body2),
            SizedBox(
              height: CustomSpacing.three,
            ),
            Divider(),
            SizedBox(
              height: CustomSpacing.three,
            ),
            // Add Company Form
            // Profile Pic
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/loginImage.png'),
                    radius: 40,
                  ),
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Image",
                        style:
                            CustomTypography.Body1.copyWith(color: Colors.white),
                      ),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      Text(
                        "Min 400x400px\nPNG or JPEG",
                        style: CustomTypography.BottomNavigationActiveLabel,
                      ),
                      SizedBox(
                        height: CustomSpacing.two,
                      ),
                      // Add button
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding:
                                EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          ),
                          child: Text(
                            "Upload Image",
                            style: CustomTypography.ButtonLarge,
                          ))
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: CustomSpacing.two,
            ),
            Form(
                child: Column(children: [
              // Company Type
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Company Type',
                        labelStyle: CustomTypography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          child: Text(
                            'Corporate',
                            style: CustomTypography.Body1,
                          ),
                          value: 'Corporate',
                        ),
                        DropdownMenuItem(
                          child: Text(
                            'Non Corporate',
                            style: CustomTypography.Body1,
                          ),
                          value: 'Non Corporate',
                        ),
                      ],
                      onChanged: (value) {
                        // Handle dropdown value change
                      },
                    ),
                  ),
                  SizedBox(
                    width: CustomSpacing.four,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Company Domain',
                        labelStyle: CustomTypography.Body1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          child: Text(
                            'Enable',
                            style: CustomTypography.Body1,
                          ),
                          value: 'Enable',
                        ),
                        DropdownMenuItem(
                          child: Text(
                            'Disable',
                            style: CustomTypography.Body1,
                          ),
                          value: 'Disable',
                        ),
                      ],
                      onChanged: (value) {
                        // Handle dropdown value change
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              // Domain List
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Domain List (Separated by commas)',
                  labelStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              // Company Legal Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Company Legal Name',
                  labelStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              // Company Display Name
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Company Display Name',
                  labelStyle: CustomTypography.Body1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              // User & Role(s) divider
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'User & Role(s)',
                    style: CustomTypography.Subtitle1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(width: CustomSpacing.three),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.white.withOpacity(0.11999999731779099),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: CustomSpacing.two,
              ),
              // Role Dropdown
                  Stack(
                    children: [
                      TextField(
                        readOnly: true,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return RolesBottomSheet(
                                showCorporateSwitch: true,
                                options: roles,
                                selectedRoles: _selectedRoles,
                                addChip: _addChip,
                                removeChip: _removeChip,
                                removeAllChips: _removeAllChips,
                                selectedOption:
                                SignUpOptions.corporate,
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
                                    showCorporateSwitch: true,
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
SizedBox(width: CustomSpacing.two,),
              // Phone
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
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
                            FilteringTextInputFormatter.digitsOnly // Only allows digits
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
                  SizedBox(height: CustomSpacing.two),
              // Cancel and Submit Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle cancel button
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
                        child: ElevatedButton(
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
                            'Submit',
                            style: CustomTypography.ButtonLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
            ]))
          ]),
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
