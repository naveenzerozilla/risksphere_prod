import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:country_list_picker/country_list_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/components/roles_dropdown.dart';
import 'package:green/models/account_list_model.dart';
import 'package:green/models/sub_account_list_model.dart';
import 'package:green/providers/account_list_provider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/providers/sub_account_list_provider.dart';
import 'package:green/screens/listings/location_list.dart';
import 'package:green/screens/listings/location_profile.dart';
import 'package:green/screens/listings/sov_list.dart';
import 'package:green/screens/listings/widgets/auto_complete_options_sub_accounts.dart';
import 'package:green/screens/listings/widgets/configurations_tab.dart';
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
import '../../models/transfer_autocomplete_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:green/models/role_model.dart' as roleModel;

import '../../providers/upload_sov_provider.dart';
import '../../service/api_service.dart';
import '../../service/language_service.dart';
import '../../utils/api_constants.dart';
import 'my_location_list.dart';
import 'widgets/auto_complete_options.dart';

class SubAccountListScreen extends StatefulWidget {

  final String accountId;
  final String? accountName;

  const SubAccountListScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<SubAccountListScreen> createState() => _SubAccountListScreenState();
}

class _SubAccountListScreenState extends State<SubAccountListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.subAccountList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  String? _uploadedFileName;
  TextEditingController _sovNameController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  TextEditingController _subAccountEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;

  late File files;

  String _subAccountQuery = "";
  bool _subAccountAlreadyExists = false;
  SubAccounts? _selectedSubAccount;
  String _autocompleteText = "";

  Timer? autoCompleteDeBouncer;


  ScrollController _scrollController = ScrollController();


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
      _subAccountQuery = query;
      print("Query set to: $_subAccountQuery");
      var provider = Provider.of<SubAccountListProvider>(context, listen: false);
      provider.page = 1;
      await provider.fetchSubAccountList(context, widget.accountId, _subAccountQuery, provider.page, 2);
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
    print("autoCompleteSubAccountsSearchClient called with query: $query");
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<SubAccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteSubAccountList(context, query, widget.accountId);

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
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    _getData();
  }

  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubAccountListProvider>(context, listen: false).page = 1;
      Provider.of<SubAccountListProvider>(context, listen: false)
          .fetchSubAccountList(context, widget.accountId, "", 1, 10);
    });
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context1);
    return SafeArea(
      child: Consumer<ThemeProvider>(
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
          floatingActionButton: _selectedScreen == Screens.subAccountList
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
            onPressed: () {
              // Add sub account dialog with autocomplete from api and create account
              _showAddSubAccountDialog(context);

            },
            child: Icon(Icons.add),
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
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          Expanded(
                                            child: Consumer<SubAccountListProvider>(
                                              builder: (context, subAccountListProvider, _) {
                                                return SingleChildScrollView(
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
                                                        child: Row(
                                                          children: [
                                                            Text('My Sub Accounts', style: typography.Subtitle2),
                                                            subAccountListProvider.isLoading||subAccountListProvider.totalRecords == 0?SizedBox():SizedBox(width: CustomSpacing.two,),
                                                            subAccountListProvider.isLoading||subAccountListProvider.totalRecords == 0?SizedBox():SizedBox(
                                                              height: 25,
                                                              child: Chip(
                                                                labelPadding: EdgeInsets.all(0),
                                                                materialTapTargetSize:
                                                                MaterialTapTargetSize.shrinkWrap,
                                                                label: Text(
                                                                  subAccountListProvider.totalRecords
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
                                                      Tab(text: 'Configuration'),
                                                      //Tab(text: 'Access Requests'),
                                                    ],
                                                  ),
                                                );
                                              }
                                            ),
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
                                  _getSubAccountUI(),
                                  _getComingSoonUI(),
                                  ConfigurationTab(accountId: widget.accountId),
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
        );
      }),
    );
  }

  Widget _buildSubAccountCard(int index, SubAccountListProvider subAccountListProvider) {
    var typography = CustomTypography(context);
    bool isDisabled = subAccountListProvider.subAccountList[index].disabled;
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
        onTap: isDisabled?null:() {
          // On tap of card

          if (showCheckbox) {
            setState(() {
              subAccountListProvider.subAccountList[index].isChecked =
                  !(subAccountListProvider.subAccountList[index].isChecked ?? false);
            });
          }
          // if all are unselected then hide checkbox
          if (subAccountListProvider.subAccountList
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
              MyLocationList(accountID: widget.accountId, subAccountID: subAccountListProvider.subAccountList[index].subAccountId ?? "", accountName: widget.accountName??"", subAccountName: subAccountListProvider.subAccountList[index].name??"",);
          }));
          /*LocationList(
            userId: subAccountListProvider.subAccountList[index].sub ?? "",
            companyName:
            subAccountListProvider.subAccountList[index].accountName ?? "",
          );*/
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
                    color: isDisabled?
                    Theme.of(context).colorScheme.scrim:
                    Theme.of(context).colorScheme.surface,
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
                                          (subAccountListProvider
                                                          .subAccountList[index]
                                                          .name ??
                                                      "")
                                                  .isNotEmpty
                                              ? subAccountListProvider
                                                      .subAccountList[index]
                                                      .name!
                                                      .substring(0, 1)
                                                      .toUpperCase() +
                                                  subAccountListProvider
                                                      .subAccountList[index]
                                                      .name!
                                                      .substring(1)
                                              : "",
                                          style:
                                              typography.Body2.copyWith(
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
                                      isDisabled?SizedBox():InkWell(
                                        onTap: () {
                                          _subAccountEditNameController.text =
                                          (subAccountListProvider
                                              .subAccountList[index]
                                              .name ??
                                              "")
                                              .isNotEmpty
                                              ? subAccountListProvider
                                              .subAccountList[index]
                                              .name!
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              subAccountListProvider
                                                  .subAccountList[index]
                                                  .name!
                                                  .substring(1)
                                              : "";
                                          // Show edit dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "sub_account_list_edit_sub_account_title"),
                                                  style: typography
                                                      .H5_Regular,
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          _subAccountEditNameController,

                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        labelText:
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "sub_account_list_app_edit_label_text"),
                                                        labelStyle:
                                                            typography
                                                                .Body1,
                                                        hintText:
                                                            LanguageService
                                                                .getTranslated(
                                                                    context,
                                                                    "sub_account_list_app_edit_label_hint_text"),
                                                        hintStyle:
                                                            typography
                                                                .Body1,
                                                      ),
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
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              LanguageService
                                                                  .getTranslated(
                                                                      context,
                                                                      "sub_account_list_app_edit_cancel_text"),
                                                              style: typography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                                ButtonType.text,
                                                          ),
                                                        ),
                                                        Consumer<SubAccountListProvider>(
                                                          builder: (context, subAccountListProvider, _) {
                                                            return subAccountListProvider.isRenameLoading?
                                                            const Expanded(
                                                              child:  Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                                                                ],
                                                              ),
                                                            )
                                                                :Expanded(
                                                              child: CustomButton(
                                                                onPressed: () async {
                                                                  if(_subAccountEditNameController.text.isEmpty){
                                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_rename_sub_account_empty_text_error"), style: typography.Body1,)));
                                                                    return;
                                                                  }
                                                                  // Update account details
                                                                  await subAccountListProvider
                                                                      .renameSubAccount(
                                                                          context,
                                                                          widget.accountId,
                                                                          subAccountListProvider
                                                                              .subAccountList[index]
                                                                              .subAccountId!,
                                                                          _subAccountEditNameController
                                                                              .text);
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text(
                                                                  LanguageService
                                                                      .getTranslated(
                                                                          context,
                                                                          "sub_account_list_app_edit_update_text"),
                                                                  style: typography
                                                                      .ButtonLarge,
                                                                ),
                                                                type: ButtonType
                                                                    .elevated,
                                                              ),
                                                            );
                                                          }
                                                        ),
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
                                  !subAccountListProvider.showSovCount
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                subAccountListProvider
                                                                .subAccountList[
                                                                    index]
                                                                .sovCount !=
                                                            null &&
                                                        subAccountListProvider
                                                                .subAccountList[
                                                                    index]
                                                                .sovCount ==
                                                            1
                                                    ? LanguageService.getTranslated(
                                                        context,
                                                        "sub_account_list_app_sov_text")
                                                    : subAccountListProvider
                                                                .subAccountList[
                                                                    index]
                                                                .sovCount ==
                                                            null
                                                        ? ""
                                                        : LanguageService
                                                            .getTranslated(
                                                                context,
                                                                "sub_account_list_app_sovs_text"),
                                                style:
                                                    typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                subAccountListProvider
                                                        .subAccountList[index]
                                                        .sovCount
                                                        ?.toString() ??
                                                    "",
                                                style:
                                                    typography.Caption),
                                          ],
                                        ),
                                  !subAccountListProvider.showOwner
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "sub_account_list_app_owner_text"),
                                                style:
                                                    typography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                /*accountListProvider.accountList[index].locationCount?.toString() ??
                                              ""*/
                                                subAccountListProvider
                                                        .subAccountList[index]
                                                        .owner
                                                        ?.name ??
                                                    "",
                                                style:
                                                    typography.Caption),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: CustomSpacing.two,
                        ),
                      ],
                    ),
                  ),
                  isDisabled?SizedBox():Container(
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
                                subAccountListProvider.subAccountList[index]);
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
                            _showUploadDialog(subAccountListProvider.subAccountList[index].accountId.toString(), subAccountListProvider.subAccountList[index].subAccountId.toString());
                          },
                          tooltip: LanguageService.getTranslated(
                              context, "sub_account_list_app_export_tooltip_text"),
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
                                    LanguageService.getTranslated(
                                        context, "sub_account_list_app_duplicate_title"),
                                    style: typography.H5_Regular,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LanguageService.getTranslated(
                                            context,
                                            "sub_account_list_app_duplicate_text"),
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
                                                    context, "sub_account_list_app_duplicate_cancel"),
                                                style: typography.ButtonLarge,
                                              ),
                                              type: ButtonType.text,
                                            ),
                                          ),
                                          subAccountListProvider.isDuplicateLoading?
                                          const Expanded(
                                            child:  Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                                              ],
                                            ),
                                          )
                                              :
                                          Expanded(
                                            child: CustomButton(
                                              onPressed: () async {
                                                // Duplicate
                                                await subAccountListProvider.duplicateSubAccount(
                                                    context,
                                                    widget.accountId,
                                                    subAccountListProvider
                                                        .subAccountList[index]
                                                        .subAccountId!);
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context, "sub_account_list_app_duplicate_duplicate"),
                                                style: typography.ButtonLarge,
                                              ),
                                              type: ButtonType.elevated,
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
                          tooltip: LanguageService.getTranslated(
                              context, "sub_account_list_app_duplicate_tooltip_text"),
                        ),
                        /*IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: AppColors.primaryMain,
                          ),
                          onPressed: () {
                            _showSettingsModal(context, index);
                          },
                          tooltip: LanguageService.getTranslated(
                              context, "sub_account_list_app_settings_tooltip_text"),
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

  void _showSettingsModal(BuildContext context, int index) {
    var typography = CustomTypography(context);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Consumer<SubAccountListProvider>(
              builder: (context, subAccountListProvider, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: subAccountListProvider.isOwnerLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: subAccountListProvider.showOwner,
                        onChanged: (value) async {
                          bool result = await subAccountListProvider.changeColumnVisibility(context,accountId: widget.accountId, showOwner: value??false, showSOVCount: subAccountListProvider.showSovCount, showOverallScore: subAccountListProvider.showOverallScore, type: 'owner');

                          if(result){
                            setModalState(() {
                              subAccountListProvider.showOwner = value ?? false;
                            });
                            setState(() {
                              subAccountListProvider.showOwner = value ?? false;
                            });
                            // Update account list
                            subAccountListProvider.fetchSubAccountList(context, widget.accountId, _subAccountQuery, subAccountListProvider.page, 2);
                          }

                        },
                      ),
                      title: Text(LanguageService.getTranslated(context, "sub_account_list_app_column_owner_text"), style: typography.Body1),
                    ),
                    ListTile(
                      leading: subAccountListProvider.showSOVCountLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: subAccountListProvider.showSovCount,
                        onChanged: (value) async {
                          bool result = await subAccountListProvider.changeColumnVisibility(context,accountId: widget.accountId, showOwner: value??false, showSOVCount: subAccountListProvider.showSovCount, showOverallScore: subAccountListProvider.showOverallScore, type: 'sov_count');

                          if(result){
                            setModalState(() {
                              subAccountListProvider.showSovCount = value ?? false;
                            });
                            setState(() {
                              subAccountListProvider.showSovCount = value ?? false;
                            });
                            // Update account list
                            subAccountListProvider.fetchSubAccountList(context, widget.accountId, _subAccountQuery, subAccountListProvider.page, 2);
                          }
                        },
                      ),
                      title: Text(LanguageService.getTranslated(context, "sub_account_list_app_column_sov_count_text"), style: typography.Body1),
                    ),
                  ],
                );
              }
            );
          },
        );
      },
    );
  }

  Future<void> _showAddSubAccountDialog(BuildContext context) async {
    var typography = CustomTypography(context);
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LanguageService.getTranslated(context, "sub_account_list_app_add_account_title"),
                      style: typography.H5_Regular,
                    ),
                    SizedBox(height: 8.0),
                    Consumer<SubAccountListProvider>(
                      builder: (context, subAccountListProvider, child) {
                        return Column(
                          children: [
                            // Chip with Account Name
                            Chip(
                              label: Text(
                                widget.accountName ?? "",
                                style: typography.Body1,
                              ),
                            ),
                            SizedBox(height: 8,),
                            TextField(
                              controller: _textEditingController,
                              focusNode: FocusNode(),
                              onChanged: (value) async {
                                setState(() {
                                  _subAccountAlreadyExists = false;
                                  _selectedSubAccount = null;
                                  // Clear the autocomplete list when user starts typing
                                  subAccountListProvider.clearAutoCompleteList();
                                });
                                _autocompleteText = value;
                                await autoCompleteAccountsSearchClient(_autocompleteText);
                              },
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(context, "sub_account_list_app_account_name_field_label"),
                                hintText: LanguageService.getTranslated(context, "sub_account_list_app_account_name_field_hint"),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            if (_textEditingController.text.isNotEmpty && !_subAccountAlreadyExists)
                              AutocompleteOptionsSubAccount(
                                options: subAccountListProvider.autoCompleteSubAccountList,
                                onSelected: (SubAccounts selection) {
                                  setState(() {
                                    _subAccountAlreadyExists = true;
                                    _selectedSubAccount = selection;
                                    _textEditingController.text = selection.name!;
                                    // Clear the autocomplete list when an option is selected
                                    subAccountListProvider.clearAutoCompleteList();
                                  });
                                },
                                isLoading: subAccountListProvider.isAutoCompleteLoading,
                              ),
                            if (_subAccountAlreadyExists)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    labelText: LanguageService.getTranslated(context, "sub_account_list_app_comment_text"),
                                    hintText: LanguageService.getTranslated(context, "sub_account_list_app_comment_placeholder"),
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
                              child: Consumer<SubAccountListProvider>(builder: (context, subAccountListProvider, _) {
                                return subAccountListProvider.isAddSubAccountLoading
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 25, height: 25, child: CircularProgressIndicator()),
                                  ],
                                )
                                    : CustomButton(
                                  onPressed: () async {
                                    if (_autocompleteText.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_add_sub_account_empty_text_error"), style: typography.Body1,)));
                                      return;
                                    }

                                    if (!_subAccountAlreadyExists) {
                                      // Add account
                                      await subAccountListProvider.addSubAccount(context, _autocompleteText, widget.accountId);
                                    } else {
                                      // Request access
                                      if (_messageController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_comment_empty_text_error"), style: typography.Body1,)));
                                        return;
                                      }
                                      await subAccountListProvider.requestAccess(context, _selectedSubAccount?.subAccountId ?? "", _messageController.text, widget.accountId);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    _subAccountAlreadyExists
                                        ? LanguageService.getTranslated(context, "sub_account_list_app_request_access_text")
                                        : LanguageService.getTranslated(context, "sub_account_list_app_submit_text"),
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
                            Navigator.pop(context);
                          },
                          child: Text(
                            LanguageService.getTranslated(context, "sub_account_list_app_cancel_text"),
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
      Provider.of<AccountListProvider>(context, listen: false).clearAutoCompleteList();
      _textEditingController.clear();
      _messageController.clear();
      _subAccountAlreadyExists = false;
    });
  }

  void _showUploadDialog(String accountId, String subAccountId) {
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
                      Text(
                          LanguageService.getTranslated(
                              context, "account_list_app_account_upload_sov"),
                          textAlign: TextAlign.start,
                          style: typography.Body1),
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
                              String fileNameWithExtension = file.path.split('/').last;
                              _uploadedFileName = fileNameWithExtension.split('.').first;
                              _sovNameController.text = _uploadedFileName!;
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
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                              LanguageService.getTranslated(
                                  context, "account_list_app_account_sov_name_1"),
                              textAlign: TextAlign.start,
                              style: typography.Body1),
                          Flexible(
                            child: Center(
                              child: Text(
                                  widget.accountName ?? "",
                                  textAlign: TextAlign.start,
                                  style: typography.Body1),
                            ),
                          ),
                          Text(
                              LanguageService.getTranslated(
                                  context, "account_list_app_account_sov_name_2"),
                              textAlign: TextAlign.start,
                              style: typography.Body1),
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _sovNameController,
                        readOnly: false,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(
                              context, "account_list_app_sov_name"),
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          hintText: LanguageService.getTranslated(
                              context, "account_list_app_account_name_of_sov"),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer<SubAccountListProvider>(
                              builder: (_, subAccountProvider, child) {
                                return subAccountProvider.isImageUploadLoading
                                    ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                    : Container(
                                  width:
                                  MediaQuery.of(context).size.width / 1.2,
                                  child: CustomButton(
                                    onPressed: () async {
                                      String success = (await Provider.of<
                                          SubAccountListProvider>(
                                          context,
                                          listen: false)
                                          .uploadSovAccount(context, files, accountId, subAccountId, _sovNameController.text));

                                      print('Success: $success');
                                      // contain symbol +
                                      if(success.isNotEmpty && success.contains('+')){
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
                                                  style: typography.H5_Regular,
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      /* LanguageService.getTranslated(
                                                            context,
                                                            "account_list_app_empty_sov_text"),*/
                                                      'Looks Like, Data has not been specified!! Do you want to continue creating an empty SOV, or abort?',
                                                      style: typography.Body1,
                                                    ),
                                                    SizedBox(
                                                      height: CustomSpacing.two,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                      children: [
                                                        Consumer<UploadSovProvider>(
                                                            builder: (context, uploadSovProvider, child) {
                                                              return uploadSovProvider.isLoading?
                                                              const Center(
                                                                child: CircularProgressIndicator(),
                                                              ):
                                                              CustomButton(
                                                                onPressed: () async {
                                                                  // Create empty SOV
                                                                  var provider = Provider.of<UploadSovProvider>(context, listen: false);
                                                                  await provider.createEmptySov(context, success);
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text(
                                                                  /*LanguageService.getTranslated(
                                                                      context,
                                                                      "account_list_app_empty_sov_create"),*/
                                                                  'Create',
                                                                  style: typography.ButtonLarge,
                                                                ),
                                                                type: ButtonType.elevated,
                                                              );
                                                            }
                                                        ),
                                                        CustomButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          child: Text(
                                                            /*LanguageService.getTranslated(
                                                                  context,
                                                                  "account_list_app_empty_sov_abort")*/
                                                            'Abort',
                                                            style: typography.ButtonLarge,
                                                          ),
                                                          type: ButtonType.text,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            });
                                      }
                                      else if(success.isNotEmpty) {

                                        Navigator.push(context, MaterialPageRoute(builder: (_) => MappingScreen(tempId: success, accountId: widget.accountId, accountName: widget.accountName??"",)));

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

  Future<void> _showTransferDialog(BuildContext context, SubAccounts subAccount) async {
    var typography = CustomTypography(context);
    TextEditingController _userSearchController = TextEditingController();
    TransferAutocompleteModel? _selectedUser;
    List<TransferAutocompleteModel> _autocompleteUsersList = [];
    bool _isTransferLoading = false;
    bool _isSearching = false;
    Timer? _debounce;

    void _onSearchChanged(String query, StateSetter setState) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (query.isNotEmpty) {
          setState(() {
            _isSearching = true;
          });

          _autocompleteUsersList = await fetchAutocompleteUsers(query);

          setState(() {
            _isSearching = false;
          });
        } else {
          setState(() {
            _autocompleteUsersList.clear();
            _isSearching = false;
          });
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                        'Transfer Sub-Account',
                        style: typography.H5_Regular.copyWith(height: 1.2),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _userSearchController,
                        onChanged: (query) {
                          setState(() {
                            _selectedUser = null;
                          });
                          _onSearchChanged(query, setState);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for a user to transfer sub-account',
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
                              backgroundImage: NetworkImage(user.imageUrl),
                            )
                                : CircleAvatar(
                              child: Text(user.name[0].toUpperCase()),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _userSearchController.text = user.name;
                              });
                            },
                          );
                        },
                      )
                          : Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Selected User: ${_selectedUser!.name}'),
                      ),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: _selectedUser != null && !_isTransferLoading
                              ? () async {
                            setState(() {
                              _isTransferLoading = true;
                            });
                            var provider = Provider.of<SubAccountListProvider>(context, listen: false);
                            await provider.transferSubAccount(context, widget.accountId, subAccount.subAccountId!, _selectedUser!.id);
                            setState(() {
                              _isTransferLoading = false;
                            });
                            Navigator.pop(dialogContext);
                          }
                              : null,
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
      if (_debounce?.isActive ?? false) _debounce?.cancel();
    });
  }


  Future<List<TransferAutocompleteModel>> fetchAutocompleteUsers(
      String query) async {
    try {
      ApiService apiService = ApiService(AppConstant.TRANSFER_USER_AUTOCOMPLETE);
      String url = '?search=$query';
      var response = await apiService.get(url);

      // Parse the response to extract user data
      List<TransferAutocompleteModel> users = (response['result'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Widget _getSubAccountUI() {
    var typography = CustomTypography(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: CustomSpacing.four),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${LanguageService.getTranslated(context, "sub_account_list_app_title")} ',
              style: typography.Body1,
            ),
          ],
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
              suffixIcon: _subAccountQuery.isNotEmpty
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
                  context, "sub_account_list_search_hint"),
              hintStyle: typography.Body2,
            ),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
        // List of sub accounts
        Expanded(
          child: Consumer<SubAccountListProvider>(
              builder: (context, subAccountListProvider, _) {
                return subAccountListProvider.isLoading
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
                    : subAccountListProvider.subAccountList.isEmpty
                    ? Center(
                  child: Text(
                    "Looks like you don't have a sub-account yet. No worries! Just create a new one and start adding your locations.",
                    style: typography.Body1,
                  ),
                )
                    :
                ListView.builder(
                  itemCount: subAccountListProvider
                      .subAccountList.length,
                  itemBuilder: (context, index) {
                    print("Query1: $_subAccountQuery");
                    if (index ==
                        subAccountListProvider
                            .subAccountList.length -
                            1) {
                      // Check if it's the last item
                      if (subAccountListProvider
                          .isNextPageLoading) {
                        // Display loading indicator
                        return Padding(
                          padding:
                          const EdgeInsets.all(8.0),
                          child: Center(
                            child:
                            CircularProgressIndicator(),
                          ),
                        );
                      } else if (subAccountListProvider.page >=
                          subAccountListProvider.totalPages&&subAccountListProvider.subAccountList.isNotEmpty) {
                        // Display end of list message
                        print("sub account list: ${subAccountListProvider.subAccountList}");
                        return Column(
                          children: [
                            _buildSubAccountCard(
                                index, subAccountListProvider),
                            Padding(
                              padding:
                              const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(LanguageService.getTranslated(
                                    context,
                                    "sub_account_list_app_end_of_list_text"),
                                  style: typography.Body1,
                                ),
                              ), ),
                          ],
                        );
                      } else {
                        // Trigger fetching the next page
                        subAccountListProvider.page =
                            subAccountListProvider.page + 1;
                        print(
                            "Fetching page ${subAccountListProvider.page}");
                        print(
                            "Query: $_subAccountQuery, Page: ${subAccountListProvider.page}");
                        subAccountListProvider
                            .fetchSubAccountList(
                          context,
                          widget.accountId,
                          _subAccountQuery,
                          // Pass the search query if any
                          subAccountListProvider.page,
                          10, // Page size
                        );
                        return SizedBox();
                      }
                    }

                    return _buildSubAccountCard(
                        index, subAccountListProvider);
                  },
                );
              }),
        ),
      ],
    );
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
}
