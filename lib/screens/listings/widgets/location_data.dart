import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/utilities/custom_spacing.dart';
import 'package:RiskSphere/screens/listings/widgets/duplicates_tab.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/firestore_service.dart';
import '../../../service/language_service.dart';
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
  bool _isLoadData = false;

  Map<String, dynamic> response = {};

  TabController? _masterTabController;
  int selectedMasterTab = 0;
  late ScrollController _scrollController;
  TextEditingController _textEditingController = TextEditingController();
  List<Map<String, dynamic>> selectedLocations = [];
  String processStatus = '';
  final FirebaseFirestore _db = FirestoreService.db;
  StreamSubscription<QuerySnapshot>? _processStatusSubscription;

  @override
  void initState() {
    super.initState();
    _listenToProcessStatus();
    _scrollController = ScrollController();
    _masterTabController = TabController(length: 2, vsync: this);

    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
      if (selectedMasterTab == 0 && !_isLoading) {
        // _listenToProcessStatus();
      }
    });
    _listenToProcessStatus();
  }

  void _listenToProcessStatus() {
    final query = _db
        .collection('processes')
        .where('process_id', isEqualTo: widget.processId);

    _processStatusSubscription = query.snapshots().listen((querySnapshot) {
      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();

        if (!mounted) return;

        setState(() {
          processStatus = data['duplication_check_status'] ?? '';
        });

        print(processStatus);
        _getData(); // Make sure _getData checks `mounted` before setState
      }
    });
  }

  @override
  void dispose() {
    _processStatusSubscription?.cancel();
    _masterTabController?.dispose();
    _scrollController.dispose();
    super.dispose();
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
      ]);
    } catch (e) {
      print("Error fetching data: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error fetching data. Please try again.")),
      // );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getGeocodeData() async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() => _isLoading = true);

    try {
      final uploadSovProvider =
          Provider.of<UploadSovProvider>(context, listen: false);

      // Call APIs in parallel
      await Future.wait([
        uploadSovProvider.fetchLocations(context, widget.processId),
        // uploadSovProvider.fetchDuplicates(context, widget.processId),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error fetching data. Please try again.")),
      // );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    var provider = Provider.of<UploadSovProvider>(context, listen: false);

    setState(() {
      _selectAll = value;

      // Set all checkboxes in the list based on _selectAll
      for (var location in provider.geocodingList) {
        location['isChecked'] = _selectAll;
      }

      // Update selectedLocations accordingly
      selectedLocations = _selectAll ? List.from(provider.geocodingList) : [];
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
                                    child: TabBar(
                                      controller: _masterTabController,
                                      tabAlignment: TabAlignment.start,
                                      labelStyle: typography.Subtitle2,
                                      isScrollable: true,
                                      indicatorColor: AppColors.primaryMain,
                                      labelColor: AppColors.primaryMain,
                                      unselectedLabelColor: Colors.grey,
                                      onTap: (index) async {
                                        setState(() {
                                          _currentIndex = index;
                                          _isLoading = true; // Show loader
                                        });

                                        // Wait for all data to load
                                        await _getData();
                                        if (_currentIndex == 0) {
                                          await _getGeocodeData();
                                        }

                                        setState(() {
                                          _isLoading =
                                              false; // Hide loader after everything completes
                                        });
                                      },

                                      // onTap: (index) {
                                      //   setState(() {
                                      //     _currentIndex = index;
                                      //   });
                                      //   _getData();
                                      //   _currentIndex == 0 ? _getGeocodeData() : null;
                                      // },
                                      tabs: [
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.5,
                                          child: Tab(
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
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.5,
                                          child: Tab(
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
                                                                        BorderRadius.circular(
                                                                            10),
                                                                  ),
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
                                                                ? BlinkingText1(
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
                                                                : Container(
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
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
                          // StreamBuilder<DocumentSnapshot>(
                          //     stream: FirebaseFirestore.instance
                          //         .collection('processes_status')
                          //         .doc(widget.processId)
                          //         .snapshots(),
                          //     builder: (context, snapshot) {
                          //       if (snapshot.connectionState ==
                          //           ConnectionState.waiting) {
                          //         return SizedBox();
                          //       }
                          //       final data = snapshot.data!.data()
                          //           as Map<String, dynamic>;
                          //       final duplicationCheckStatus =
                          //           data['duplication_check_status']
                          //               ?.toLowerCase();
                          //       print(
                          //           "Duplication Check Status: $duplicationCheckStatus");
                          //
                          if (processStatus != "completed") ...[
                            //         // Show animated loader if duplication check is not completed
                            //         return
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Add your animated loader here
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * 0.1,
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

                                  Consumer<UploadSovProvider>(
                                      builder: (context, provider, child) {
                                    return Text(
                                      "We're currently reviewing your addresses.\nJust hang tight for a few minutes, and we'll have it ready for you shortly! ${provider.geocodingList.length.toString()} locations completed.",
                                      textAlign: TextAlign.center,
                                      style: typography.Subtitle1,
                                    );
                                  }),
                                ],
                              ),
                            )
                          ] else if (processStatus == "completed") ...[
                            // }
                            // return
                            Expanded(
                              child: _isLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : _locationListBody(typography, context),
                            ),
                            // Expanded(
                            //     child: _locationListBody(typography, context)),
                          ],
                          // }),
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
                    ],
                  ),
                ),
              ],
            ),
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
                          _selectAll == false ? "Select All" : "DeSelect All",
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
                                  text:
                                      "Please review the list of duplicate locations.",
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 13)),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
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
                                      value: location['isChecked'] ?? false,
                                      onChanged: (bool? value) {
                                        if (value == null) return;

                                        final currentOffset =
                                            _scrollController.offset;

                                        setStateLocal(() {
                                          location['isChecked'] = value;
                                        });

                                        if (value) {
                                          if (!selectedLocations.any((item) =>
                                              item['id'] == location['id'])) {
                                            selectedLocations.add(location);
                                          }
                                        } else {
                                          selectedLocations.removeWhere(
                                              (item) =>
                                                  item['id'] == location['id']);
                                          _selectAll = false;
                                        }

                                        if (provider.geocodingList.every(
                                            (item) =>
                                                item['isChecked'] == true)) {
                                          _selectAll = true;
                                        }

                                        print(_selectAll);
                                        print("_selectAll");
                                        setState(() {
                                          // _selectAll = _selectAll;
                                          _selectAll = provider.geocodingList
                                              .every((item) =>
                                                  item['isChecked'] == true);
                                        });
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (_scrollController.hasClients) {
                                            _scrollController
                                                .jumpTo(currentOffset);
                                          }
                                        });
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
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          decoration: BoxDecoration(
            color: _bgAnimation.value,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${widget.conflictCount}',
            textAlign: TextAlign.center,
            style: widget.style.copyWith(
              color: _colorAnimation.value, // Blinking text color
            ),
          ),
        );
      },
    );
  }
}
