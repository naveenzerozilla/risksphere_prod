import 'dart:async';
import 'dart:io';
import 'dart:math';

// import 'package:country_list_picker/country_list_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/components/custom_button.dart';
import 'package:RiskSphere/design_system/components/roles_dropdown.dart';
import 'package:RiskSphere/models/account_list_model.dart';
import 'package:RiskSphere/models/sov_list_model.dart';
import 'package:RiskSphere/providers/account_list_provider.dart';
import 'package:RiskSphere/providers/connections_provider.dart';
import 'package:RiskSphere/providers/sov_list_provider.dart';
import 'package:RiskSphere/providers/sub_account_list_provider.dart';
import 'package:RiskSphere/screens/listings/location_list.dart';
import 'package:RiskSphere/screens/listings/location_profile.dart';
import 'package:RiskSphere/screens/listings/widgets/export_dialog.dart';
import 'package:RiskSphere/screens/listings/widgets/mapping_screen.dart';
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
import 'package:RiskSphere/models/role_model.dart' as roleModel;

import '../../providers/upload_sov_provider.dart';
import '../../service/api_service.dart';
import '../../service/language_service.dart';
import '../../utils/api_constants.dart';
import 'add_location_screen.dart';
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

class _SovListScreenState extends State<SovListScreen> with TickerProviderStateMixin {
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

  String? _uploadedFileName;
  TextEditingController _sovNameController = TextEditingController();
  late File files;

  int _selectedAccountIndex = 0;

  String _sovQuery = "";
  bool _sovAlreadyExists = false;
  Accounts? _selectedSov;
  String _autocompleteText = "";

  Timer? autoCompleteDeBouncer;

  ScrollController _scrollController = ScrollController();

  void debounce(VoidCallback callback, {Duration duration = const Duration(seconds: 1)}) {
    if (deBouncer != null) {
      deBouncer!.cancel();
    }
    deBouncer = Timer(duration, callback);
  }

  void sovSearchClient(String query) async {
    debounce(() async {
      if (!mounted) return;
      _sovQuery = query;
      var provider = Provider.of<SOVListProvider>(context, listen: false);
      provider.page = 0;
      await provider.fetchSovList(context, widget.accountId, widget.subAccountId, _sovQuery, provider.page, 10);
    });
  }

  void autoCompleteDebounce(VoidCallback callback, {Duration duration = const Duration(seconds: 1)}) {
    if (autoCompleteDeBouncer != null) {
      autoCompleteDeBouncer!.cancel();
    }
    autoCompleteDeBouncer = Timer(duration, callback);
  }

  Future<void> autoCompleteAccountsSearchClient(String query) async {
    if (query.isEmpty) {
      return;
    }
    autoCompleteDebounce(() async {
      if (!mounted) return;
      var provider = Provider.of<SubAccountListProvider>(context, listen: false);
      await provider.fetchAutoCompleteSubAccountList(context, query, widget.accountId);

      // Force UI update after API call
      if (mounted) {
        setState(() {});
      }
    });
  }

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getData();
  }



  _getData() async {
    // Fetch data from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SOVListProvider>(context, listen: false).page = 0;
      Provider.of<SOVListProvider>(context, listen: false)
          .fetchSovList(context, widget.accountId, widget.subAccountId, "", 0, 10);
    });
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(builder: (buildContext, themeProvider, child) {
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
          floatingActionButton: Builder(builder: (contextLocal) {
            return SpeedDial(
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
                  label: 'Import Locations',
                  onTap:
                    () async {
                      setState(() {
                        _uploadedFileName = null;
                        _sovNameController.clear();
                      });
                      _showUploadDialog(widget.accountId, widget.subAccountId);
                    },

                ),
                SpeedDialChild(
                  child: Icon(CupertinoIcons.tray_arrow_down),
                  label: 'Export',
                  onTap: () {
                    // On export button click
                    List<String> selectedSovIds = Provider.of<SOVListProvider>(context, listen: false)
                        .sovList
                        .where((sov) => sov.isChecked ?? false)
                        .map((sov) => sov.id!)
                        .toList();

                    if (selectedSovIds.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ExportDialog(
                            accountId: widget.accountId,
                            subAccountId: widget.subAccountId,
                            locationId: selectedSovIds,
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          LanguageService.getTranslated(context, "no_items_selected_error"),
                          style: typography.Body1,
                        ),
                      ));
                    }
                  },
                ),
              ],
            );
          }),
          body: PopScope(
            canPop: true,
            onPopInvoked: (canPop) {},
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                            text: 'SOVs',
                                          ),
                                          Tab(text: 'Shared'),
                                          Tab(text: 'Access Requests'),
                                        ],
                                      ),
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
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: sovBody(typography),
                            ),
                          ),
                          _getComingSoonUI(),
                          _getComingSoonUI(),
                        ],
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

  Widget sovBody(CustomTypography typography) {
    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: CustomSpacing.two),
                          Text(
                            '${LanguageService.getTranslated(context, "sov_list_app_title")} ',
                            style: typography.Body1,
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
                                hintStyle: typography.Body2,
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          SizedBox(height: CustomSpacing.four),
                          // List of sovs
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
                                      "Looks like you don't have a sov yet. No worries! Just create a new one and start adding your locations.",
                                      style: typography.Body1,
                                    ),
                                  )
                                      : ListView.builder(
                                    itemCount: sovListProvider
                                        .sovList.length,
                                    itemBuilder: (context, index) {
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
                                            sovListProvider
                                                .totalPages &&
                                            sovListProvider
                                                .sovList.isNotEmpty) {
                                          // Display end of list message
                                          return Column(
                                            children: [
                                              _buildSovCard(
                                                  index,
                                                  sovListProvider),
                                              Padding(
                                                padding:
                                                const EdgeInsets.all(
                                                    8.0),
                                                child: Center(
                                                  child: Text(
                                                    LanguageService.getTranslated(
                                                        context,
                                                        "sov_list_app_end_of_list_text"),
                                                    style:
                                                    typography
                                                        .Body1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          // Trigger fetching the next page
                                          sovListProvider.page =
                                              sovListProvider.page + 1;
                                          sovListProvider.fetchSovList(
                                            context,
                                            widget.accountId,
                                            widget.subAccountId,
                                            _sovQuery,
                                            sovListProvider.page,
                                            10, // Page size
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

  Widget _buildSovCard(int index, SOVListProvider sOVListProvider) {
    var typography = CustomTypography(context);
    bool isDisabled = sOVListProvider.sovList[index].disabled ?? false;
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isDisabled
            ? null
            : () {
          // On tap of card
          if (showCheckbox) {
            setState(() {
              sOVListProvider.sovList[index].isChecked =
              !(sOVListProvider.sovList[index].isChecked ?? false);
            });
          }
          // if all are unselected then hide checkbox
          if (sOVListProvider.sovList
              .every((element) => element.isChecked == false)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                showCheckbox = false;
              });
            });
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return LocationList(
              userId: sOVListProvider.sovList[index].accountId ?? "",
              companyName: widget.accountName,
              accountId: widget.accountId,
              accountName: widget.accountName,
              subAccountId: widget.subAccountId,
              sovId: sOVListProvider.sovList[index].id ?? "",
              sovName: sOVListProvider.sovList[index].name ?? "",
              subAccountName: widget.subAccountName,
              rating: sOVListProvider.sovList[index].overAllScore?.toString() ??
                  "0",
            );
          }));
        },
        onLongPress: () {
          setState(() {
            if (showCheckbox) {
              showCheckbox = false;
              sOVListProvider.sovList[index].isChecked = false;
            } else {
              sOVListProvider.sovList.forEach((element) {
                element.isChecked = false;
              });
              showCheckbox = true;
              sOVListProvider.sovList[index].isChecked = true;
            }
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Checkbox here
            showCheckbox?
            Checkbox(
              value: sOVListProvider.sovList[index].isChecked ?? false,
              onChanged: isDisabled?null:(value) {
                setState(() {
                  sOVListProvider.sovList[index].isChecked = value??false;
                });
              },
            ):SizedBox(),
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
                                          /*(sOVListProvider.sovList[index].name ??
                                              "")
                                              .isNotEmpty
                                              ? sOVListProvider.sovList[index]
                                              .name!
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              sOVListProvider.sovList[index]
                                                  .name!
                                                  .substring(1)
                                              : ""*/sOVListProvider.sovList[index].id??"",
                                          style:
                                          typography.Body2.copyWith(
                                            color: Theme.of(context)
                                                .brightness ==
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
                                          _sovEditNameController.text =
                                          (sOVListProvider
                                              .sovList[index]
                                              .name ??
                                              "")
                                              .isNotEmpty
                                              ? sOVListProvider
                                              .sovList[index]
                                              .name!
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              sOVListProvider
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
                                                  style:
                                                  typography.H5_Regular,
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Chip(
                                                          label: Text(
                                                            widget.accountName +
                                                                " / " +
                                                                widget
                                                                    .subAccountName,
                                                            style:
                                                            typography
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
                                                            typography
                                                                .Body1,
                                                            hintText:
                                                            LanguageService
                                                                .getTranslated(
                                                                context,
                                                                "sov_list_app_edit_label_hint_text"),
                                                            hintStyle:
                                                            typography
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
                                                              style:
                                                              typography
                                                                  .ButtonLarge,
                                                            ),
                                                            type: ButtonType.text,
                                                          ),
                                                        ),
                                                        Consumer<SOVListProvider>(
                                                            builder: (context,
                                                                sovListProvider,
                                                                _) {
                                                              return sovListProvider
                                                                  .isRenameLoading
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
                                                                  ))
                                                                  : Expanded(
                                                                child:
                                                                CustomButton(
                                                                  onPressed:
                                                                      () async {
                                                                    if (_sovEditNameController
                                                                        .text
                                                                        .isEmpty) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                          content: Text(
                                                                            LanguageService.getTranslated(context, "sub_account_list_app_rename_sub_account_empty_text_error"),
                                                                            style: typography.Body1,
                                                                          )));
                                                                      return;
                                                                    }
                                                                    // Update account details
                                                                    await sovListProvider.renameSov(
                                                                        context,
                                                                        widget
                                                                            .accountId,
                                                                        widget
                                                                            .subAccountId,
                                                                        sovListProvider
                                                                            .sovList[
                                                                        index]
                                                                            .id ??
                                                                            "",
                                                                        _sovEditNameController
                                                                            .text);
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    LanguageService.getTranslated(
                                                                        context,
                                                                        "sov_list_app_edit_update_text"),
                                                                    style: typography
                                                                        .ButtonLarge,
                                                                  ),
                                                                  type: ButtonType
                                                                      .elevated,
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
                                  !sOVListProvider.showLocationCount
                                      ? SizedBox()
                                      : Row(
                                    children: [
                                      Text(
                                          sOVListProvider
                                              .sovList[index]
                                              .locationCount !=
                                              null &&
                                              sOVListProvider
                                                  .sovList[index]
                                                  .locationCount ==
                                                  1
                                              ? LanguageService.getTranslated(
                                              context,
                                              "sov_list_app_column_location_count_text")
                                              : sOVListProvider
                                              .sovList[index]
                                              .locationCount ==
                                              null
                                              ? ""
                                              : LanguageService
                                              .getTranslated(
                                              context,
                                              "sov_list_app_column_location_count_text"),
                                          style: typography.Caption),
                                      SizedBox(
                                        width: CustomSpacing.two,
                                      ),
                                      Text(
                                          sOVListProvider.sovList[index]
                                              .locationCount
                                              ?.toString() ??
                                              "",
                                          style: typography.Caption),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            !sOVListProvider.showOverallScore
                                ? SizedBox()
                                : Padding(
                              padding:
                              EdgeInsets.only(top: CustomSpacing.one),
                              child: CustomGradientCircularProgressBar(
                                radius: 23,
                                value: double.parse(
                                  (sOVListProvider.sovList[index].overAllScore ?? 0).toStringAsFixed(3),
                                ),
                                strokeWidth: 6,
                                showText: true,
                                textColor: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                                text: (sOVListProvider.sovList[index].overAllScore ?? 0).toStringAsFixed(2),
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
                        TextButton.icon(
                          onPressed: () {
                            // Transfer account
                            _showTransferDialog(context,
                                sOVListProvider.sovList[index]);
                          },
                          icon: const Icon(Symbols.share_windows),
                          label: Text('Transfer',
                              style: typography.Caption.copyWith(
                                  color: Theme.of(context).brightness ==
                                      Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black)),
                        ),
                        const Spacer(),
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
                                        "sov_list_app_duplicate_title"),
                                    style: typography.H5_Regular,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LanguageService.getTranslated(
                                            context,
                                            "sov_list_app_duplicate_text"),
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
                                                    "sov_list_app_duplicate_cancel"),
                                                style:
                                                typography.ButtonLarge,
                                              ),
                                              type: ButtonType.text,
                                            ),
                                          ),
                                          sOVListProvider.isDuplicateLoading
                                              ? const Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                      width: 25,
                                                      height: 25,
                                                      child:
                                                      CircularProgressIndicator()),
                                                ],
                                              ))
                                              : Expanded(
                                            child: CustomButton(
                                              onPressed: () async {
                                                // Duplicate
                                                await sOVListProvider
                                                    .duplicateSov(
                                                    context,
                                                    widget.accountId,
                                                    widget.subAccountId,
                                                    sOVListProvider
                                                        .sovList[index]
                                                        .id??"");
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                LanguageService.getTranslated(
                                                    context,
                                                    "sov_list_app_duplicate_duplicate"),
                                                style: typography
                                                    .ButtonLarge,
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
            return Consumer<SOVListProvider>(
                builder: (context, sovListProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: sovListProvider.showLocationCountLoading
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
                          value: sovListProvider.showLocationCount,
                          onChanged: (value) async {
                            bool result = await sovListProvider
                                .changeColumnVisibility(
                                context,
                                widget.accountId,
                                widget.subAccountId,
                                showLocationCount: value ?? false,
                                showOverallScore:
                                sovListProvider.showOverallScore,
                                type: 'location_count');

                            if (result) {
                              setModalState(() {
                                sovListProvider.showLocationCount =
                                    value ?? false;
                              });
                              setState(() {
                                sovListProvider.showLocationCount =
                                    value ?? false;
                              });
                              // Update account list
                              sovListProvider.fetchSovList(
                                  context,
                                  widget.accountId,
                                  widget.subAccountId,
                                  _sovQuery,
                                  sovListProvider.page,
                                  10);
                            }
                          },
                        ),
                        title: Text(
                            LanguageService.getTranslated(context,
                                "sov_list_app_column_location_count_text"),
                            style: typography.Body1),
                      ),
                      ListTile(
                        leading: sovListProvider.showOverallScoreLoading
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
                          value: sovListProvider.showOverallScore,
                          onChanged: (value) async {
                            bool result =
                            await sovListProvider.changeColumnVisibility(
                                context,
                                widget.accountId,
                                widget.subAccountId,
                                showLocationCount:
                                sovListProvider.showLocationCount,
                                showOverallScore: value ?? false,
                                type: 'over_all_score');
                            if (result) {
                              setModalState(() {
                                sovListProvider.showOverallScore =
                                    value ?? false;
                              });
                              setState(() {
                                sovListProvider.showOverallScore =
                                    value ?? false;
                              });
                              // Update account list
                              sovListProvider.fetchSovList(
                                  context,
                                  widget.accountId,
                                  widget.subAccountId,
                                  _sovQuery,
                                  sovListProvider.page,
                                  10);
                            }
                          },
                        ),
                        title: Text(
                            LanguageService.getTranslated(context,
                                "sov_list_app_column_overall_score_text"),
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

  Future<void> _showTransferDialog(BuildContext context, SovAccount sov) async {
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
                        'Transfer SOV',
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
                          hintText: 'Search for a user to transfer sov',
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
                              child: Text(user.displayName[0].toUpperCase()),
                            ),
                            title: Text(user.displayName),
                            subtitle: Text(user.email),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _userSearchController.text = user.displayName;
                              });
                            },
                          );
                        },
                      )
                          : Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Selected User: ${_selectedUser!.displayName}'),
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
                            var provider = Provider.of<SOVListProvider>(context, listen: false);
                            await provider.transferSOV(context, widget.accountId, widget.subAccountId, sov.id, _selectedUser!.id);
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
      ApiService apiService = ApiService(AppConstant.ADD_TEAM_MEMBERS);
      String url = '?search=$query&within_company=true';
      var response = await apiService.get(url);

      // Parse the response to extract user data
      List<TransferAutocompleteModel> users = (response['users'] as List)
          .map((user) => TransferAutocompleteModel.fromJson(user))
          .toList();

      return users;
    } catch (e) {
      print(e.toString());
      return [];
    }
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
}
