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

class DuplicatesTab extends StatefulWidget {
  final String? subAccountName;
  final String processId;
  final String accountId;
  final String subAccountId;
  final TabController? masterTabController;
  final String tempId;
  final String accountName;

  const DuplicatesTab(
      {super.key,
       this.subAccountName,
      required this.processId,
      required this.accountId,
      required this.subAccountId,
      this.masterTabController,
      required this.tempId,
      required this.accountName});

  @override
  DuplicatesTabState createState() => DuplicatesTabState();
}

class DuplicatesTabState extends State<DuplicatesTab> {
  Map<String, dynamic> response = {};
  int currentIndex = 0; // For pagination

  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();

  Future<void> _getData() async {
    final uploadSovProvider =
        Provider.of<UploadSovProvider>(context, listen: false);

    List<dynamic> responses = await Future.wait([
      uploadSovProvider.fetchDuplicates(context, widget.processId),
      uploadSovProvider.fetchLocations(context, widget.processId),
      uploadSovProvider.fetchConflicts(context, widget.processId),
    ]);

    // Access responses if needed
    final duplicatesResponse = responses[0];
    final locationsResponse = responses[1];
    final conflictsResponse = responses[2];

    // Perform any further processing if necessary
  }

  Future<void> _getDataInital() async {
    response = await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchDuplicates(context, widget.processId);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDataInital(); // Ensures API calls happen after the widget is built
    });
    // _getData();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _navigateNext() {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    if (currentIndex < provider.duplicateLocations.length - 1) {
      setState(() {
        currentIndex++;
      });
      _updateMap();
    }
  }

  void _navigatePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _updateMap();
    }
  }

  void _updateMap() {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);
    final currentLocation = provider.duplicateLocations[currentIndex];
    final topDuplicate = currentLocation['top_duplicate'];
    if (topDuplicate != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(topDuplicate['latitude'] ?? 10.0202,
              topDuplicate['longitude'] ?? 102.0229),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadSovProvider>(builder: (context, provider, child) {
      final bool hasDuplicates = provider.duplicateLocations.isNotEmpty;
      var typography = CustomTypography(context);
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await _getData();
          },
          child: hasDuplicates
              ? Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GoogleMap(
                      key: _mapKey,
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: provider.duplicateLocations.isNotEmpty &&
                                provider.duplicateLocations[currentIndex]
                                        ['top_duplicate'] !=
                                    null
                            ? LatLng(
                                provider.duplicateLocations[currentIndex]
                                    ['top_duplicate']['latitude'],
                                provider.duplicateLocations[currentIndex]
                                    ['top_duplicate']['longitude'])
                            : LatLng(0, 0),
                        zoom: 14,
                      ),
                      markers: {
                        // Main address marker
                        Marker(
                          markerId: MarkerId('mainAddress'),
                          position: LatLng(
                            provider.duplicateLocations[currentIndex]
                                    ['top_duplicate']?['latitude'] ??
                                0,
                            provider.duplicateLocations[currentIndex]
                                    ['top_duplicate']?['longitude'] ??
                                0,
                          ),
                          infoWindow: InfoWindow(
                            title: '',
                            snippet: provider.duplicateLocations[currentIndex]
                                            ['top_duplicate']
                                        ?['geocode_input_address']
                                    ?['formatted_address'] ??
                                "",
                          ),
                        ),
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            onPressed: _navigatePrevious,
                                            child: Icon(
                                              Icons.chevron_left,
                                              size: 24,
                                              color: AppColors.primaryMain,
                                            ),
                                          ),
                                          Spacer(),
                                          Row(
                                            children: [
                                              Text(
                                                'Duplicates',
                                                style: CustomTypography(context)
                                                    .Body1
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Chip(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  side: BorderSide(
                                                      color:
                                                          Colors.transparent),
                                                ),
                                                label: Text(
                                                  '${currentIndex + 1} of ${provider.duplicateLocations.length}',
                                                  style:
                                                      CustomTypography(context)
                                                          .Caption
                                                          .copyWith(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          FloatingActionButton(
                                            shape: CircleBorder(),
                                            mini: true,
                                            elevation: 0,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            onPressed: _navigateNext,
                                            child: Icon(
                                              Icons.chevron_right,
                                              size: 24,
                                              color: AppColors.primaryMain,
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Text(
                                          '${currentIndex + 1} - ${provider.duplicateLocations[currentIndex]['formatted_address']}',
                                          style: CustomTypography(context)
                                              .H7
                                              .copyWith(
                                                color: AppColors.primaryMain,
                                                height: 1,
                                                fontWeight: FontWeight.w300,
                                              ),
                                        ),
                                      ),
                                      SizedBox(height: 18),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text(
                                      provider.duplicateLocations[currentIndex]
                                              ['top_duplicate']?['address'] ??
                                          "",
                                      style: CustomTypography(context)
                                          .Body1
                                          .copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                    ),
                                  ),
                                ),
                                // Add text
                                SizedBox(height: 16),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: MessageCard(
                                        messageTextSpans: [
                                          TextSpan(
                                            text:
                                                "The locations are already in our database. Please review them for accuracy. If you find any discrepancies, click the \"It's not Duplicate!\" button.",
                                            style: typography.Body2.copyWith(
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      )),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            type: ButtonType.elevated,
                                            onPressed: () async {
                                              // Get the current duplicate row
                                              final currentDuplicate =
                                                  provider.duplicateLocations[
                                                      currentIndex];

                                              // Call the method to mark as not duplicate
                                              bool success = await Provider.of<
                                                  UploadSovProvider>(
                                                context,
                                                listen: false,
                                              ).markAsNotDuplicate(
                                                  context,
                                                  widget.accountId,
                                                  widget.subAccountId,
                                                  widget.processId,
                                                  [currentDuplicate],
                                                  provider.duplicateLocations[
                                                          currentIndex]['id'] ??
                                                      "" // Pass the current duplicate
                                                  );

                                              final uploadSovProvider = Provider
                                                  .of<UploadSovProvider>(
                                                      context,
                                                      listen: false);

                                              if (success) {
                                                // Remove from duplicate list
                                                provider.duplicateLocations
                                                    .removeAt(currentIndex);

                                                // Add the item to the geocoding list (assuming it should now be treated as a valid location)
                                                provider.geocodingList
                                                    .add(currentDuplicate);

                                                // If the item was in the conflict list, remove it
                                                provider.conflictLocations
                                                    .removeWhere((conflict) =>
                                                        conflict['id'] ==
                                                        currentDuplicate['id']);

                                                // Update counts locally without API call
                                                uploadSovProvider
                                                        .duplicateCount =
                                                    provider.duplicateLocations
                                                        .length;
                                                uploadSovProvider
                                                        .locationCount =
                                                    provider
                                                        .geocodingList.length;
                                                uploadSovProvider
                                                        .conflictCount =
                                                    provider.conflictLocations
                                                        .length;

                                                // Notify UI about the update
                                                uploadSovProvider
                                                    .refreshCounts();

                                                // Debugging log for verification
                                                print(
                                                    "Updated Counts - Duplicates: ${uploadSovProvider.duplicateCount}");
                                                print(
                                                    "Updated Counts - Locations: ${uploadSovProvider.locationCount}");
                                                print(
                                                    "Updated Counts - Conflicts: ${uploadSovProvider.conflictCount}");
                                              }
                                            },
                                            child: Text(
                                              "It's not duplicate!",
                                              style: CustomTypography(context)
                                                  .ButtonLarge
                                                  .copyWith(
                                                    color: Colors.black,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                          UploadPreviewButtons(
                            subAccountName: widget.subAccountName,
                            accountId: widget.accountId,
                            accountName: widget.accountName,
                            tempId: widget.tempId,
                            processId: widget.processId,
                            subAccountId: widget.subAccountId,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Looks Like none of the locations are present in the database.",
                          textAlign: TextAlign.center,
                          style: typography.Body1,
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
                              text: " and resolve any ",
                              style: typography.Body2,
                            ),
                            TextSpan(
                              text: "conflicts.",
                              style: typography.Body2.copyWith(
                                color: AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  widget.masterTabController?.animateTo(
                                      2); // Navigate to Conflicts tab
                                },
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
