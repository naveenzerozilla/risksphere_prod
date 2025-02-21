import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphare/constants/enums.dart';
import 'package:RiskSphare/design_system/components/custom_button.dart';
import 'package:RiskSphare/design_system/primitives/app_colors.dart';
import 'package:RiskSphare/design_system/primitives/utilities/custom_spacing.dart';
import 'package:RiskSphare/screens/listings/account_list.dart';
import 'package:RiskSphare/screens/listings/widgets/duplicates_tab.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';
import 'conflicts_tab.dart';
import 'location_headers.dart';
import '../../../providers/upload_sov_provider.dart';
import 'package:provider/provider.dart';

import 'message_card.dart';
import 'upload_preview_buttons.dart';

class LocationDataScreen extends StatefulWidget {
  final String tempId;
  final String processId;
  final String accountId;
  final String accountName;
  final String subAccountId;

  const LocationDataScreen({
    Key? key,
    required this.tempId,
    required this.processId,
    //required this.targetHeaders,
    this.accountId = '',
    this.accountName = '',
    this.subAccountId = '',
  }) : super(key: key);

  @override
  LocationDataScreenState createState() => LocationDataScreenState();
}

class LocationDataScreenState extends State<LocationDataScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _selectAll = false;
  bool _isLoading = false;
  bool _isCancelLoading = false;

  Map<String, dynamic> response = {};

  TabController? _masterTabController;
  int selectedMasterTab = 0;
  late ScrollController _scrollController;
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _masterTabController = TabController(length: 3, vsync: this);
    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
      if (selectedMasterTab == 0 && !_isLoading) {
        _getData();
      }
    });
    // Initial data fetch
  }

  @override
  void dispose() {
    _masterTabController?.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _getData() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    setState(() {
      _isLoading = true;
    });

    try {
      Provider.of<UploadSovProvider>(context, listen: false)
          .fetchLocations(context, widget.processId);
      Provider.of<UploadSovProvider>(context, listen: false)
          .fetchDuplicates(context, widget.processId);
      Provider.of<UploadSovProvider>(context, listen: false)
          .fetchConflicts(context, widget.processId);
    } catch (e) {
      print("Error fetching locations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching locations. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset the loading flag
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    setState(() {
      _selectAll = value ?? false;
      for (var location in provider.geocodingList) {
        location['isChecked'] = _selectAll;
      }
    });
  }

  void _toggleCheckbox(bool? value, int index) {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    setState(() {
      provider.geocodingList[index]['isChecked'] = value!;
      if (!value) {
        _selectAll = false;
      }
    });
  }

  /*void _showOptionsDialog() {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _selectedOption = 'Use SOV Data';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C1C1E), // Dark background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Column(
                children: [
                  Text(
                    'Just one more step before\nsubmitting the locations!',
                    style: typography.Body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      'Use Locations Data',
                      style: typography.Body1,
                    ),
                    subtitle: Text(
                      'Only missing data will be processed!',
                      style: typography.Caption,
                    ),
                    value: "Use SOV Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Refresh All Data',
                      style: typography.Body1,
                    ),
                    value: "Refresh All Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _commitSelectedLocations();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Commit Selected Locations',
                            style: typography.Body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _commitAllLocations();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Commit All Locations',
                            style: typography.Body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }*/

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    final isSubmitLoading =
        Provider.of<UploadSovProvider>(context).isSubmitLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_upload_preview"),
          style: typography.Body1.copyWith(fontWeight: FontWeight.w300),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                // Master TabBar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(0), // Rounded edges
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: DefaultTabController(
                    length: 4,
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
                              /*IconButton(
                                    icon: Icon(Icons.arrow_left,
                                        color: Colors.grey),
                                    onPressed: _scrollLeft,
                                  ),*/
                              // Scrollable TabBar
                              Consumer<UploadSovProvider>(
                                builder: (context, provider, child) {
                                  return Expanded(
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: TabBar(
                                        controller: _masterTabController,
                                        tabAlignment: TabAlignment.start,
                                        labelStyle: typography.Subtitle2,
                                        isScrollable: true,
                                        indicatorColor: AppColors.primaryMain,
                                        labelColor: AppColors.primaryMain,
                                        unselectedLabelColor: Colors.grey,
                                        tabs: [
                                          Tab(
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'Geocoding List ',
                                                style: typography.Subtitle2
                                                    .copyWith(
                                                        color: AppColors
                                                            .primaryMain),
                                                children: [
                                                  WidgetSpan(
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .middle,
                                                    // Aligns the widget properly in RichText
                                                    child:  Container(
                                                      width: 20,
                                                            alignment: Alignment.center,
                                                            // padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white38,
                                                              // Blinking background color
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10), // Rounded corners
                                                            ),
                                                            child: Text(
                                                              provider
                                                                  .geocodingList
                                                                  .length
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ), // Hides widget when count is 0
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Tab(
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'Duplicates ',
                                                style: typography.Subtitle2
                                                    .copyWith(
                                                        color: AppColors
                                                            .primaryMain),
                                                children: [
                                                  WidgetSpan(
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .middle,
                                                    // Aligns the widget properly in RichText
                                                    child: provider
                                                                .duplicateLocations
                                                                .length >
                                                            0
                                                        ? BlinkingText(
                                                            conflictCount: provider
                                                                .duplicateLocations
                                                                .length,
                                                            style: typography
                                                                    .Subtitle2
                                                                .copyWith(
                                                              color: Colors
                                                                  .white, // Default text color
                                                            ),
                                                            blinkColor:
                                                                Colors.white,
                                                            // Blinking text color
                                                            defaultColor: Colors
                                                                .red, // Default background color
                                                          )
                                                        : Container(
                                                            alignment: Alignment
                                                                .center,
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    3, 0, 4, 0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white38,
                                                              // Blinking background color
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10), // Rounded corners
                                                            ),
                                                            child: Text(
                                                              provider
                                                                  .duplicateLocations
                                                                  .length
                                                                  .toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ), // Hides widget when count is 0
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Tab(
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'Conflicts ',
                                                style: typography.Subtitle2
                                                    .copyWith(
                                                        color: AppColors
                                                            .primaryMain),
                                                children: [
                                                  TextSpan(
                                                    children: [
                                                      WidgetSpan(
                                                        alignment:
                                                            PlaceholderAlignment
                                                                .middle,
                                                        // Aligns the widget properly in RichText
                                                        child: provider
                                                                    .conflictLocations
                                                                    .length >
                                                                0
                                                            ? BlinkingText(
                                                                conflictCount:
                                                                    provider
                                                                        .conflictLocations
                                                                        .length,
                                                                style: typography
                                                                        .Subtitle2
                                                                    .copyWith(
                                                                  color: Colors
                                                                      .white, // Default text color
                                                                ),
                                                                blinkColor: Colors
                                                                    .orangeAccent,
                                                                // Blinking text color
                                                                defaultColor: Colors
                                                                    .red, // Default background color
                                                              )
                                                            : Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white38,
                                                                  // Blinking background color
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10), // Rounded corners
                                                                ),
                                                                child: Text(
                                                                  provider
                                                                      .conflictLocations
                                                                      .length
                                                                      .toString(),
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                      ),
                                                    ],
                                                  ),

                                                  // TextSpan(
                                                  //   text:
                                                  //       '${provider.conflictLocations.length}',
                                                  //   style: typography.Subtitle2.copyWith(
                                                  //       color: provider
                                                  //                   .conflictLocations
                                                  //                   .length >
                                                  //               0
                                                  //           ? Colors.red
                                                  //           : AppColors
                                                  //               .primaryMain), // Change length color
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              //old code
                              // Expanded(
                              //   child: SingleChildScrollView(
                              //     controller: _scrollController,
                              //     scrollDirection: Axis.horizontal,
                              //     child: TabBar(
                              //       controller: _masterTabController,
                              //       tabAlignment: TabAlignment.start,
                              //       labelStyle: typography.Subtitle2,
                              //       isScrollable: true,
                              //       indicatorColor: AppColors.primaryMain,
                              //       labelColor: AppColors.primaryMain,
                              //       unselectedLabelColor: Colors.grey,
                              //       tabs: [
                              //         Tab(
                              //           text: 'Geocoding List (0)',
                              //
                              //         ),
                              //         Tab(
                              //           text: 'Duplicates(0)',
                              //         ),
                              //         Tab(
                              //           text: 'Conflicts(0)',
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // Right arrow button
                              /* IconButton(
                                    icon: Icon(Icons.arrow_right,
                                        color: Colors.grey),
                                    onPressed: _scrollRight,
                                  ),*/
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Master TabBarView for the Tab Content
                Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: _masterTabController,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: CustomSpacing.four,
                          ),
                          StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('processes_status')
                                  .doc(widget.processId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox();
                                }
                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final duplicationCheckStatus =
                                    data['duplication_check_status']
                                        ?.toLowerCase();
                                print(
                                    "Duplication Check Status: $duplicationCheckStatus");

                                if (duplicationCheckStatus != "completed") {
                                  // Show animated loader if duplication check is not completed
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Add your animated loader here
                                        SizedBox(
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              0.1,
                                        ),
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 6,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "We're currently reviewing your addresses.\nJust hang tight for a few minutes, and we'll have it ready for you shortly!",
                                          textAlign: TextAlign.center,
                                          style: typography.Subtitle1,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Expanded(
                                    child: RefreshIndicator(
                                        onRefresh: _getData,
                                        child: _locationListBody(
                                            typography, context)));
                              }),
                        ],
                      ),
                      DuplicatesTab(
                        processId: widget.processId,
                        accountId: widget.accountId,
                        subAccountId: widget.subAccountId,
                        masterTabController: _masterTabController,
                        accountName: widget.accountName,
                        tempId: widget.tempId,
                      ),
                      ConflictsTab(
                        processId: widget.processId,
                        accountId: widget.accountId,
                        subAccountId: widget.subAccountId,
                        accountName: widget.accountName,
                        tempId: widget.tempId,
                        masterTabController: _masterTabController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSubmitLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Consumer<UploadSovProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _locationListBody(var typography, BuildContext context) {
    return PopScope(
      canPop: !_isCancelLoading,
      child: Consumer<UploadSovProvider>(builder: (context, provider, child) {
        return Column(
          children: [
            provider.geocodingList.isEmpty
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 60,
                      child: TextField(
                        controller: _textEditingController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _textEditingController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: "Search Locations",
                          hintStyle: typography.Body2,
                        ),
                      ),
                    ),
                  ),
            SizedBox(height: CustomSpacing.two),
            // Select all checkbox
            provider.geocodingList.isEmpty
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          value: _selectAll,
                          onChanged: _toggleSelectAll,
                        ),
                        Text(
                          "Select All",
                          style: typography.Body1,
                        ),
                      ],
                    ),
                  ),
            provider.geocodingList.isEmpty
                ? SizedBox.shrink()
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: MessageCard(
                          messageTextSpans: [
                            TextSpan(
                              text:
                                  "The locations you provided are not currently in our database. They will be processed, and this will incur nominal charges.",
                              style: typography.Body2.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        )),
                  ),
            provider.geocodingList.isEmpty
                ? SizedBox.shrink()
                : Column(
                    children: [
                      SizedBox(height: CustomSpacing.two),
                      Divider(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        thickness: 1,
                      ),
                    ],
                  ),
            SizedBox(height: CustomSpacing.two),
            provider.geocodingList.isEmpty
                ? Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              "There are no new locations provided.",
                              style: typography.Body1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16),
                          MessageCard(
                            messageTextSpans: [
                              TextSpan(
                                text: "Please review the list of ",
                                style: typography.Body2,
                              ),
                              TextSpan(
                                text: "duplicate",
                                style: typography.Body2.copyWith(
                                  color: AppColors.primaryMain,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _masterTabController?.animateTo(
                                        1); // Navigate to Geocode tab
                                  },
                              ),
                              TextSpan(
                                text: " locations and resolve any ",
                                style: typography.Body2,
                              ),
                              TextSpan(
                                text: "conflicts",
                                style: typography.Body2.copyWith(
                                  color: AppColors.primaryMain,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _masterTabController?.animateTo(
                                        2); // Navigate to Conflicts tab
                                  },
                              ),
                              TextSpan(
                                text: ".",
                                style: typography.Body2,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: provider.geocodingList.length,
                      itemBuilder: (context, index) {
                        final location = provider.geocodingList[index];
                        if (_searchQuery.isNotEmpty &&
                            !(location['formatted_address']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ||
                                location['city']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()))) {
                          return Container();
                        }

                        return Container(
                          margin:
                              EdgeInsets.only(bottom: 8, left: 16, right: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Checkbox(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  value: location['isChecked'],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      provider.geocodingList[index]
                                          ['isChecked'] = value!;
                                      if (!value) {
                                        _selectAll = false;
                                      }
                                    });
                                  },
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      Text(
                                        location['formatted_address'],
                                        style: typography.Body1,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "${location['city'] != null && location['city'].isNotEmpty ? location['city'] : ''}"
                                        "${location['state'] != null && location['state'].isNotEmpty ? (location['city'] != null && location['city'].isNotEmpty ? ', ' : '') + location['state'] : ''}"
                                        "${location['country'] != null && location['country'].isNotEmpty ? ((location['city'] != null && location['city'].isNotEmpty) || (location['state'] != null && location['state'].isNotEmpty) ? ', ' : '') + location['country'] : ''}",
                                        style: typography.Caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                  ),
                                  width: 50,
                                  height: double.infinity,
                                  child: IconButton(
                                    icon: Icon(Icons.info,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LocationHeadersScreen(
                                                  location: location),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            UploadPreviewButtons(
              accountId: widget.accountId,
              accountName: widget.accountName,
              tempId: widget.tempId,
              processId: widget.processId,
              subAccountId: widget.subAccountId,
            ),
          ],
        );
      }),
    );
  }
}

class BlinkingText extends StatefulWidget {
  final int conflictCount;
  final TextStyle style;
  final Color blinkColor;
  final Color defaultColor;

  const BlinkingText({
    Key? key,
    required this.conflictCount,
    required this.style,
    required this.blinkColor,
    required this.defaultColor,
  }) : super(key: key);

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _bgAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // Adjust speed of blinking
    )..repeat(reverse: true); // Reverses between colors

    _colorAnimation = ColorTween(
      begin: widget.blinkColor,
      end: widget.defaultColor,
    ).animate(_controller);

    _bgAnimation = ColorTween(
      begin: widget.defaultColor,
      end: widget.blinkColor,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _bgAnimation.value, // Blinking background color
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          child: Text(
            '${widget.conflictCount}',
            style: widget.style.copyWith(
              color: _colorAnimation.value, // Blinking text color
            ),
          ),
        );
      },
    );
  }
}
