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

  bool showOwner = true;
  bool showSovCount = true;
  bool showSubAccountCount = true;
  bool showOverallScore = true;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  TextEditingController _accountEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;

  String _accountQuery = "";
  bool _accountAlreadyExists = false;
  Accounts? _selectedAccount;
  String _autocompleteText = "";

  Timer? autoCompleteDeBouncer;

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
      await provider.fetchAccountList(context, _accountQuery, provider.page, 2);
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

  void autoCompleteAccountsSearchClient(String query) async {
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<AccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteAccountList(context, query);
    });
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountListProvider>(context, listen: false).page = 1;
      Provider.of<AccountListProvider>(context, listen: false)
          .fetchAccountList(context, "", 1, 2);
    });
  }

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
                            _tabController?.animateTo(3);
                            _selectedScreen = Screens.networkList;
                          },
                          child: Icon(Icons.add),
                        ),
                      ],
                    );
                  })
                : FloatingActionButton(
                    onPressed: () {
                      // Add account dialog with autocomplete from api and create account
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Material(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).viewInsets.bottom,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                                    child:  Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          LanguageService.getTranslated(context, "account_list_app_add_account_title"),
                                          style: CustomTypography.H5_Regular,
                                        ),
                                        SizedBox(height: 16.0),
                                    Consumer<AccountListProvider>(
                                      builder: (context, accountListProvider, child) {
                                        return Autocomplete<Accounts>(
                                          optionsBuilder: (TextEditingValue textEditingValue) {
                                            print("AutoComplete: ${accountListProvider.autoCompleteAccountList}");
                                            if (textEditingValue.text.isEmpty || accountListProvider.autoCompleteAccountList.isEmpty) {
                                              print("No options to return");
                                              print("Checking conditions: ${textEditingValue.text.isEmpty} || ${accountListProvider.autoCompleteAccountList.isEmpty}");
                                              return const Iterable<Accounts>.empty();
                                            }
                                            var filteredOptions;
                                           try {
                                             filteredOptions = accountListProvider.autoCompleteAccountList.where((Accounts option) {
                                               final accountName = option.accountName;
                                               if (accountName != null) {
                                                 return accountName.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                               }
                                               return false;
                                             }).toList();

                                             print("Filtered options to return: $filteredOptions");
                                           } catch (e, stack) {
                                              print("Error: $e, Stack: $stack");
                                           }
                                            print("Filtered options to return: $filteredOptions");
                                            return filteredOptions;
                                          },
                                          optionsViewBuilder: (context, onSelected, options) {
                                            print("Options in ViewBuilder: $options");
                                            return Container(
                                              height: 52.0 * options.length,
                                              width: MediaQuery.of(context).size.width - 32, // Adjust the width
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: options.length,
                                                physics: ClampingScrollPhysics(),
                                                shrinkWrap: false,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final option = options.elementAt(index);
                                                  return GestureDetector(
                                                    onTap: () => onSelected(option),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16.0),
                                                      child: Text('${option.accountName}', style: CustomTypography.Subtitle1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          onSelected: (Accounts selection) {
                                            setState(() {
                                              _accountAlreadyExists = true;
                                              _selectedAccount = selection;
                                            });
                                          },
                                          displayStringForOption: (Accounts option) => option.accountName ?? "",
                                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                            return TextFormField(
                                              controller: textEditingController,
                                              focusNode: focusNode,
                                              onFieldSubmitted: (_) {},
                                              onChanged: (value) {
                                                setState(() {
                                                  _accountAlreadyExists = false;
                                                  _selectedAccount = null;
                                                });
                                                accountListProvider.autoCompleteAccountList.clear();
                                                _autocompleteText = value;
                                                accountListProvider.fetchAutoCompleteAccountList(context, value);
                                              },
                                              decoration: InputDecoration(
                                                labelText: LanguageService.getTranslated(context, "register_corporate_legalname_field_label"),
                                                hintText: LanguageService.getTranslated(context, "register_corporate_legalname_filed_placeholder"),
                                                border: const OutlineInputBorder(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),

                                    SizedBox(height: CustomSpacing.six),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomButton(
                                                onPressed: () {
                                                  // Cancel
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  LanguageService.getTranslated(context, "account_list_app_cancel_text"),
                                                  style: CustomTypography.ButtonLarge,
                                                ),
                                                type: ButtonType.text,
                                              ),
                                            ),
                                            Consumer<AccountListProvider>(builder: (context, accountListProvider, _) {
                                              return accountListProvider.isAddAccountLoading
                                                  ? const Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(width: 25, height: 25, child: CircularProgressIndicator()),
                                                  ],
                                                ),
                                              )
                                                  : Expanded(
                                                child: CustomButton(
                                                  onPressed: () async {
                                                    if(_autocompleteText.isEmpty){
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "account_list_app_add_account_empty_text_error"), style: CustomTypography.Body1,)));
                                                      return;
                                                    }

                                                    if (!_accountAlreadyExists) {
                                                      // Add account
                                                      await accountListProvider.addAccount(context, _autocompleteText);
                                                      return;
                                                    } else {
                                                      // Request access
                                                      await accountListProvider.requestAccess(context, _selectedAccount?.accountId ?? "", _messageController.text);
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    LanguageService.getTranslated(context, "account_list_app_add_text"),
                                                    style: CustomTypography.ButtonLarge,
                                                  ),
                                                  type: ButtonType.elevated,
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),

                                  ),
                                ),
                              );
                            }
                          );
                        },
                      );


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
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            LanguageService.getTranslated(
                                context, "account_list_app_subtitle"),
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
                              return accountListProvider.isLoading
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
                                  : accountListProvider.accountList.isEmpty
                                      ? Center(
                                          child: Text(
                                            LanguageService.getTranslated(
                                                context,
                                                "account_list_app_no_accounts_text"),
                                            style: CustomTypography.Body1,
                                          ),
                                        )
                                      :
                              ListView.builder(
                                      itemCount: accountListProvider
                                          .accountList.length,
                                      itemBuilder: (context, index) {
                                        print("Query1: $_accountQuery");
                                        if (index ==
                                            accountListProvider
                                                    .accountList.length -
                                                1) {
                                          // Check if it's the last item
                                          if (accountListProvider
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
                                          } else if (accountListProvider.page >=
                                              accountListProvider.totalPages) {
                                            // Display end of list message
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                child: Text(LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_end_of_list_text"),
                                                  style: CustomTypography.Body1,
                                              ),
                                            ), );
                                          } else {
                                            // Trigger fetching the next page
                                            accountListProvider.page =
                                                accountListProvider.page + 1;
                                            print(
                                                "Fetching page ${accountListProvider.page}");
                                            print(
                                                "Query: $_accountQuery, Page: ${accountListProvider.page}");
                                            accountListProvider
                                                .fetchAccountList(
                                              context,
                                              _accountQuery,
                                              // Pass the search query if any
                                              accountListProvider.page,
                                              2, // Page size
                                            );
                                            return SizedBox();
                                          }
                                        }

                                        return _buildAccountCard(
                                            index, accountListProvider);
                                      },
                                    );
                            }),
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
        onTap: () {
          // On tap of card

          if (showCheckbox) {
            setState(() {
              accountListProvider.accountList[index].isChecked =
                  !(accountListProvider.accountList[index].isChecked ?? false);
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
                LocationList(
              userId: accountListProvider.accountList[index].accountId ?? "",
              companyName:
                  accountListProvider.accountList[index].accountName ?? "",
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
            SizedBox(
              width: CustomSpacing.two,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Card(
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
                                          style:
                                              CustomTypography.Body2.copyWith(
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
                                      InkWell(
                                        onTap: () {
                                          _accountEditNameController.text =
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
                                              : "";
                                          // Show edit dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                  LanguageService.getTranslated(
                                                      context,
                                                      "account_list_edit_account_title"),
                                                  style: CustomTypography
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
                                                            CustomTypography
                                                                .Body1,
                                                        hintText:
                                                            'Enter Account Name',
                                                        hintStyle:
                                                            CustomTypography
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
                                                              'Cancel',
                                                              style: CustomTypography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                                ButtonType.text,
                                                          ),
                                                        ),
                                                        Consumer<AccountListProvider>(
                                                          builder: (context, accountListProvider, _) {
                                                            return accountListProvider.isRenameLoading?
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
                                                                  if(_accountEditNameController.text.isEmpty){
                                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "account_list_app_rename_account_empty_text_error"), style: CustomTypography.Body1,)));
                                                                    return;
                                                                  }
                                                                  // Update account details
                                                                  await accountListProvider
                                                                      .renameAccount(
                                                                          context,
                                                                          accountListProvider
                                                                              .accountList[
                                                                                  index]
                                                                              .accountId!,
                                                                          _accountEditNameController
                                                                              .text);
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text(
                                                                  'Update',
                                                                  style: CustomTypography
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
                                  !showSubAccountCount
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
                                                style:
                                                    CustomTypography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                accountListProvider
                                                        .accountList[index]
                                                        .subAccountCount
                                                        ?.toString() ??
                                                    "",
                                                style:
                                                    CustomTypography.Caption),
                                          ],
                                        ),
                                  !showSovCount
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
                                                style:
                                                    CustomTypography.Caption),
                                            SizedBox(
                                              width: CustomSpacing.two,
                                            ),
                                            Text(
                                                accountListProvider
                                                        .accountList[index]
                                                        .sovCount
                                                        ?.toString() ??
                                                    "",
                                                style:
                                                    CustomTypography.Caption),
                                          ],
                                        ),
                                  !showOwner
                                      ? SizedBox()
                                      : Row(
                                          children: [
                                            Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "account_list_app_owner_text"),
                                                style:
                                                    CustomTypography.Caption),
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
                                                style:
                                                    CustomTypography.Caption),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                            !showOverallScore
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
                  Container(
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
                        /*TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.history),
                          label: Text('View History',
                              style: CustomTypography.Caption.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black)),
                        ),*/
                        SizedBox(),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.upload_rounded),
                          color: AppColors.primaryMain,
                          onPressed: () async {},
                          tooltip: 'Export',
                        ),
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
                                        context, "account_list_app_duplicate_title"),
                                    style: CustomTypography.H5_Regular,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LanguageService.getTranslated(
                                            context,
                                            "account_list_app_duplicate_text"),
                                        style: CustomTypography.Body1,
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
                                                    context, "account_list_app_duplicate_cancel"),
                                                style: CustomTypography.ButtonLarge,
                                              ),
                                              type: ButtonType.text,
                                            ),
                                          ),
                                          accountListProvider.isDuplicateLoading?
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
                                                await accountListProvider.duplicateAccount(
                                                    context,
                                                    accountListProvider
                                                        .accountList[index]
                                                        .accountId!);
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context, "account_list_app_duplicate_duplicate"),
                                                style: CustomTypography.ButtonLarge,
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
                          tooltip: 'Duplicate',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: AppColors.primaryMain,
                          ),
                          onPressed: () {
                            _showSettingsModal(context);
                          },
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: CustomSpacing.two,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
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
                      leading: accountListProvider.isOwnerLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: showOwner,
                        onChanged: (value) async {
                          bool result = await accountListProvider.changeColumnVisibility(context, showOwner: value??false, showSOVCount: showSovCount, showSubAccountCount: showSubAccountCount, showOverallScore: showOverallScore, type: 'owner');

                          if(result){
                            setModalState(() {
                              showOwner = value ?? false;
                            });
                            setState(() {
                              showOwner = value ?? false;
                            });
                            // Update account list
                            accountListProvider.fetchAccountList(context, _accountQuery, accountListProvider.page, 2);
                          }

                        },
                      ),
                      title: Text(LanguageService.getTranslated(context, "account_list_app_column_owner_text"), style: CustomTypography.Body1),
                    ),
                    ListTile(
                      leading: accountListProvider.showSOVCountLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: showSovCount,
                        onChanged: (value) async {
                          bool result = await accountListProvider.changeColumnVisibility(context, showOwner: value??false, showSOVCount: showSovCount, showSubAccountCount: showSubAccountCount, showOverallScore: showOverallScore, type: 'sov_count');

                          if(result){
                            setModalState(() {
                              showSovCount = value ?? false;
                            });
                            setState(() {
                              showSovCount = value ?? false;
                            });
                            // Update account list
                            accountListProvider.fetchAccountList(context, _accountQuery, accountListProvider.page, 2);
                          }
                        },
                      ),
                      title: Text(LanguageService.getTranslated(context, "account_list_app_column_sov_count_text"), style: CustomTypography.Body1),
                    ),
                    ListTile(
                      leading:  accountListProvider.showSubAccountCountLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: showSubAccountCount,
                        onChanged: (value) async {
                         bool result = await  accountListProvider.changeColumnVisibility(context, showOwner: showOwner, showSOVCount: showSovCount, showSubAccountCount: value??false, showOverallScore: showOverallScore, type: 'sub_account_count');
                         if(result){
                           setModalState(() {
                             showSubAccountCount = value ?? false;
                           });
                           setState(() {
                             showSubAccountCount = value ?? false;
                           });
                           // Update account list
                           accountListProvider.fetchAccountList(context, _accountQuery, accountListProvider.page, 2);
                         }
                        },
                      ),
                      title:
                          Text(LanguageService.getTranslated(context, "account_list_app_column_sub_account_count_text") , style: CustomTypography.Body1),
                    ),
                    ListTile(
                      leading:   accountListProvider.showOverallScoreLoading?
                      Padding(
                        padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                        child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                      )
                          :Checkbox(
                        value: showOverallScore,
                        onChanged: (value) async {

                          bool result = await  accountListProvider.changeColumnVisibility(context, showOwner: showOwner, showSOVCount: showSovCount, showSubAccountCount: showSubAccountCount, showOverallScore: value??false, type: 'overall_score');
                          if(result){
                            setModalState(() {
                              showOverallScore = value ?? false;
                            });
                            setState(() {
                              showOverallScore = value ?? false;
                            });
                            // Update account list
                            accountListProvider.fetchAccountList(context, _accountQuery, accountListProvider.page, 2);
                          }
                        },
                      ),
                      title: Text(LanguageService.getTranslated(context, "account_list_app_column_overall_score_text"), style: CustomTypography.Body1),
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
}
