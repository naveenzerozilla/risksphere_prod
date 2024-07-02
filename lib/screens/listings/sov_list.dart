import 'dart:async';
import 'dart:math';

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
import 'package:green/providers/sov_list_provider.dart';
import 'package:green/providers/sub_account_list_provider.dart';
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
import 'widgets/auto_complete_options.dart';

class SovListScreen extends StatefulWidget {

  final String accountId;
  final String accountName;
  final String subAccountId;
  final String subAccountName;

  const SovListScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.subAccountId,
    required this.subAccountName,
  });

  @override
  State<SovListScreen> createState() => _SovListScreenState();
}

class _SovListScreenState extends State<SovListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  Screens _selectedScreen = Screens.sovList;
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController _messageController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  TextEditingController _sovEditNameController = TextEditingController();

  int _selectedAccountIndex = 0;

  String _sovQuery = "";
  bool _sovAlreadyExists = false;
  Accounts? _selectedSov;
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

  void sovSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _sovQuery = query;
      print("Query set to: $_sovQuery");
      var provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 0;
      await provider.fetchSovList(context, widget.accountId, widget.subAccountId, _sovQuery, provider.page, 2);
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
    super.initState();
    _getData();
  }

  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SOVListProvider>(context, listen: false).page = 0;
      Provider.of<SOVListProvider>(context, listen: false)
          .fetchSovList(context, widget.accountId, widget.subAccountId, "", 0, 2);
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
                                '${LanguageService.getTranslated(context, "sov_list_app_title")} ',
                                style: CustomTypography.H5_Regular,
                              ),
                              Text(
                                LanguageService.getTranslated(
                                    context, "sov_list_app_subtitle"),
                                style: CustomTypography.Body2,
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // Search
                              SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: _textEditingController,
                                  onChanged: (query) {
                                    sovSearchClient(query);
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: LanguageService.getTranslated(
                                        context, "sov_list_search_hint"),
                                    hintStyle: CustomTypography.Body2,
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              SizedBox(height: CustomSpacing.four),
                              // List of accounts
                              Expanded(
                                child: Consumer<SOVListProvider>(
                                    builder: (context, sovListProvider, _) {
                                      return sovListProvider.isLoading
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
                                          : sovListProvider.sovList.isEmpty
                                          ? Center(
                                        child: Text(
                                          LanguageService.getTranslated(
                                              context,
                                              "sov_list_app_no_sov_text"),
                                          style: CustomTypography.Body1,
                                        ),
                                      )
                                          :
                                      ListView.builder(
                                        itemCount: sovListProvider
                                            .sovList.length,
                                        itemBuilder: (context, index) {
                                          print("Query1: $_sovQuery");
                                          if (index ==
                                              sovListProvider
                                                  .sovList.length -
                                                  1) {
                                            // Check if it's the last item
                                            if (sovListProvider
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
                                            } else if (sovListProvider.page >=
                                                sovListProvider.totalPages&&sovListProvider.sovList.isNotEmpty) {
                                              // Display end of list message
                                              print("sov list: ${sovListProvider.sovList}");
                                              return Column(
                                                children: [
                                                  _buildSovCard(
                                                      index, sovListProvider),
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets.all(8.0),
                                                    child: Center(
                                                      child: Text(LanguageService.getTranslated(
                                                          context,
                                                          "sov_list_app_end_of_list_text"),
                                                        style: CustomTypography.Body1,
                                                      ),
                                                    ), ),
                                                ],
                                              );
                                            } else {
                                              // Trigger fetching the next page
                                              sovListProvider.page =
                                                  sovListProvider.page + 1;
                                              print(
                                                  "Fetching page ${sovListProvider.page}");
                                              print(
                                                  "Query: $_sovQuery, Page: ${sovListProvider.page}");
                                              sovListProvider
                                                  .fetchSovList(
                                                context,
                                                widget.accountId,
                                                widget.subAccountId,
                                                _sovQuery,
                                                // Pass the search query if any
                                                sovListProvider.page,
                                                2, // Page size
                                              );
                                              return SizedBox();
                                            }
                                          }

                                          return _buildSovCard(
                                              index, sovListProvider);
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

  Widget _buildSovCard(int index, SOVListProvider subAccountListProvider) {
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
              subAccountListProvider.sovList[index].isChecked =
              !(subAccountListProvider.sovList[index].isChecked ?? false);
            });
          }
          // if all are unselected then hide checkbox
          if (subAccountListProvider.sovList
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
                userId: subAccountListProvider.sovList[index].accountId ?? "",
                companyName:
                subAccountListProvider.sovList[index].name ?? "",
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
                                          (subAccountListProvider
                                              .sovList[index]
                                              .name ??
                                              "")
                                              .isNotEmpty
                                              ? subAccountListProvider
                                              .sovList[index]
                                              .name!
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              subAccountListProvider
                                                  .sovList[index]
                                                  .name!
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
                                          _sovEditNameController.text =
                                          (subAccountListProvider
                                              .sovList[index]
                                              .name ??
                                              "")
                                              .isNotEmpty
                                              ? subAccountListProvider
                                              .sovList[index]
                                              .name!
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              subAccountListProvider
                                                  .sovList[index]
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
                                                      "sov_list_app_edit_sov_title"),
                                                  style: CustomTypography
                                                      .H5_Regular,
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        // add a chip with text then / then text field
                                                        Chip(
                                                          label: Text(
                                                           widget.accountName+" / "+widget.subAccountName,
                                                            style: CustomTypography
                                                                .Body1,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: CustomSpacing.two,
                                                        ),
                                                        TextField(
                                                          controller:
                                                          _sovEditNameController,

                                                          decoration:
                                                          InputDecoration(
                                                            border:
                                                            OutlineInputBorder(),
                                                            labelText:
                                                            LanguageService
                                                                .getTranslated(
                                                                context,
                                                                "sov_list_app_edit_label_text"),
                                                            labelStyle:
                                                            CustomTypography
                                                                .Body1,
                                                            hintText:
                                                            LanguageService
                                                                .getTranslated(
                                                                context,
                                                                "sov_list_app_edit_label_hint_text"),
                                                            hintStyle:
                                                            CustomTypography
                                                                .Body1,
                                                          ),
                                                        ),
                                                      ],
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
                                                                  "sov_list_app_edit_cancel_text"),
                                                              style: CustomTypography
                                                                  .ButtonLarge,
                                                            ),
                                                            type:
                                                            ButtonType.text,
                                                          ),
                                                        ),
                                                        Consumer<SOVListProvider>(
                                                            builder: (context, sovListProvider, _) {
                                                              return sovListProvider.isRenameLoading?
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
                                                                    if(_sovEditNameController.text.isEmpty){
                                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_rename_sub_account_empty_text_error"), style: CustomTypography.Body1,)));
                                                                      return;
                                                                    }
                                                                    // Update account details
                                                                    await sovListProvider
                                                                        .renameSov(
                                                                        context,
                                                                        widget.accountId,
                                                                        widget.subAccountId,
                                                                        sovListProvider
                                                                            .sovList[
                                                                        index]
                                                                            .id??"",
                                                                        _sovEditNameController
                                                                            .text);
                                                                    Navigator.pop(context);
                                                                  },
                                                                  child: Text(
                                                                    LanguageService
                                                                        .getTranslated(
                                                                        context,
                                                                        "sov_list_app_edit_update_text"),
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
                                  /// todo: add location count
                                ],
                              ),
                            ),
                            !subAccountListProvider.showOverallScore
                                ? SizedBox()
                                : Padding(
                              padding:
                              EdgeInsets.only(top: CustomSpacing.one),
                              child: CustomGradientCircularProgressBar(
                                radius: 23,
                                value: double.parse(subAccountListProvider
                                    .sovList[index].overAllScore
                                    ?.toString() ??
                                    "0"),
                                strokeWidth: 6,
                                showText: true,
                                textColor: Theme.of(context).brightness ==
                                    Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                                text: subAccountListProvider
                                    .sovList[index].overAllScore
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
                          tooltip: LanguageService.getTranslated(
                              context, "sov_list_app_export_tooltip_text"),
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
                                        context, "sov_list_app_duplicate_title"),
                                    style: CustomTypography.H5_Regular,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LanguageService.getTranslated(
                                            context,
                                            "sov_list_app_duplicate_text"),
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
                                                    context, "sov_list_app_duplicate_cancel"),
                                                style: CustomTypography.ButtonLarge,
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
                                                        .sovList[index]
                                                        .accountId!);
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context, "sov_list_app_duplicate_duplicate"),
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
                          tooltip: LanguageService.getTranslated(
                              context, "sov_list_app_duplicate_tooltip_text"),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: AppColors.primaryMain,
                          ),
                          onPressed: () {
                            _showSettingsModal(context, index);
                          },
                          tooltip: LanguageService.getTranslated(
                              context, "sov_list_app_settings_tooltip_text"),
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

  void _showSettingsModal(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Consumer<SOVListProvider>(
                builder: (context, sovListProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: sovListProvider.showLocationCount?
                        Padding(
                          padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                          child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                        )
                            :Checkbox(
                          value: sovListProvider.showLocationCount,
                          onChanged: (value) async {
                            bool result = await sovListProvider.changeColumnVisibility(context, widget.accountId, widget.subAccountId,showLocationCount: value??false, showOverallScore: sovListProvider.showOverallScore, type: 'location_count');

                            if(result){
                              setModalState(() {
                                sovListProvider.showLocationCount = value ?? false;
                              });
                              setState(() {
                                sovListProvider.showLocationCount = value ?? false;
                              });
                              // Update account list
                              sovListProvider.fetchSovList(context, widget.accountId, widget.subAccountId, _sovQuery, sovListProvider.page, 10);
                            }
                          },
                        ),
                        title: Text(LanguageService.getTranslated(context, "sov_list_app_column_location_count_text"), style: CustomTypography.Body1),
                      ),
                      ListTile(
                        leading:   sovListProvider.showOverallScoreLoading?
                        Padding(
                          padding: EdgeInsets.only(left: CustomSpacing.three, right: CustomSpacing.three),
                          child: SizedBox(width:25, height:25,child: CircularProgressIndicator()),
                        )
                            :Checkbox(
                          value: sovListProvider.showOverallScore,
                          onChanged: (value) async {

                            bool result = await  sovListProvider.changeColumnVisibility(context, widget.accountId, widget.subAccountId, showLocationCount: sovListProvider.showLocationCount, showOverallScore: value??false, type: 'overall_score');
                            if(result){
                              setModalState(() {
                                sovListProvider.showOverallScore = value ?? false;
                              });
                              setState(() {
                                sovListProvider.showOverallScore = value ?? false;
                              });
                              // Update account list
                              sovListProvider.fetchSovList(context, widget.accountId, widget.subAccountId, _sovQuery, sovListProvider.page, 10);
                            }
                          },
                        ),
                        title: Text(LanguageService.getTranslated(context, "sov_list_app_column_overall_score_text"), style: CustomTypography.Body1),
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
                      LanguageService.getTranslated(context, "account_list_app_add_account_title"),
                      style: CustomTypography.H5_Regular,
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
                                  _sovAlreadyExists = false;
                                  _selectedSov = null;
                                  // Clear the autocomplete list when user starts typing
                                  accountListProvider.clearAutoCompleteList();
                                });
                                _autocompleteText = value;
                                await autoCompleteAccountsSearchClient(_autocompleteText);
                              },
                              decoration: InputDecoration(
                                labelText: LanguageService.getTranslated(context, "register_corporate_legalname_field_label"),
                                hintText: LanguageService.getTranslated(context, "register_corporate_legalname_filed_placeholder"),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            if (_textEditingController.text.isNotEmpty && !_sovAlreadyExists)
                              AutocompleteOptions(
                                options: accountListProvider.autoCompleteAccountList,
                                onSelected: (Accounts selection) {
                                  setState(() {
                                    _sovAlreadyExists = true;
                                    _selectedSov = selection;
                                    _textEditingController.text = selection.accountName!;
                                    // Clear the autocomplete list when an option is selected
                                    accountListProvider.clearAutoCompleteList();
                                  });
                                },
                                isLoading: accountListProvider.isAutoCompleteLoading,
                              ),
                            if (_sovAlreadyExists)
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
                              child: Consumer<AccountListProvider>(builder: (context, accountListProvider, _) {
                                return accountListProvider.isAddAccountLoading
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 25, height: 25, child: CircularProgressIndicator()),
                                  ],
                                )
                                    : CustomButton(
                                  onPressed: () async {
                                    if (_autocompleteText.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_add_sub_account_empty_text_error"), style: CustomTypography.Body1,)));
                                      return;
                                    }

                                    if (!_sovAlreadyExists) {
                                      // Add account
                                      await accountListProvider.addAccount(context, _autocompleteText);
                                    } else {
                                      // Request access
                                      if (_messageController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageService.getTranslated(context, "sub_account_list_app_comment_empty_text_error"), style: CustomTypography.Body1,)));
                                        return;
                                      }
                                      await accountListProvider.requestAccess(context, _selectedSov?.accountId ?? "", _messageController.text);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    _sovAlreadyExists
                                        ? LanguageService.getTranslated(context, "sub_account_list_app_request_access_text")
                                        : LanguageService.getTranslated(context, "sub_account_list_app_submit_text"),
                                    style: CustomTypography.ButtonLarge,
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
                            style: CustomTypography.ButtonLarge,
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
      _sovAlreadyExists = false;
    });
  }



}
