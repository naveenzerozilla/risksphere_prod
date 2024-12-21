import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/components/roles_dropdown.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/transfer_autocomplete_model.dart';
import 'package:green/models/upload_sov_model.dart';
import 'package:green/providers/account_list_provider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/providers/upload_sov_provider.dart';
import 'package:green/screens/listings/location_list.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/listings/sub_account_list.dart';
import 'package:green/screens/listings/widgets/auto_complete_options.dart';
import 'package:green/screens/listings/widgets/mapping_screen.dart';
import 'package:material_symbols_icons/symbols.dart';
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
import '../../providers/drawer_selection_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:green/models/role_model.dart' as roleModel;

import '../../service/api_service.dart';
import '../../service/language_service.dart';
import '../../utils/api_constants.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({
    super.key,
  });

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
  TextEditingController _sovNameController = TextEditingController();


  final TextEditingController _filePathController = TextEditingController();

  String? _uploadedFileName;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  TextEditingController _accountEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;

  String _accountQuery = "";
  bool _accountAlreadyExists = false;
  Accounts? _selectedAccount;
  String _autocompleteText = "";

  ScrollController _scrollController = ScrollController();

  Timer? autoCompleteDeBouncer;

  // String? _uploadedFileName;
  String? _uploadedFileSize;

  // TextEditingController _sovNameController = TextEditingController();
  late File files;

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100, // Scroll left by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Scroll right by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
      _accountQuery = query;
      print("Query set to: $_accountQuery");
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      provider.page = 1;
      await provider.fetchAccountList(
          context, _accountQuery, provider.page, 10);
    });
  }

  void autoCompleteDebounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 1),
  }) {
    if (autoCompleteDeBouncer != null) {
      autoCompleteDeBouncer!.cancel();
    }
    autoCompleteDeBouncer = Timer(duration, callback);
  }

  Future<void> autoCompleteAccountsSearchClient(String query) async {
    if (query.isEmpty) {
      return;
    }
    print("autoCompleteAccountsSearchClient called with query: $query");
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteAccountList(context, query);

      // Force UI update after API call
      if (mounted) {
        setState(() {
          print("setState called after fetchAutoCompleteAccountList");
        });
      }
    });
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountListProvider>(context, listen: false).page = 1;
      Provider.of<AccountListProvider>(context, listen: false)
          .fetchAccountList(context, "", 1, 10);
    });
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        return PopScope(
          onPopInvokedWithResult: (canPop, result) {
            print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
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
                ? showCheckbox
                    ? Builder(builder: (contextLocal) {
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
                                _tabController?.animateTo(1);
                                _selectedScreen = Screens.networkList;
                              },
                              child: Icon(Icons.add),
                            ),
                          ],
                        );
                      })
                    : FloatingActionButton(
                        backgroundColor: AppColors.primaryMain,
                        onPressed: () {
                          // Add account dialog with autocomplete from api and create account
                          _showAddAccountDialog(context);
                        },
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                : SizedBox(),
            body: PopScope(
              canPop: /*_selectedScreen == Screens.connectionList ||
                      _selectedScreen == Screens.corporateConnectionList,*/
                  true,
              onPopInvoked: (canPop) {
                print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
                /* if (_selectedScreen == Screens.nonCorporateConnectionList) {
                      setState(() {
                        _selectedScreen = Screens.corporateConnectionList;
                      });
                    } else if (_selectedScreen == Screens.requestList) {
                      setState(() {
                        _tabController?.animateTo(0);
                        _selectedScreen = Screens.corporateConnectionList;
                      });
                    }*/
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
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              SizedBox(height: CustomSpacing.two),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                  borderRadius:
                                      BorderRadius.circular(16), // Rounded edges
                                ),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 0),
                                child: DefaultTabController(
                                  length: 3,
                                  child: Column(
                                    children: <Widget>[
                                      // Container for the TabBar with arrows
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHigh,
                                        ),
                                        height: 50,
                                        child: Row(
                                          children: <Widget>[
                                            // Left arrow button
                                            IconButton(
                                              icon: Icon(Icons.arrow_left,
                                                  color: Colors.grey),
                                              onPressed: _scrollLeft,
                                            ),
                                            // Scrollable TabBar
                                            Consumer<AccountListProvider>(
                                              builder: (context, accountListProvider, _) {
                                                return Expanded(
                                                  child: SingleChildScrollView(
                                                    controller: _scrollController,
                                                    scrollDirection: Axis.horizontal,
                                                    child: TabBar(
                                                      controller: _tabController,
                                                      tabAlignment:
                                                          TabAlignment.start,
                                                      labelStyle:
                                                          typography.Subtitle2,
                                                      isScrollable: true,
                                                      indicatorColor:
                                                          Colors.lightBlueAccent,
                                                      labelColor:
                                                          Colors.lightBlueAccent,
                                                      unselectedLabelColor:
                                                          Colors.grey,
                                                      tabs: [
                                                        Tab(
                                                          child:  Row(
                                                            children: [
                                                              Text('My Accounts', style: typography.Subtitle2),
                                                              accountListProvider.isLoading||accountListProvider.accountHits == 0?SizedBox():SizedBox(width: CustomSpacing.two,),
                                                              accountListProvider.isLoading||accountListProvider.accountHits == 0?SizedBox():SizedBox(
                                                                height: 25,
                                                                child: Chip(
                                                                  labelPadding: EdgeInsets.all(0),
                                                                  materialTapTargetSize:
                                                                  MaterialTapTargetSize.shrinkWrap,
                                                                  label: Text(
                                                                    accountListProvider.accountHits
                                                                        .toString(),
                                                                    style:
                                                                    typography.BottomNavigationActiveLabel
                                                                        .copyWith(height: -0.6),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Tab(text: 'Shared'),
                                                        //Tab(text: 'Access Requests'),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                            ),
                                            // Right arrow button
                                            IconButton(
                                              icon: Icon(Icons.arrow_right,
                                                  color: Colors.grey),
                                              onPressed: _scrollRight,
                                            ),
                                          ],
                                        ),
                                      ),


                                    ],
                                  ),
                                ),
                              ),
                              // TabBarView for the tab content
                              Expanded(
                                child
                                    : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _getAccountUI(),
                                    _getComingSoonUI(),
                                    //_getComingSoonUI(),
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
          ),
        );
      }),
    );
  }

  Widget _buildAccountCard(int index, AccountListProvider accountListProvider) {
    // Option to multiple select using checkbox, show company name, type, Admin Details (Admin Name, Email), Status switch and 2 action icons for Employees and Edit
    bool isDisabled = accountListProvider.accountList[index].disabled ?? false;
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        /*onLongPress: () {
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

        },*/
        onTap: isDisabled
            ? null
            : () {
                // On tap of card

                if (showCheckbox) {
                  setState(() {
                    accountListProvider.accountList[index].isChecked =
                        !(accountListProvider.accountList[index].isChecked ??
                            false);
                  });
                }
                // if all are unselected then hide checkbox
                if (accountListProvider.accountList
                    .every((element) => element.isChecked == false)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      showCheckbox = false;
                    });
                  });
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return /* LocationProfile(
              account: accountListProvider.accountList[index],
            );*/
                      SubAccountListScreen(
                    accountId:
                        accountListProvider.accountList[index].accountId ?? "",
                    accountName:
                        accountListProvider.accountList[index].accountName ??
                            "",
                  );
                }));
              },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*showCheckbox
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
                : */
            SizedBox(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Card(
                    color: isDisabled
                        ? Theme.of(context).colorScheme.scrim
                        : Theme.of(context).colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: CustomSpacing.three,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: CustomSpacing.two,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (accountListProvider
                                                          .accountList[index]
                                                          .accountName ??
                                                      "")
                                                  .isNotEmpty
                                              ? accountListProvider
                                                      .accountList[index]
                                                      .accountName!
                                                      .substring(0, 1)
                                                      .toUpperCase() +
                                                  accountListProvider
                                                      .accountList[index]
                                                      .accountName!
                                                      .substring(1)
                                              : "",
                                          style: typography.Body2.copyWith(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.white
                                                    : AppColors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Add edit icon and on tap show edit dialog
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      isDisabled
                                          ? SizedBox()
                                          : InkWell(
                                              onTap: () {
                                                _accountEditNameController
                                                    .text = (accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .accountName ??
                                                            "")
                                                        .isNotEmpty
                                                    ? accountListProvider
                                                            .accountList[index]
                                                            .accountName!
                                                            .substring(0, 1)
                                                            .toUpperCase() +
                                                        accountListProvider
                                                            .accountList[index]
                                                            .accountName!
                                                            .substring(1)
                                                    : "";
                                                // Show edit dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "account_list_edit_account_title"),
                                                        style: typography
                                                            .H5_Regular,
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextField(
                                                            controller:
                                                                _accountEditNameController,
                                                            decoration:
                                                                InputDecoration(
                                                              border:
                                                                  OutlineInputBorder(),
                                                              labelText:
                                                                  'Account Name',
                                                              labelStyle:
                                                                  typography
                                                                      .Body1,
                                                              hintText:
                                                                  'Enter Account Name',
                                                              hintStyle:
                                                                  typography
                                                                      .Body1,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .two,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    CustomButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Cancel
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    'Cancel',
                                                                    style: typography
                                                                        .ButtonLarge,
                                                                  ),
                                                                  type:
                                                                      ButtonType
                                                                          .text,
                                                                ),
                                                              ),
                                                              Consumer<
                                                                      AccountListProvider>(
                                                                  builder: (context,
                                                                      accountListProvider,
                                                                      _) {
                                                                return accountListProvider
                                                                        .isRenameLoading
                                                                    ? const Expanded(
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            SizedBox(
                                                                                width: 25,
                                                                                height: 25,
                                                                                child: CircularProgressIndicator()),
                                                                          ],
                                                                        ),
                                                                      )
                                                                    : Expanded(
                                                                        child:
                                                                            CustomButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (_accountEditNameController.text.isEmpty) {
                                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                LanguageService.getTranslated(context, "account_list_app_rename_account_empty_text_error"),
                                                                                style: typography.Body1,
                                                                              )));
                                                                              return;
                                                                            }
                                                                            // Update account details
                                                                            await accountListProvider.renameAccount(
                                                                                context,
                                                                                accountListProvider.accountList[index].accountId!,
                                                                                _accountEditNameController.text);
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            'Update',
                                                                            style:
                                                                                typography.ButtonLarge,
                                                                          ),
                                                                          type:
                                                                              ButtonType.elevated,
                                                                        ),
                                                                      );
                                                              }),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                            ),
                                    ],
                                  ),
                                  !accountListProvider.showSubAccountCount
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount !=
                                                            null &&
                                                        accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount ==
                                                            1
                                                    ? LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_sub_account_text")
                                                    : accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .subAccountCount ==
                                                            null
                                                        ? ""
                                                        : LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "account_list_app_sub_accounts_text"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                accountListProvider
                                                        .accountList[index]
                                                        .subAccountCount
                                                        ?.toString() ??
                                                    "",
                                                style: typography.Caption),
                                          ],
                                        ),
                                  !accountListProvider.showSOVCount
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .sovCount !=
                                                            null &&
                                                        accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .sovCount ==
                                                            1
                                                    ? LanguageService.getTranslated(
                                                        context,
                                                        "account_list_app_sov_text")
                                                    : accountListProvider
                                                                .accountList[
                                                                    index]
                                                                .sovCount ==
                                                            null
                                                        ? ""
                                                        : LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "account_list_app_sovs_text"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                accountListProvider
                                                        .accountList[index]
                                                        .sovCount
                                                        ?.toString() ??
                                                    "",
                                                style: typography.Caption),
                                          ],
                                        ),
                                  !accountListProvider.showOwner
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_owner_text"),
                                                style: typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                /*accountListProvider.accountList[index].locationCount?.toString() ??
                                              ""*/
                                                accountListProvider
                                                        .accountList[index]
                                                        .owner
                                                        ?.name ??
                                                    "",
                                                style: typography.Caption),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                            //!accountListProvider.showOverallScore
                      true
                                ? SizedBox()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(top: CustomSpacing.one),
                                    child: CustomGradientCircularProgressBar(
                                      radius: 23,
                                      value: double.parse(accountListProvider
                                              .accountList[index].overallScore
                                              ?.toString() ??
                                          "0"),
                                      strokeWidth: 6,
                                      showText: true,
                                      textColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.white
                                          : AppColors.black,
                                      text: accountListProvider
                                              .accountList[index].overallScore
                                              ?.toString() ??
                                          "0",
                                    ),
                                  ),
                            SizedBox(
                              width: CustomSpacing.four,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                      ],
                    ),
                  ),
                  isDisabled
                      ? SizedBox()
                      : Container(
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
                              TextButton.icon(
                                onPressed: () {
                                  // Transfer account
                                  _showTransferDialog(context,
                                      accountListProvider.accountList[index]);
                                },
                                icon: const Icon(Symbols.share_windows),
                                label: Text('Transfer',
                                    style: typography.Caption.copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.white
                                            : AppColors.black)),
                              ),
                              //SizedBox(),

                              const Spacer(),
                              /*IconButton(
                                icon: const Icon(Icons.upload_rounded),
                                color: AppColors.primaryMain,
                                onPressed: () async {
                                  setState(() {
                                    _uploadedFileName = null;
                                    _sovNameController.clear();
                                  });
                                  _showUploadDialog(accountListProvider
                                      .accountList[index].accountId
                                      .toString());
                                },
                                tooltip: LanguageService.getTranslated(context,
                                    "account_list_app_export_tooltip_text"),
                              ),*/
                              IconButton(
                                icon: const Icon(Icons.file_copy_rounded),
                                color: AppColors.primaryMain,
                                onPressed: () {
                                  // Show duplicate dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          LanguageService.getTranslated(context,
                                              "account_list_app_duplicate_title"),
                                          style: typography.H5_Regular,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "account_list_app_duplicate_text"),
                                              style: typography.Body1,
                                            ),
                                            SizedBox(
                                              height: CustomSpacing.two,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomButton(
                                                    onPressed: () {
                                                      // Cancel
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      LanguageService.getTranslated(
                                                          context,
                                                          "account_list_app_duplicate_cancel"),
                                                      style: typography
                                                          .ButtonLarge,
                                                    ),
                                                    type: ButtonType.text,
                                                  ),
                                                ),
                                                accountListProvider
                                                        .isDuplicateLoading
                                                    ? const Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SizedBox(
                                                                width: 25,
                                                                height: 25,
                                                                child:
                                                                    CircularProgressIndicator()),
                                                          ],
                                                        ),
                                                      )
                                                    : Expanded(
                                                        child: CustomButton(
                                                          onPressed: () async {
                                                            // Duplicate
                                                            await accountListProvider
                                                                .duplicateAccount(
                                                                    context,
                                                                    accountListProvider
                                                                        .accountList[
                                                                            index]
                                                                        .accountId!);
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text(
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "account_list_app_duplicate_duplicate"),
                                                            style: typography
                                                                .ButtonLarge,
                                                          ),
                                                          type: ButtonType
                                                              .elevated,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                tooltip: 'Duplicate',
                              ),
                              /*IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  color: AppColors.primaryMain,
                                ),
                                onPressed: () {
                                  _showSettingsModal(context);
                                },
                                tooltip: 'Settings',
                              ),*/
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransferDialog(
      BuildContext context, Accounts account) async {
    var typography = CustomTypography(context);
    TextEditingController _userSearchController = TextEditingController();
    TransferAutocompleteModel? _selectedUser;
    List<TransferAutocompleteModel> _autocompleteUsersList = [];
    bool _isTransferLoading = false;
    bool _isSearching = false;
    Timer? _debounce;

    // Function to handle search input changes
    void _onSearchChanged(String query, StateSetter setState) {
      // Cancel any existing debounce timer
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      // Create a new debounce timer
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (query.isNotEmpty) {
          // Set searching state
          setState(() {
            _isSearching = true; // Start searching
          });

          // Fetch autocomplete users
          _autocompleteUsersList = await fetchAutocompleteUsers(query);

          // Update state after search
          setState(() {
            _isSearching = false; // End searching
          });
        } else {
          // Clear search results if query is empty
          setState(() {
            _autocompleteUsersList.clear();
            _isSearching = false; // No need to search if query is empty
          });
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage internal dialog state
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              child: Container(
                width: 304,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Transfer Account',
                        style: typography.H5_Regular,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _userSearchController,
                        onChanged: (query) {
                          setState(() {
                            _selectedUser =
                                null; // Remove selected user when editing
                          });
                          // Call search change handler with local setState
                          _onSearchChanged(query, setState);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for a user to transfer account',
                          border: OutlineInputBorder(),
                          suffixIcon: _isSearching
                              ? Container(
                                  margin: EdgeInsets.fromLTRB(0, 8, 16, 8),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator())
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Flexible(
                      child: _selectedUser == null
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: _autocompleteUsersList.length,
                              itemBuilder: (context, index) {
                                final user = _autocompleteUsersList[index];
                                return ListTile(
                                  leading: user.imageUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(user.imageUrl),
                                        )
                                      : CircleAvatar(
                                          child: Text(user.name[0]
                                              .toUpperCase()),
                                        ),
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _userSearchController.text =
                                          user.name;
                                    });
                                  },
                                );
                              },
                            )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                  'Selected User: ${_selectedUser!.name}'),
                            ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: _selectedUser != null &&
                                  !_isTransferLoading
                              ? () async {
                                  setState(() {
                                    _isTransferLoading =
                                        true; // Show loading only on Transfer
                                  });
                                  var provider =
                                      Provider.of<AccountListProvider>(context,
                                          listen: false);
                                  await provider.transferAccount(context,
                                      account.accountId!, _selectedUser!.id);
                                  setState(() {
                                    _isTransferLoading = false; // Stop loading
                                  });
                                  Navigator.pop(dialogContext);
                                }
                              : null,
                          // Disable button if no user is selected or already transferring
                          child: _isTransferLoading
                              ? CircularProgressIndicator(strokeWidth: 2.0)
                              : Text('Transfer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Dispose of the debounce timer
      if (_debounce?.isActive ?? false) _debounce?.cancel();
    });
  }

  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(String query) async {
    try {
      ApiService apiService = ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);

      // The response has 'result' array instead of 'users'
      List<TransferAutocompleteModel> users = (response['result'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print('Error fetching users: ${e.toString()}');
      return [];
    }
  }

  void _showSettingsModal(BuildContext context) {
    var typography = CustomTypography(context);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Consumer<AccountListProvider>(
                builder: (context, accountListProvider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: accountListProvider.isOwnerLoading
                        ? Padding(
                            padding: EdgeInsets.only(
                                left: CustomSpacing.three,
                                right: CustomSpacing.three),
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator()),
                          )
                        : Checkbox(
                            value: accountListProvider.showOwner,
                            onChanged: (value) async {
                              bool result = await accountListProvider
                                  .changeColumnVisibility(context,
                                      showOwner: value ?? false,
                                      showSOVCount:
                                          accountListProvider.showSOVCount,
                                      showSubAccountCount: accountListProvider
                                          .showSubAccountCount,
                                      showOverallScore:
                                          accountListProvider.showOverallScore,
                                      type: 'owner');

                              if (result) {
                                setModalState(() {
                                  accountListProvider.showOwner =
                                      value ?? false;
                                });
                                setState(() {
                                  accountListProvider.showOwner =
                                      value ?? false;
                                });
                                // Update account list
                                accountListProvider.fetchAccountList(
                                    context,
                                    _accountQuery,
                                    accountListProvider.page,
                                    10);
                              }
                            },
                          ),
                    title: Text(
                        LanguageService.getTranslated(
                            context, "account_list_app_column_owner_text"),
                        style: typography.Body1),
                  ),
                  ListTile(
                    leading: accountListProvider.showSOVCountLoading
                        ? Padding(
                            padding: EdgeInsets.only(
                                left: CustomSpacing.three,
                                right: CustomSpacing.three),
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator()),
                          )
                        : Checkbox(
                            value: accountListProvider.showSOVCount,
                            onChanged: (value) async {
                              bool result = await accountListProvider
                                  .changeColumnVisibility(context,
                                      showOwner: accountListProvider.showOwner,
                                      showSOVCount: value ?? false,
                                      showSubAccountCount: accountListProvider
                                          .showSubAccountCount,
                                      showOverallScore:
                                          accountListProvider.showOverallScore,
                                      type: 'sov_count');

                              if (result) {
                                setModalState(() {
                                  accountListProvider.showSOVCount =
                                      value ?? false;
                                });
                                setState(() {
                                  accountListProvider.showSOVCount =
                                      value ?? false;
                                });
                                // Update account list
                                accountListProvider.fetchAccountList(
                                    context,
                                    _accountQuery,
                                    accountListProvider.page,
                                    10);
                              }
                            },
                          ),
                    title: Text(
                        LanguageService.getTranslated(
                            context, "account_list_app_column_sov_count_text"),
                        style: typography.Body1),
                  ),
                  ListTile(
                    leading: accountListProvider.showSubAccountCountLoading
                        ? Padding(
                            padding: EdgeInsets.only(
                                left: CustomSpacing.three,
                                right: CustomSpacing.three),
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator()),
                          )
                        : Checkbox(
                            value: accountListProvider.showSubAccountCount,
                            onChanged: (value) async {
                              bool result = await accountListProvider
                                  .changeColumnVisibility(context,
                                      showOwner: accountListProvider.showOwner,
                                      showSOVCount:
                                          accountListProvider.showSOVCount,
                                      showSubAccountCount: value ?? false,
                                      showOverallScore:
                                          accountListProvider.showOverallScore,
                                      type: 'sub_account_count');
                              if (result) {
                                setModalState(() {
                                  accountListProvider.showSubAccountCount =
                                      value ?? false;
                                });
                                setState(() {
                                  accountListProvider.showSubAccountCount =
                                      value ?? false;
                                });
                                // Update account list
                                accountListProvider.fetchAccountList(
                                    context,
                                    _accountQuery,
                                    accountListProvider.page,
                                    10);
                              }
                            },
                          ),
                    title: Text(
                        LanguageService.getTranslated(context,
                            "account_list_app_column_sub_account_count_text"),
                        style: typography.Body1),
                  ),
                  ListTile(
                    leading: accountListProvider.showOverallScoreLoading
                        ? Padding(
                            padding: EdgeInsets.only(
                                left: CustomSpacing.three,
                                right: CustomSpacing.three),
                            child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator()),
                          )
                        : Checkbox(
                            value: accountListProvider.showOverallScore,
                            onChanged: (value) async {
                              bool result = await accountListProvider
                                  .changeColumnVisibility(context,
                                      showOwner: accountListProvider.showOwner,
                                      showSOVCount:
                                          accountListProvider.showSOVCount,
                                      showSubAccountCount: accountListProvider
                                          .showSubAccountCount,
                                      showOverallScore: value ?? false,
                                      type: 'overall_score');
                              if (result) {
                                setModalState(() {
                                  accountListProvider.showOverallScore =
                                      value ?? false;
                                });
                                setState(() {
                                  accountListProvider.showOverallScore =
                                      value ?? false;
                                });
                                // Update account list
                                accountListProvider.fetchAccountList(
                                    context,
                                    _accountQuery,
                                    accountListProvider.page,
                                    10);
                              }
                            },
                          ),
                    title: Text(
                        LanguageService.getTranslated(context,
                            "account_list_app_column_overall_score_text"),
                        style: typography.Body1),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  void _showUploadDialog(String accountId) {
    var typography = CustomTypography(context);
    bool addToSoV = false; // New variable for checkbox state
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return PopScope(
              onPopInvokedWithResult: (canPop, result) {
                print('Can Pop: $canPop, Selected Screen: $_selectedScreen');
                Provider.of<DrawerSelectionProvider>(context, listen: false)
                    .setSelectedItem("dashboard");
              },
              child: AlertDialog(
                backgroundColor: Colors.black87,
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xls', 'xlsx'],
                          );
                          if (result != null) {
                            File file = File(result.files.single.path!);
                            setState(() {
                              files = file;
                              _uploadedFileName = file.path.split('/').last;
                              _sovNameController.text = _uploadedFileName!;
                            });
                          }
                        },
                        child: _uploadedFileName == null
                            ? Container(
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
                                Icon(Icons.cloud_upload_outlined, color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  LanguageService.getTranslated(context, "account_list_app_account_upload_drag_and_drop"),
                                  style: typography.Body1,
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.white54),
                                    SizedBox(width: 3),
                                    Text('Max file size is 200 MB', style: typography.Body1),
                                  ],
                                ),
                              ],
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
                                  LanguageService.getTranslated(context, "account_list_app_cancel_text"),
                                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                                ),
                              ),
                              SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Checkbox(
                            value: addToSoV,
                            onChanged: (bool? value) {
                              setState(() {
                                addToSoV = value!;
                              });
                            },
                          ),
                          Text(
                            'Add to SoV',
                            style: typography.Body1,
                          ),
                        ],
                      ),
                      if (!addToSoV) ...[
                        TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Enter Tags (separated by comma)",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                      if (addToSoV) ...[
                        // Fields displayed only if checkbox is checked
                        TextField(
                          controller: _sovNameController,
                          readOnly: _uploadedFileName != null,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Name of the SoV",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Enter Tags (separated by comma)",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Enter Account Name",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Enter Sub-account Name",
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _uploadedFileName = null;
                                _sovNameController.clear();
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text("Close", style: typography.Body1),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Upload action
                            },
                            child: Text("Upload", style: typography.ButtonLarge),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    var typography = CustomTypography(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LanguageService.getTranslated(
                          context, "account_list_app_add_account_title"),
                      style: typography.H5_Regular,
                    ),
                    SizedBox(height: 16.0),
                    Consumer<AccountListProvider>(
                      builder: (context, accountListProvider, child) {
                        return Column(
                          children: [
                            TextField(
                              controller: _textEditingController,
                              focusNode: FocusNode(),
                              onChanged: (value) async {
                                setState(() {
                                  _accountAlreadyExists = false;
                                  _selectedAccount = null;
                                  // Clear the autocomplete list when user starts typing
                                  accountListProvider.clearAutoCompleteList();
                                });
                                _autocompleteText = value;
                                await autoCompleteAccountsSearchClient(
                                    _autocompleteText);
                              },
                              decoration: InputDecoration(
                                suffixIcon: _textEditingController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _textEditingController.clear();
                                            _accountAlreadyExists = false;
                                            _selectedAccount = null;
                                            // Clear the autocomplete list when user clears the text
                                            accountListProvider.clearAutoCompleteList();
                                          });
                                        },
                                      )
                                    : null,
                                labelText: LanguageService.getTranslated(
                                    context,
                                    "account_list_app_add_account_title"),
                                hintText: LanguageService.getTranslated(context,
                                    "account_list_app_add_account_title"),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            if (_textEditingController.text.isNotEmpty &&
                                !_accountAlreadyExists)
                              AutocompleteOptions(
                                options:
                                    accountListProvider.autoCompleteAccountList,
                                onSelected: (Accounts selection) {
                                  setState(() {
                                    _accountAlreadyExists = true;
                                    _selectedAccount = selection;
                                    _textEditingController.text =
                                        selection.accountName!;
                                    // Clear the autocomplete list when an option is selected
                                    accountListProvider.clearAutoCompleteList();
                                  });
                                },
                                isLoading:
                                    accountListProvider.isAutoCompleteLoading,
                              ),
                            if (_accountAlreadyExists)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    labelText: LanguageService.getTranslated(
                                        context,
                                        "account_list_app_comment_text"),
                                    hintText: LanguageService.getTranslated(
                                        context,
                                        "account_list_app_comment_placeholder"),
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: CustomSpacing.six),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<AccountListProvider>(
                                  builder: (context, accountListProvider, _) {
                                return accountListProvider.isAddAccountLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                              width: 25,
                                              height: 25,
                                              child:
                                                  CircularProgressIndicator()),
                                        ],
                                      )
                                    : CustomButton(
                                        onPressed: () async {
                                          if (_autocompleteText.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                              LanguageService.getTranslated(
                                                  context,
                                                  "account_list_app_add_account_empty_text_error"),
                                              style: typography.Body1,
                                            )));
                                            return;
                                          }

                                          if (!_accountAlreadyExists) {
                                            // Add account
                                            await accountListProvider
                                                .addAccount(
                                                    context, _autocompleteText);
                                          } else {
                                            // Request access
                                            if (_messageController
                                                .text.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_comment_empty_text_error"),
                                                style: typography.Body1,
                                              )));
                                              return;
                                            }
                                            await accountListProvider
                                                .requestAccess(
                                                    context,
                                                    _selectedAccount
                                                            ?.accountId ??
                                                        "",
                                                    _messageController.text);
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          _accountAlreadyExists
                                              ? LanguageService.getTranslated(
                                                  context,
                                                  "account_list_app_request_access_text")
                                              : LanguageService.getTranslated(
                                                  context,
                                                  "account_list_app_submit_text"),
                                          style: typography.ButtonLarge,
                                        ),
                                        type: ButtonType.elevated,
                                      );
                              }),
                            ),
                          ],
                        ),
                        CustomButton(
                          onPressed: () {
                            // Cancel
                            _uploadedFileName = null;
                            _sovNameController.clear();
                            Navigator.pop(context);
                          },
                          child: Text(
                            LanguageService.getTranslated(
                                context, "account_list_app_cancel_text"),
                            style: typography.ButtonLarge,
                          ),
                          type: ButtonType.text,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear the autocomplete list when the dialog is dismissed
      Provider.of<AccountListProvider>(context, listen: false)
          .clearAutoCompleteList();
      _textEditingController.clear();
      _messageController.clear();
      _accountAlreadyExists = false;
    });
  }

  _getComingSoonUI() {
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

  Widget _getAccountUI() {
    var typography = CustomTypography(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(height: CustomSpacing.six),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${LanguageService.getTranslated(context, "account_list_app_title")} ',
              style: typography.Body1,
            ),
            /*ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Container(
                height: 40,
                // Adjust this value to match your desired button height
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Upload',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: AppColors.primaryDark,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),*/
          ],
        ),
        SizedBox(height: CustomSpacing.four),
        // Search
        SizedBox(
          height: 50,
          child: TextField(
            controller: _textEditingController,
            onChanged: (query) {
              print("Query: ${_textEditingController.text}");
              accountsSearchClient(query);
              setState(() {
                _accountQuery = query;
              });
            },
            decoration: InputDecoration(
              suffixIcon: _accountQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _textEditingController.clear();
                        accountsSearchClient("");
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: LanguageService.getTranslated(
                  context, "account_list_search_hint"),
              hintStyle: typography.Body2,
            ),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
        // List of accounts
        Expanded(
          child: Consumer<AccountListProvider>(
              builder: (context, accountListProvider, _) {
            return accountListProvider.isLoading
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                      ),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  )
                : accountListProvider.accountList.isEmpty
                    ? Center(
                        child: Text(
                          LanguageService.getTranslated(
                              context, "account_list_app_no_accounts_text"),
                          style: typography.Body1,
                        ),
                      )
                    : RefreshIndicator(

                      onRefresh: () async {
                        accountListProvider.fetchAccountList(
                            context, _accountQuery, 1, 10);
                      },
                      child: ListView.builder(
                          itemCount: accountListProvider.accountList.length,
                          itemBuilder: (context, index) {
                            print("Query1: $_accountQuery");
                            if (index ==
                                accountListProvider.accountList.length - 1) {
                              // Check if it's the last item
                              if (accountListProvider.isNextPageLoading) {
                                // Display loading indicator
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (accountListProvider.page >=
                                      accountListProvider.totalPages &&
                                  accountListProvider.accountList.isNotEmpty) {
                                // Display end of list message
                                print(
                                    "account list: ${accountListProvider.accountList}");
                                return Column(
                                  children: [
                                    _buildAccountCard(index, accountListProvider),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          LanguageService.getTranslated(context,
                                              "account_list_app_end_of_list_text"),
                                          style: typography.Body1,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Trigger fetching the next page
                                accountListProvider.page =
                                    accountListProvider.page + 1;
                                print(
                                    "Fetching page ${accountListProvider.page}");
                                print(
                                    "Query: $_accountQuery, Page: ${accountListProvider.page}");
                                accountListProvider.fetchAccountList(
                                  context,
                                  _accountQuery,
                                  // Pass the search query if any
                                  accountListProvider.page,
                                  10, // Page size
                                );
                                return SizedBox();
                              }
                            } else {
                              return _buildAccountCard(
                                  index, accountListProvider);
                            }
                          }),
                    );
          }),
        ),
      ],
    );
  }
}
