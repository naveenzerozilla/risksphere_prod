import 'dart:async';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/components/roles_dropdown.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/providers/account_list_provider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/screens/listings/location_list.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/custom_gradient_circular_progress_bar.dart';
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

class AccountListScreen extends StatefulWidget {

  const AccountListScreen(
      {super.key,});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

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

  void accountsSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
  });
        }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    // Fetch data from API
    Provider.of<AccountListProvider>(context, listen: false).addDummyData();
  }

  void searchNetworks(String query) async => debounce(() async {
    if (!mounted) return;
    // Fetch data from API using query
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
              showDropdown: true,
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
            floatingActionButton: _selectedScreen == Screens.accountList
                ? showCheckbox?Builder(builder: (contextLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      // On export button click
                    },
                    child: Icon(CupertinoIcons.tray_arrow_down),
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
            }):
            FloatingActionButton(
              onPressed: () {
                // Add more SOVs
              },
              child: Icon(Icons.add),
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
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                         /*     Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RolesDropdown(),
                                    ],
                                  ),
                                ],
                              ),*/
                              Text(
                                '${LanguageService.getTranslated(context, "account_list_app_title")} ',
                                style: CustomTypography.H5_Regular,
                              ),
                              Text(
                                LanguageService.getTranslated(context,
                                    "account_list_app_subtitle"),
                                style: CustomTypography.Body2,
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Search
                              SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _textEditingController,
                                  onChanged: (query) {
                                    accountsSearchClient(query);
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: LanguageService.getTranslated(
                                        context, "account_list_search_hint"),
                                    hintStyle: CustomTypography.Body2,
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // List of accounts
                              Expanded(
                                child: Consumer<AccountListProvider>(
                                  builder: (context, accountListProvider, _) {
                                    return ListView.builder(
                                      itemCount: accountListProvider.accountList.length,
                                      itemBuilder: (context, index) {
                                        return _buildAccountCard(index, accountListProvider);
                                      },
                                    );
                                  }
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
          );
        });
  }

  Widget _buildAccountCard(int index, AccountListProvider accountListProvider) {
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
          setState(() {
            accountListProvider.accountList[index].isChecked =
            !(accountListProvider.accountList[index].isChecked??false);
          });

        },
        onTap: () {
          // On tap of card

          if (showCheckbox) {
            setState(() {
              accountListProvider.accountList[index].isChecked =
              !(accountListProvider.accountList[index].isChecked??false);
            });
          }
          // if all are unselcted then hide checkbox
          if (accountListProvider.accountList.every((element) => element.isChecked == false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                showCheckbox = false;
              });
            });
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return/* LocationProfile(
              account: accountListProvider.accountList[index],
            );*/LocationList(userId: accountListProvider.accountList[index].id??"", companyName: accountListProvider.accountList[index].name??"",);
          }));
        },
        child: Row(
          children: [
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: CustomSpacing.three,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: CustomSpacing.four,
                        ),
                        showCheckbox
                            ? Checkbox(
                          value: accountListProvider.accountList[index].isChecked??false,
                          onChanged: (value) {
                            // Handle checkbox value change
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              setState(() {
                                accountListProvider.accountList[index].isChecked = value;
                              });
                            });
                          },
                        )
                            : SizedBox(),

                        SizedBox(
                          width: CustomSpacing.two,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (accountListProvider.accountList[index].displayName ?? "").isNotEmpty
                                    ? accountListProvider.accountList[index].displayName!.substring(0, 1).toUpperCase() +
                                    accountListProvider.accountList[index].displayName!.substring(1)
                                    : (accountListProvider.accountList[index].name ?? "").isNotEmpty
                                    ? accountListProvider.accountList[index].name!.substring(0, 1).toUpperCase() +
                                    accountListProvider.accountList[index].name!.substring(1)
                                    : "",
                                style: CustomTypography.Body2.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Row(
                                children: [
                                  Text(
                                      accountListProvider.accountList[index].locationCount?.toString() ??
                                          "",
                                      style: CustomTypography.Caption),
                                  SizedBox(
                                    width: CustomSpacing.two,
                                  ),
                                  Text(
                                      accountListProvider.accountList[index].locationCount!= null && accountListProvider.accountList[index].locationCount == 1?"Location":accountListProvider.accountList[index].locationCount== null?"":"Locations",
                                      style: CustomTypography.Caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                    SizedBox(
                      height: CustomSpacing.three,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: CustomSpacing.four,
            ),
            CustomGradientCircularProgressBar(
              radius: 23,
              value: double.parse(accountListProvider.accountList[index].overAllScore ?? "0"),
              strokeWidth: 6,
              showText: true,
              textColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white
                  : AppColors.black,
              text: accountListProvider.accountList[index].overAllScore ?? "0",
            ),
            SizedBox(
              width: CustomSpacing.two,
            ),
          ],
        ),
      ),
    );
  }

}
