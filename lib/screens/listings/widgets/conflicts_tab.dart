import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:RiskSphare/design_system/components/custom_button.dart';
import 'package:RiskSphare/screens/listings/widgets/upload_preview_buttons.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/upload_sov_provider.dart';
import 'message_card.dart';

class ConflictsTab extends StatefulWidget {
  final String processId;
  final String accountId;
  final String subAccountId;
  final String accountName;
  final String tempId;
  final TabController? masterTabController;

  const ConflictsTab({
    super.key,
    required this.processId,
    required this.accountId,
    required this.subAccountId,
    required this.accountName,
    required this.tempId,
    required this.masterTabController,
  });

  @override
  ConflictsTabState createState() => ConflictsTabState();
}

class ConflictsTabState extends State<ConflictsTab> {
  Map<String, dynamic> response = {};
  int currentIndex = 0; // For pagination

  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  String? selectedOption =
      "none"; // To store the selected conflict resolution option

  Future<void> _getData() async {
    response = await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchConflicts(context, widget.processId);
    List<dynamic> data = response['result'] ?? [];

    if (Provider.of<UploadSovProvider>(context, listen: false)
        .conflictLocations
        .isNotEmpty) {
      _updateMap();
    }
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _navigateToMarker(double latitude, double longitude) {
    const double offset = 0.005; // Offset to move the marker slightly upward
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(latitude + offset, longitude),
      ),
    );
  }

  void _navigateNext() {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    if (currentIndex < provider.conflictLocations.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = 'none'; // Reset the selection for the next conflict
      });
      _updateMap();
    }
  }

  void _navigatePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedOption =
            'none'; // Reset the selection for the previous conflict
      });
      _updateMap();
    }
  }

  void _updateMap() {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    final currentLocation = provider.conflictLocations[currentIndex];
    if (currentLocation['conflicts'].isNotEmpty) {
      final firstConflict = currentLocation['conflicts'][0];
      _navigateToMarker(
        firstConflict['latitude'] ?? 10.0202,
        firstConflict['longitude'] ?? 102.0229,
      );
    }
  }

  void _resolveConflict() async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please select an option to resolve the conflict.")),
      );
      return;
    }
    var provider = Provider.of<UploadSovProvider>(context, listen: false);

    final currentConflict = provider.conflictLocations[currentIndex];
    final selectedData = [
      {
        'account_id': widget.accountId,
        'sub_account_id': widget.subAccountId,
        'unique_object_id': currentConflict['id'],
        'process_id': widget.processId,
        'location_id': selectedOption == 'none' ? null : selectedOption,
      }
    ];

    bool success = await Provider.of<UploadSovProvider>(
      context,
      listen: false,
    ).resolveConflict(context, selectedData);

    if (success) {
      await _getData();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Consumer<UploadSovProvider>(builder: (context, provider, child) {
      final bool hasConflicts = provider.conflictLocations.isNotEmpty;
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await _getData();
          },
          child: hasConflicts
              ? Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GoogleMap(
                      key: _mapKey,
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: provider.conflictLocations.isNotEmpty &&
                                provider
                                    .conflictLocations[currentIndex]
                                        ['conflicts']
                                    .isNotEmpty
                            ? LatLng(
                                provider.conflictLocations[currentIndex]
                                    ['conflicts'][0]['latitude'],
                                provider.conflictLocations[currentIndex]
                                    ['conflicts'][0]['longitude'],
                              )
                            : LatLng(0, 0),
                        zoom: 14,
                      ),
                      markers: {
                        // Main marker
                        Marker(
                          markerId: MarkerId('mainMarker'),
                          position: LatLng(
                            provider.conflictLocations[currentIndex]
                                    ['latitude'] ??
                                0,
                            provider.conflictLocations[currentIndex]
                                    ['longitude'] ??
                                0,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(
                            title: 'Main Location',
                            snippet: provider.conflictLocations[currentIndex]
                                ['formatted_address'],
                          ),
                        ),
                        // Conflict location markers
                        ...provider.conflictLocations[currentIndex]['conflicts']
                            .map<Marker>((conflict) {
                          return Marker(
                            markerId: MarkerId(conflict['location_id']),
                            position: LatLng(
                              conflict['latitude'] ?? 0.0,
                              conflict['longitude'] ?? 0.0,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue), // Blue marker
                            infoWindow: InfoWindow(
                              title: conflict['address'],
                            ),
                          );
                        }).toSet(),
                      },
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            child: DraggableScrollableSheet(
                              initialChildSize: 0.3,
                              minChildSize: 0.2,
                              maxChildSize: 0.7,
                              builder: (context, scrollController) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header Section
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHigh,
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                          ),
                                          child: Column(
                                            children: [
                                              SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  SizedBox(width: 8),
                                                  FloatingActionButton(
                                                    shape: CircleBorder(),
                                                    mini: true,
                                                    elevation: 0,
                                                    backgroundColor: Theme.of(
                                                            context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    onPressed:
                                                        _navigatePrevious,
                                                    child: Icon(
                                                      Icons.chevron_left,
                                                      size: 24,
                                                      color:
                                                          AppColors.primaryMain,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Resolve Conflicts',
                                                        style: CustomTypography(
                                                                context)
                                                            .Body1
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Chip(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(24),
                                                          side: BorderSide(
                                                              color: Colors
                                                                  .transparent),
                                                        ),
                                                        label: Text(
                                                          '${provider.conflictLocations.length}',
                                                          style:
                                                              CustomTypography(
                                                                      context)
                                                                  .Caption
                                                                  .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    ],
                                                  ),
                                                  Spacer(),
                                                  FloatingActionButton(
                                                    shape: CircleBorder(),
                                                    mini: true,
                                                    elevation: 0,
                                                    backgroundColor: Theme.of(
                                                            context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    onPressed: _navigateNext,
                                                    child: Icon(
                                                      Icons.chevron_right,
                                                      size: 24,
                                                      color:
                                                          AppColors.primaryMain,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                ],
                                              ),
                                              Divider(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                thickness: 2,
                                              ),
                                              SizedBox(height: 8),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: Text(
                                                  '${currentIndex + 1} - ${provider.conflictLocations[currentIndex]['formatted_address'].replaceAll(RegExp(r',\s*,+'), ',')}',
                                                  style:
                                                      CustomTypography(context)
                                                          .H7
                                                          .copyWith(
                                                            color: AppColors
                                                                .primaryMain,
                                                            height: 1,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                          ),
                                                ),
                                              ),
                                              SizedBox(height: 18),
                                            ],
                                          ),
                                        ),
                                        // Conflict Options
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: provider
                                                      .conflictLocations[
                                                          currentIndex]
                                                          ['conflicts']
                                                      .length >
                                                  3
                                              ? 3
                                              : provider
                                                  .conflictLocations[
                                                      currentIndex]['conflicts']
                                                  .length,
                                          itemBuilder: (context, index) {
                                            final conflict =
                                                provider.conflictLocations[
                                                        currentIndex]
                                                    ['conflicts'][index];
                                            return GestureDetector(
                                              onTap: () {
                                                _navigateToMarker(
                                                  conflict['latitude'] ?? 0.0,
                                                  conflict['longitude'] ?? 0.0,
                                                );
                                              },
                                              child: RadioListTile<String>(
                                                title:
                                                    Text(conflict['address']),
                                                value: conflict['location_id'],
                                                groupValue: selectedOption,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedOption = value!;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        RadioListTile<String>(
                                          title: Text("None of these"),
                                          value: "none",
                                          groupValue: selectedOption,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedOption = value!;
                                              // Save the selected option in the provider's list
                                              provider.conflictLocations[
                                                          currentIndex]
                                                      ['selected_option'] =
                                                  selectedOption;
                                            });
                                          },
                                        ),

                                        // RadioListTile<String>(
                                        //   title: Text("None of these"),
                                        //   value: "none",
                                        //   groupValue: selectedOption,
                                        //   onChanged: (value) {
                                        //     setState(() {
                                        //       selectedOption = value!;
                                        //     });
                                        //   },
                                        // ),
                                        // ListView.builder(
                                        //   shrinkWrap: true,
                                        //   physics:
                                        //       NeverScrollableScrollPhysics(),
                                        //   itemCount: provider
                                        //               .conflictLocations[
                                        //                   currentIndex]
                                        //                   ['conflicts']
                                        //               .length >
                                        //           3
                                        //       ? 3
                                        //       : provider
                                        //           .conflictLocations[
                                        //               currentIndex]['conflicts']
                                        //           .length,
                                        //   itemBuilder: (context, index) {
                                        //     final conflict =
                                        //         provider.conflictLocations[
                                        //                 currentIndex]
                                        //             ['conflicts'][index];
                                        //     return GestureDetector(
                                        //       onTap: () {
                                        //         _navigateToMarker(
                                        //           conflict['latitude'] ?? 0.0,
                                        //           conflict['longitude'] ?? 0.0,
                                        //         );
                                        //       },
                                        //       child: RadioListTile<String>(
                                        //         title:
                                        //             Text(conflict['address']),
                                        //         value: conflict['location_id'],
                                        //         groupValue: selectedOption,
                                        //         onChanged: (value) {
                                        //           setState(() {
                                        //             selectedOption = value;
                                        //           });
                                        //         },
                                        //       ),
                                        //     );
                                        //   },
                                        // ),
                                        // RadioListTile<String>(
                                        //   title: Text("None of these"),
                                        //   value: "none",
                                        //   groupValue: selectedOption,
                                        //   onChanged: (value) {
                                        //     setState(() {
                                        //       selectedOption = value;
                                        //     });
                                        //   },
                                        // ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: CustomButton(
                                                  type: ButtonType.elevated,
                                                  onPressed: _resolveConflict,
                                                  child: Text(
                                                    "Resolve",
                                                    style: CustomTypography(
                                                            context)
                                                        .ButtonLarge
                                                        .copyWith(
                                                            color:
                                                                Colors.black),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Great news, there are no conflicts to resolve!",
                          textAlign: TextAlign.center,
                          style: CustomTypography(context).Body1,
                        ),
                        SizedBox(height: 16),
                        MessageCard(
                          messageTextSpans: [
                            TextSpan(
                              text: "Please review the location list to ",
                              style: typography.Body2,
                            ),
                            TextSpan(
                              text: "geocode",
                              style: typography.Body2.copyWith(
                                color: AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  widget.masterTabController
                                      ?.animateTo(0); // Navigate to Geocode tab
                                },
                            ),
                            TextSpan(
                              text: " and address any ",
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
                                  widget.masterTabController?.animateTo(
                                      1); // Navigate to Conflicts tab
                                },
                            ),
                            TextSpan(
                              text: " locations already in the database.",
                              style: typography.Body2,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }
}
