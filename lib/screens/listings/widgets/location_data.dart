import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphare/design_system/primitives/app_colors.dart';
import 'package:RiskSphare/design_system/primitives/utilities/custom_spacing.dart';
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
  final String? subAccountName;
  final String subAccountId;

  const LocationDataScreen({
    Key? key,
    required this.tempId,
    required this.processId,
    //required this.targetHeaders,
    this.accountId = '',
    this.accountName = '',
    this.subAccountName,
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
  List<Map<String, dynamic>> selectedLocations = [];
  String processStatus = '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _listenToProcessStatus();
    _scrollController = ScrollController();
    _masterTabController = TabController(length: 3, vsync: this);

    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
      if (selectedMasterTab == 0 && !_isLoading) {
        // _listenToProcessStatus();
      }
    });
    _listenToProcessStatus();
    // Initial data fetch
  }

  void _listenToProcessStatus() {
    final query = _db
        .collection('processes')
        .where('process_id', isEqualTo: widget.processId);

    query.snapshots().listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          processStatus = data['duplication_check_status'] ?? '';
        });
        print(processStatus);
        print("processStatus");
        _getData();
      }
    });
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

  Future<void> _getDataInital() async {
    response = await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchDuplicates(context, widget.processId);
  }

  Future<void> _getData() async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() => _isLoading = true);

    try {
      final uploadSovProvider =
          Provider.of<UploadSovProvider>(context, listen: false);

      // Call APIs in parallel
      await Future.wait([
        uploadSovProvider.fetchLocations(context, widget.processId),
        uploadSovProvider.fetchDuplicates(context, widget.processId),
        uploadSovProvider.fetchConflicts(context, widget.processId),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getLocationData() async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() => _isLoading = true);

    try {
      final uploadSovProvider =
          Provider.of<UploadSovProvider>(context, listen: false);

      // Step 1: Store IDs of selected locations before refresh
      List<String> selectedIds = uploadSovProvider.geocodingList
          .where((location) => location['isChecked'] == true)
          .map(
              (location) => location['id'].toString()) // Ensure IDs are strings
          .toList();

      // Call APIs in parallel
      await Future.wait([
        uploadSovProvider.fetchLocations(context, widget.processId),
      ]);

      // Step 2: Restore the selected state after refreshing
      for (var location in uploadSovProvider.geocodingList) {
        if (selectedIds.contains(location['id'].toString())) {
          location['isChecked'] = true;
        }
      }

      // Step 3: Check if all items are selected and update `_selectAll`
      _selectAll = uploadSovProvider.geocodingList.isNotEmpty &&
          uploadSovProvider.geocodingList
              .every((location) => location['isChecked'] == true);
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  //
  // Future<void> _getData() async {
  //   if (_isLoading) return; // Prevent multiple simultaneous calls
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     Provider.of<UploadSovProvider>(context, listen: false)
  //         .fetchLocations(context, widget.processId);
  //     Provider.of<UploadSovProvider>(context, listen: false)
  //         .fetchDuplicates(context, widget.processId);
  //     Provider.of<UploadSovProvider>(context, listen: false)
  //         .fetchConflicts(context, widget.processId);
  //   } catch (e) {
  //     print("Error fetching locations: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error fetching locations. Please try again.")),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoading = false; // Reset the loading flag
  //     });
  //   }
  // }

  // void _toggleSelectAll(bool? value) {
  //     var provider = Provider.of<UploadSovProvider>(context, listen: false);
  //   setState(() {
  //     _selectAll = value ?? false;
  //
  //     // Update all checkboxes in the list
  //     for (var location in provider.geocodingList) {
  //       location['isChecked'] = _selectAll;
  //     }
  //
  //     // Update the selectedLocations list
  //     if (_selectAll) {
  //       selectedLocations = List.from(provider.geocodingList);
  //     } else {
  //       selectedLocations.clear();
  //     }
  //   });
  // }
  void _toggleSelectAll(bool? value) {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    setState(() {
      _selectAll = value ?? false;

      // Update all checkboxes in the list
      for (var location in provider.geocodingList) {
        location['isChecked'] = _selectAll;
      }

      // Update the selectedLocations list and its count
      selectedLocations = _selectAll ? List.from(provider.geocodingList) : [];
    });
  }

  // void _toggleSelectAll(bool? value) {
  //   var provider = Provider.of<UploadSovProvider>(context, listen: false);
  //   setState(() {
  //     _selectAll = value ?? false;
  //     for (var location in provider.geocodingList) {
  //       location['isChecked'] = _selectAll;
  //     }
  //     selectedLocations.length;
  //   });
  // }

  void _toggleCheckbox(bool? value, int index) {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    setState(() {
      provider.geocodingList[index]['isChecked'] = value!;
      if (!value) {
        _selectAll = false;
      }
    });
  }

  int _currentIndex = 0;

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
                              // Scrollable TabBa
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
                                        onTap: (index) {
                                          setState(() {
                                            _currentIndex = index;
                                          });
                                          print(_currentIndex);
                                        },
                                        tabs: [
                                          Tab(
                                            child: processStatus != "completed"
                                                ? RichText(
                                                    text: TextSpan(
                                                      text: 'Geocoding List ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color:
                                                            _currentIndex == 0
                                                                ? AppColors
                                                                    .primaryMain
                                                                : Colors.grey,
                                                      ),
                                                      children: [
                                                        WidgetSpan(
                                                          alignment:
                                                              PlaceholderAlignment
                                                                  .middle,
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                6,
                                                                vertical:
                                                                0),
                                                            decoration:
                                                            BoxDecoration(
                                                              color: Colors
                                                                  .white12,
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                  10),
                                                            ),
                                                            child:
                                                                FutureBuilder(
                                                              future: provider
                                                                      .isInitialLoad
                                                                  ? Future
                                                                      .delayed(
                                                                      Duration(
                                                                          seconds:
                                                                              2),
                                                                      () => provider
                                                                          .geocodingList
                                                                          .length,
                                                                    )
                                                                  : Future
                                                                      .value(0),
                                                              builder: (context,
                                                                  snapshot) {
                                                                return Text(
                                                                  "0",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : RichText(
                                                    text: TextSpan(
                                                      text: 'Geocoding List ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color: _currentIndex ==
                                                                0
                                                            ? AppColors
                                                                .primaryMain
                                                            : Colors.white60,
                                                      ),
                                                      children: [
                                                        WidgetSpan(
                                                          alignment:
                                                              PlaceholderAlignment
                                                                  .middle,
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white12,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child:
                                                                FutureBuilder<
                                                                    int>(
                                                              future: provider
                                                                      .isInitialLoad
                                                                  ? Future.delayed(
                                                                      Duration(
                                                                          seconds:
                                                                              2),
                                                                      () => provider
                                                                          .geocodingList
                                                                          .length)
                                                                  : Future.value(
                                                                      provider
                                                                          .geocodingList
                                                                          .length),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting) {
                                                                  return SizedBox(
                                                                    width: 15,
                                                                    height: 15,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      valueColor: AlwaysStoppedAnimation<
                                                                              Color>(
                                                                          Colors
                                                                              .white),
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return Padding(
                                                                    padding: EdgeInsets.only(
                                                                        bottom:
                                                                            2),
                                                                    child: Text(
                                                                      snapshot.data
                                                                              ?.toString() ??
                                                                          "0",
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                          Tab(
                                            child: processStatus != "completed"
                                                ? RichText(
                                                    text: TextSpan(
                                                      text: 'Duplicates ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color: _currentIndex ==
                                                                1
                                                            ? AppColors
                                                                .primaryMain
                                                            : Colors.white60,
                                                      ),
                                                      children: [
                                                        WidgetSpan(
                                                          alignment:
                                                              PlaceholderAlignment
                                                                  .middle,
                                                          child: provider
                                                                      .duplicateLocations
                                                                      .length >
                                                                  0
                                                              ? BlinkingText1(
                                                                  conflictCount:
                                                                      0,
                                                                  style: typography
                                                                          .Subtitle2
                                                                      .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  blinkColor:
                                                                      Colors
                                                                          .white,
                                                                  defaultColor:
                                                                      Colors
                                                                          .red,
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
                                                                    .white12,
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                  10),
                                                            ),
                                                                  // alignment:
                                                                  //     Alignment
                                                                  //         .center,
                                                                  // padding: EdgeInsets
                                                                  //     .fromLTRB(
                                                                  //         3,
                                                                  //         0,
                                                                  //         4,
                                                                  //         0),
                                                                  // decoration:
                                                                  //     BoxDecoration(
                                                                  //   color: Colors
                                                                  //       .white12,
                                                                  //   borderRadius:
                                                                  //       BorderRadius.circular(
                                                                  //           10),
                                                                  // ),
                                                                  child: Text(
                                                                    "0",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : RichText(
                                                    text: TextSpan(
                                                      text: 'Duplicates ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color: _currentIndex ==
                                                                1
                                                            ? AppColors
                                                                .primaryMain
                                                            : Colors.white60,
                                                      ),
                                                      children: [
                                                        if (processStatus ==
                                                            "completed")
                                                          WidgetSpan(
                                                            alignment:
                                                                PlaceholderAlignment
                                                                    .middle,
                                                            child: provider
                                                                        .duplicateLocations
                                                                        .length >
                                                                    0
                                                                ?

                                                            BlinkingText1(
                                                                    conflictCount:
                                                                        provider
                                                                            .duplicateLocations
                                                                            .length,
                                                                    style: typography
                                                                            .Subtitle2
                                                                        .copyWith(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    blinkColor:
                                                                        Colors
                                                                            .white,
                                                                    defaultColor:
                                                                        Colors
                                                                            .red,
                                                                  )
                                                                :  Container(
                                                              // padding: EdgeInsets
                                                              //     .symmetric(
                                                              //     horizontal:
                                                              //     6,
                                                              //     vertical:
                                                              //     0),
                                                              // decoration:
                                                              // BoxDecoration(
                                                              //   color: Colors
                                                              //       .white12,
                                                              //   borderRadius:
                                                              //   BorderRadius
                                                              //       .circular(
                                                              //       10),
                                                              // ),
                                                                    child:
                                                                        FutureBuilder(
                                                                      future: provider
                                                                              .isInitialLoad
                                                                          ? Future
                                                                              .delayed(
                                                                              Duration(seconds: 2),
                                                                              () => provider.duplicateLocations.length,
                                                                            )
                                                                          : Future.value(provider
                                                                              .duplicateLocations
                                                                              .length),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        return Text(
                                                                          snapshot.connectionState == ConnectionState.waiting
                                                                              ? "0"
                                                                              : snapshot.data.toString(),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                          Tab(
                                            child: processStatus != "completed"
                                                ? RichText(
                                                    text: TextSpan(
                                                      text: 'Conflicts ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color: _currentIndex ==
                                                                2
                                                            ? AppColors
                                                                .primaryMain
                                                            : Colors.white60,
                                                      ),
                                                      children: [
                                                        WidgetSpan(
                                                          alignment:
                                                              PlaceholderAlignment
                                                                  .middle,
                                                          child: provider
                                                                      .conflictLocations
                                                                      .length >
                                                                  0
                                                              ? BlinkingText(
                                                                  conflictCount:
                                                                      0,
                                                                  style: typography
                                                                          .Subtitle2
                                                                      .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  blinkColor: Colors
                                                                      .orangeAccent,
                                                                  defaultColor:
                                                                      Colors
                                                                          .red,
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
                                                                        .white12,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                  ),
                                                                  child:
                                                                      FutureBuilder(
                                                                    future: provider
                                                                            .isInitialLoad
                                                                        ? Future
                                                                            .delayed(
                                                                            Duration(seconds: 2),
                                                                            () =>
                                                                                provider.conflictLocations.length,
                                                                          )
                                                                        : Future
                                                                            .value(0),
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      return Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            bottom:
                                                                                2.0),
                                                                        child:
                                                                            Text(
                                                                          "0",
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : RichText(
                                                    text: TextSpan(
                                                      text: 'Conflicts ',
                                                      style: typography
                                                          .Subtitle2.copyWith(
                                                        color: _currentIndex ==
                                                                2
                                                            ? AppColors
                                                                .primaryMain
                                                            : Colors.white60,
                                                      ),
                                                      children: [
                                                        if (processStatus ==
                                                            "completed")
                                                          WidgetSpan(
                                                            alignment:
                                                                PlaceholderAlignment
                                                                    .middle,
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
                                                                          .white,
                                                                    ),
                                                                    blinkColor:
                                                                        Colors
                                                                            .orangeAccent,
                                                                    defaultColor:
                                                                        Colors
                                                                            .red,
                                                                  )
                                                                : Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .white12,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                                    child:
                                                                        FutureBuilder(
                                                                      future: provider
                                                                              .isInitialLoad
                                                                          ? Future
                                                                              .delayed(
                                                                              Duration(seconds: 1),
                                                                              () => provider.conflictLocations.length,
                                                                            )
                                                                          : Future.value(provider
                                                                              .conflictLocations
                                                                              .length),
                                                                      builder:
                                                                          (context,
                                                                              snapshot) {
                                                                        return Container(
                                                                          padding:
                                                                              EdgeInsets.only(bottom: 2),
                                                                          child:
                                                                              Text(
                                                                            snapshot.connectionState == ConnectionState.waiting
                                                                                ? "0"
                                                                                : snapshot.data.toString(),
                                                                            style:
                                                                                TextStyle(color: Colors.white),
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                          ),
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

                              // Consumer<UploadSovProvider>(
                              //   builder: (context, provider, child) {
                              //     return
                              //         // provider.isLoading ? Center(child: CircularProgressIndicator(),):
                              //         Expanded(
                              //       child: SingleChildScrollView(
                              //         controller: _scrollController,
                              //         scrollDirection: Axis.horizontal,
                              //         child: TabBar(
                              //           controller: _masterTabController,
                              //           tabAlignment: TabAlignment.start,
                              //           labelStyle: typography.Subtitle2,
                              //           isScrollable: true,
                              //           indicatorColor: AppColors.primaryMain,
                              //           labelColor: AppColors.primaryMain,
                              //           unselectedLabelColor: Colors.grey,
                              //           tabs: [
                              //             Tab(
                              //               child: RichText(
                              //                 text: TextSpan(
                              //                   text: 'Geocoding List ',
                              //                   style: typography.Subtitle2
                              //                       .copyWith(
                              //                     color: AppColors.primaryMain,
                              //                   ),
                              //                   children: [
                              //                     WidgetSpan(
                              //                       alignment:
                              //                           PlaceholderAlignment
                              //                               .middle,
                              //                       child: Container(
                              //                           width: 25,
                              //                           alignment:
                              //                               Alignment.center,
                              //                           decoration:
                              //                               BoxDecoration(
                              //                             color: Colors.white38,
                              //                             // Background color
                              //                             borderRadius:
                              //                                 BorderRadius.circular(
                              //                                     10), // Rounded corners
                              //                           ),
                              //                           child: FutureBuilder(
                              //                             future: Future.delayed(
                              //                                 Duration(
                              //                                     seconds: 2),
                              //                                 () => provider
                              //                                     .geocodingList
                              //                                     .length),
                              //                             builder: (context,
                              //                                 snapshot) {
                              //                               return Text(
                              //                                 snapshot.connectionState ==
                              //                                         ConnectionState
                              //                                             .waiting
                              //                                     ? "0"
                              //                                     : snapshot
                              //                                         .data
                              //                                         .toString(),
                              //                                 style: TextStyle(
                              //                                     color: Colors
                              //                                         .white),
                              //                               );
                              //                             },
                              //                           )),
                              //                     ),
                              //                   ],
                              //                 ),
                              //               ),
                              //             ),
                              //             Tab(
                              //               child: RichText(
                              //                 text: TextSpan(
                              //                   text: 'Duplicates ',
                              //                   style: typography.Subtitle2
                              //                       .copyWith(
                              //                     color: AppColors.primaryMain,
                              //                   ),
                              //                   children: [
                              //                     WidgetSpan(
                              //                       alignment:
                              //                           PlaceholderAlignment
                              //                               .middle,
                              //                       child: provider
                              //                                   .duplicateLocations
                              //                                   .length >
                              //                               0
                              //                           ? BlinkingText(
                              //                               conflictCount: provider
                              //                                   .duplicateLocations
                              //                                   .length,
                              //                               style: typography
                              //                                       .Subtitle2
                              //                                   .copyWith(
                              //                                 color: Colors
                              //                                     .white, // Default text color
                              //                               ),
                              //                               blinkColor:
                              //                                   Colors.white,
                              //                               defaultColor:
                              //                                   Colors.red,
                              //                             )
                              //                           : Container(
                              //                               alignment: Alignment
                              //                                   .center,
                              //                               padding: EdgeInsets
                              //                                   .fromLTRB(
                              //                                       3, 0, 4, 0),
                              //                               decoration:
                              //                                   BoxDecoration(
                              //                                 color: Colors
                              //                                     .white38,
                              //                                 borderRadius:
                              //                                     BorderRadius
                              //                                         .circular(
                              //                                             10),
                              //                               ),
                              //                               child:
                              //                                   FutureBuilder(
                              //                                 future: Future.delayed(
                              //                                     Duration(
                              //                                         seconds:
                              //                                             4),
                              //                                     () => provider
                              //                                         .duplicateLocations
                              //                                         .length),
                              //                                 builder: (context,
                              //                                     snapshot) {
                              //                                   return Text(
                              //                                     snapshot.connectionState ==
                              //                                             ConnectionState
                              //                                                 .waiting
                              //                                         ? "0"
                              //                                         : snapshot
                              //                                             .data
                              //                                             .toString(),
                              //                                     textAlign:
                              //                                         TextAlign
                              //                                             .center,
                              //                                     style: TextStyle(
                              //                                         color: Colors
                              //                                             .white),
                              //                                   );
                              //                                 },
                              //                               ),
                              //                             ),
                              //                     ),
                              //                   ],
                              //                 ),
                              //               ),
                              //             ),
                              //             Tab(
                              //               child: RichText(
                              //                 text: TextSpan(
                              //                   text: 'Conflicts ',
                              //                   style: typography.Subtitle2
                              //                       .copyWith(
                              //                     color: AppColors.primaryMain,
                              //                   ),
                              //                   children: [
                              //                     WidgetSpan(
                              //                       alignment:
                              //                           PlaceholderAlignment
                              //                               .middle,
                              //                       child: provider
                              //                                   .conflictLocations
                              //                                   .length >
                              //                               0
                              //                           ? BlinkingText(
                              //                               conflictCount: provider
                              //                                   .conflictLocations
                              //                                   .length,
                              //                               style: typography
                              //                                       .Subtitle2
                              //                                   .copyWith(
                              //                                 color:
                              //                                     Colors.white,
                              //                               ),
                              //                               blinkColor: Colors
                              //                                   .orangeAccent,
                              //                               defaultColor:
                              //                                   Colors.red,
                              //                             )
                              //                           : Container(
                              //                               padding: EdgeInsets
                              //                                   .symmetric(
                              //                                       horizontal:
                              //                                           6,
                              //                                       vertical:
                              //                                           0),
                              //                               decoration:
                              //                                   BoxDecoration(
                              //                                 color: Colors
                              //                                     .white38,
                              //                                 borderRadius:
                              //                                     BorderRadius
                              //                                         .circular(
                              //                                             10),
                              //                               ),
                              //                               child:
                              //                                   FutureBuilder(
                              //                                 future: Future.delayed(
                              //                                     Duration(
                              //                                         seconds:
                              //                                             4),
                              //                                     () => provider
                              //                                         .conflictLocations
                              //                                         .length),
                              //                                 builder: (context,
                              //                                     snapshot) {
                              //                                   return Text(
                              //                                     snapshot.connectionState ==
                              //                                             ConnectionState
                              //                                                 .waiting
                              //                                         ? "0"
                              //                                         : snapshot
                              //                                             .data
                              //                                             .toString(),
                              //                                     style: TextStyle(
                              //                                         color: Colors
                              //                                             .white),
                              //                                   );
                              //                                 },
                              //                               ),
                              //                             ),
                              //                     ),
                              //                   ],
                              //                 ),
                              //               ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // ),
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
                                    child:
                                        _locationListBody(typography, context));
                              }),
                        ],
                      ),
                      DuplicatesTab(
                        subAccountName: widget.subAccountName,
                        processId: widget.processId,
                        accountId: widget.accountId,
                        subAccountId: widget.subAccountId,
                        masterTabController: _masterTabController,
                        accountName: widget.accountName,
                        tempId: widget.tempId,
                      ),
                      ConflictsTab(
                        subAccountName: widget.subAccountName,
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
          // if (isSubmitLoading)
          //   Container(
          //     color: Colors.black54,
          //     child: Center(
          //       child: CircularProgressIndicator(),
          //     ),
          //   ),
          // Consumer<UploadSovProvider>(
          //   builder: (context, provider, child) {
          //     if (provider.isLoading) {
          //       return Container(
          //         color: Colors.black54,
          //         child: Center(
          //           child: CircularProgressIndicator(),
          //         ),
          //       );
          //     } else {
          //       return const SizedBox.shrink();
          //     }
          //   },
          // ),
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
                                StatefulBuilder(
                                  builder: (context, setStateLocal) {
                                    return Checkbox(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      value: location['isChecked'] ?? false,
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          setStateLocal(() {
                                            location['isChecked'] = value;
                                          });

                                          if (value) {
                                            selectedLocations.add(location);
                                          } else {
                                            selectedLocations.removeWhere(
                                                (item) =>
                                                    item['id'] ==
                                                    location['id']);
                                          }

                                          // Check if all items are selected
                                          _selectAll = provider.geocodingList
                                              .every((item) =>
                                                  item['isChecked'] == true);
                                        }
                                      },
                                    );
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

                    // ListView.builder(
                    //   itemCount: provider.geocodingList.length,
                    //   itemBuilder: (context, index) {
                    //     final location = provider.geocodingList[index];
                    //
                    //     if (_searchQuery.isNotEmpty &&
                    //         !(location['formatted_address']
                    //                 .toString()
                    //                 .toLowerCase()
                    //                 .contains(_searchQuery.toLowerCase()) ||
                    //             location['city']
                    //                 .toString()
                    //                 .toLowerCase()
                    //                 .contains(_searchQuery.toLowerCase()))) {
                    //       return Container();
                    //     }
                    //
                    //     return Container(
                    //       margin:
                    //           EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    //       decoration: BoxDecoration(
                    //         color: Theme.of(context)
                    //             .colorScheme
                    //             .surfaceContainerHighest,
                    //         border: Border.all(
                    //           color: Theme.of(context)
                    //               .colorScheme
                    //               .surfaceContainerHighest,
                    //         ),
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       child: IntrinsicHeight(
                    //         child: Row(
                    //           children: [
                    //             Checkbox(
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(6),
                    //               ),
                    //               value: location['isChecked'] ?? false,
                    //               onChanged: (bool? value) {
                    //                 setState(() {
                    //                   location['isChecked'] = value!;
                    //
                    //                   if (value) {
                    //                     selectedLocations.add(
                    //                         location); // Use add() instead of insert()
                    //                   } else {
                    //                     selectedLocations.removeWhere((item) =>
                    //                         item['id'] == location['id']);
                    //                   }
                    //
                    //                   // Check if all items are selected
                    //                   _selectAll = provider.geocodingList.every(
                    //                       (item) => item['isChecked'] == true);
                    //                 });
                    //               },
                    //             ),
                    //             SizedBox(width: 8),
                    //             Expanded(
                    //               child: Column(
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   SizedBox(height: 10),
                    //                   Text(
                    //                     location['formatted_address'],
                    //                     style: typography.Body1,
                    //                     maxLines: 2,
                    //                     overflow: TextOverflow.ellipsis,
                    //                   ),
                    //                   SizedBox(height: 4),
                    //                   Text(
                    //                     "${location['city'] != null && location['city'].isNotEmpty ? location['city'] : ''}"
                    //                     "${location['state'] != null && location['state'].isNotEmpty ? (location['city'] != null && location['city'].isNotEmpty ? ', ' : '') + location['state'] : ''}"
                    //                     "${location['country'] != null && location['country'].isNotEmpty ? ((location['city'] != null && location['city'].isNotEmpty) || (location['state'] != null && location['state'].isNotEmpty) ? ', ' : '') + location['country'] : ''}",
                    //                     style: typography.Caption,
                    //                     overflow: TextOverflow.ellipsis,
                    //                   ),
                    //                   SizedBox(height: 10),
                    //                 ],
                    //               ),
                    //             ),
                    //             Container(
                    //               decoration: BoxDecoration(
                    //                 borderRadius: BorderRadius.only(
                    //                   topRight: Radius.circular(12),
                    //                   bottomRight: Radius.circular(12),
                    //                 ),
                    //                 color: Theme.of(context)
                    //                     .colorScheme
                    //                     .surfaceContainerLow,
                    //               ),
                    //               width: 50,
                    //               height: double.infinity,
                    //               child: IconButton(
                    //                 icon: Icon(Icons.info,
                    //                     color: Theme.of(context)
                    //                         .colorScheme
                    //                         .primary),
                    //                 onPressed: () {
                    //                   Navigator.push(
                    //                     context,
                    //                     MaterialPageRoute(
                    //                       builder: (context) =>
                    //                           LocationHeadersScreen(
                    //                               location: location),
                    //                     ),
                    //                   );
                    //                 },
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ),

            UploadPreviewButtons(
              accountId: widget.accountId,
              accountName: widget.accountName,
              subAccountName: widget.subAccountName,
              tempId: widget.tempId,
              processId: widget.processId,
              subAccountId: widget.subAccountId,
              selectedLocations: selectedLocations,
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
          decoration: BoxDecoration(
            color: _bgAnimation.value, // Blinking background color
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          padding: EdgeInsets.fromLTRB(4, 1, 4, 2), // Optional padding
          child: Text(
            '${widget.conflictCount}',
            textAlign: TextAlign.center,
            style: widget.style.copyWith(
              color: _colorAnimation.value, // Blinking text color
            ),
          ),
        );
        //   Container(
        //   // padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        //   decoration: BoxDecoration(
        //     color: _bgAnimation.value, // Blinking background color
        //     borderRadius: BorderRadius.circular(10), // Rounded corners
        //   ),
        //   child: Text(
        //     '${widget.conflictCount}',
        //     style: widget.style.copyWith(
        //       color: _colorAnimation.value, // Blinking text color
        //     ),
        //   ),
        // );
      },
    );
  }
}


class BlinkingText1 extends StatefulWidget {
  final int conflictCount;
  final TextStyle style;
  final Color blinkColor;
  final Color defaultColor;

  const BlinkingText1({
    Key? key,
    required this.conflictCount,
    required this.style,
    required this.blinkColor,
    required this.defaultColor,
  }) : super(key: key);

  @override
  _BlinkingText1State createState() => _BlinkingText1State();
}

class _BlinkingText1State extends State<BlinkingText1>
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
          padding: EdgeInsets
              .symmetric(
              horizontal:
              6,
              vertical:
              0),
          decoration:
          BoxDecoration(
            color: _bgAnimation.value,
            borderRadius:
            BorderRadius
                .circular(
                10),
          ),
          // decoration: BoxDecoration(
          //   color: _bgAnimation.value, // Blinking background color
          //   borderRadius: BorderRadius.circular(10), // Rounded corners
          // ),
          // padding: EdgeInsets.fromLTRB(4, 1, 4, 2), // Optional padding
          child: Text(
            '${widget.conflictCount}',
            textAlign: TextAlign.center,
            style: widget.style.copyWith(
              color: _colorAnimation.value, // Blinking text color
            ),
          ),
        );
        //   Container(
        //   // padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        //   decoration: BoxDecoration(
        //     color: _bgAnimation.value, // Blinking background color
        //     borderRadius: BorderRadius.circular(10), // Rounded corners
        //   ),
        //   child: Text(
        //     '${widget.conflictCount}',
        //     style: widget.style.copyWith(
        //       color: _colorAnimation.value, // Blinking text color
        //     ),
        //   ),
        // );
      },
    );
  }
}
