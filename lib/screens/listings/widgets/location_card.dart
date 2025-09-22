import 'package:RiskSphere/screens/listings/widgets/conflicts_tab.dart';
import 'package:RiskSphere/screens/listings/widgets/location_details_popup.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:provider/provider.dart';

import '../../../design_system/primitives/app_colors.dart';
import '../../../providers/location_list_provider.dart';
import '../location_profile.dart'; // For SVG rendering.

class MyLocationCard extends StatefulWidget {
  final Map<String, HazardDetails>? hazards;
  final bool? isConflict;
  final String imageUrl;
  final String locationId;
  final String accountName;
  final String ownerName;
  final String address;
  final double percentage;
  final int geocodingScore;
  final int riskScore;
  final int dataCompletenessScore;
  final bool isAutoCertified; // To show the certificate if score is 5.
  final List<String> tags;
  final void Function(String)? onDelete;
  final void Function(String)? onAddToSOV;
  final void Function(String)? onAddTag;
  final bool isCertified;
  final String? accountId;
  final String? subAccountId;
  final String? lat;
  final String? long;
  final dynamic overallScore;
  final int index;
  final String? sovId;
  final String? sovName;
  final String? subAccountName;
  final String? locationQuery;
  final String? campusId;
  final bool? hazardProcess;
  final bool? rented;

  // callback to get gata after coming back from profile page (nullable)
  final void Function()? getData;
  final VoidCallback? onNavigateStart;
  final VoidCallback? onNavigateBack;
  List<Conflicts>? conflict;
  bool? isHazardCanStart;

  MyLocationCard({
    super.key,
    this.hazards,
    this.isConflict,
    required this.imageUrl,
    required this.locationId,
    required this.accountName,
    required this.ownerName,
    required this.address,
    required this.percentage,
    required this.geocodingScore,
    required this.riskScore,
    required this.dataCompletenessScore,
    required this.isAutoCertified,
    required this.tags,
    required this.campusId,
    this.onDelete,
    this.onAddToSOV,
    this.isCertified = false,
    this.onAddTag,
    this.accountId,
    this.subAccountId,
    this.lat,
    this.long,
    this.overallScore,
    required this.index,
    this.sovId,
    this.sovName,
    this.subAccountName,
    this.locationQuery,
    this.hazardProcess,
    this.rented,
    this.getData,
    this.onNavigateStart,
    this.onNavigateBack,
    this.conflict,
    this.isHazardCanStart,
  });

  @override
  State<MyLocationCard> createState() => _MyLocationCardState();
}

class _MyLocationCardState extends State<MyLocationCard> {
  List<Color> scoreColors = [
    Colors.grey[300]!, // Default color for unfilled bars
    Colors.red[900]!, // Dark Red for 1
    Colors.red[300]!, // Light Red for 2
    Colors.yellow[300]!, // Light Yellow for 3
    Colors.green[300]!, // Light Green for 4
    Colors.green[600]!, // Green for 5
  ];

  ScrollController _scrollController = ScrollController();

  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    selectionMode = Provider.of<MyLocationListProvider>(context)
        .selectedLocations
        .isNotEmpty;
    MyLocation? myLocation;
    if (widget.isCertified) {
      myLocation = Provider.of<MyLocationListProvider>(context, listen: false)
          .getCertifiedLocationById(widget.locationId);
    } else {
      myLocation = Provider.of<MyLocationListProvider>(context, listen: false)
          .getLocationById(widget.locationId);
    }
    // Check if the location is selected
    final isSelected = Provider.of<MyLocationListProvider>(context)
        .selectedLocations
        .contains(myLocation);
    // final image = widget.imageUrl;
    return GestureDetector(
      onTap: () {
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);

        // In selection mode, toggle the selection if its last selection getting unselected we remove the selection mode
        if (selectionMode) {
          setState(() {
            if (isSelected) {
              Provider.of<MyLocationListProvider>(context, listen: false)
                  .removeFromSelection(myLocation);
            } else {
              Provider.of<MyLocationListProvider>(context, listen: false)
                  .addToSelection(myLocation);
            }
            if (Provider.of<MyLocationListProvider>(context, listen: false)
                .selectedLocations
                .isEmpty) {
              selectionMode = false;
            }
          });
        } else {
          var locationListProvider =
              Provider.of<MyLocationListProvider>(context, listen: false);
          // Open location details screen

          widget.isConflict == true
              ? Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => ConflictsTab(
                            processId: widget.accountId ?? "",
                            accountId: widget.accountId ?? "",
                            subAccountId: widget.subAccountId ?? "",
                            accountName: widget.accountName ?? "",
                            subAccountName: widget.subAccountName ?? "",
                            tempId: "tempId",
                            startHazard: widget.isHazardCanStart,
                            lat: widget.lat,
                            long: widget.long,
                            geocodingAddress: widget.address,
                            conflict: widget.conflict,
                            sovId: 'null',
                          )))
                  .then((result) {
                  if (result == true) {
                    widget.onNavigateBack!.call();
                  }
                })
              : Navigator.of(context)
                  .push(MaterialPageRoute(
                  builder: (_) => LocationProfile(
                    accountId: widget.accountId ?? "",
                    accountName: widget.accountName ?? "",
                    subAccountId: widget.subAccountId ?? "",
                    subAccountName: widget.subAccountName ?? "",
                    sovId: widget.sovId ?? "",
                    sovName: widget.sovName ?? "",
                    searchQuery: widget.locationQuery ?? "",
                    page: (widget.index + 1).toString(),
                    totalPages: locationListProvider.locationHits.toString(),
                    hazardProcess: widget.hazardProcess,
                    onConfirmCallback: widget.getData,
                    onNavigateBack: widget.onNavigateBack,
                  ),
                ))
                  .then((result) {
                  // widget.getData!();
                  if (result == true) {
                    // widget.getData!();
                    // widget.onNavigateStart?.call();
                    // widget.getData?.call();
                    // widget.onNavigateBack?.call();
                  } else {
                    // widget.getData!();
                    // widget.getData?.call();
                  }
                  // widget.onNavigateStart?.call();
                  // widget.getData?.call();
                });

          // ))
          //     . then((_) {
          //   widget.getData!();
          //   // Call getData after pop
          //   widget.onNavigateStart?.call();
          // });
          widget.onNavigateStart?.call();
          // widget.onNavigateBack?.call(); // ✅ Restore debouncer & timer
          // widget.getData?.call();
          /*.then((_) {
            // Call getData after pop
            _getData();
          });*/
        }
      },
      onLongPress: () {
        // Handle the long press event
        MyLocation? myLocation;
        if (widget.isCertified) {
          myLocation =
              Provider.of<MyLocationListProvider>(context, listen: false)
                  .getCertifiedLocationById(widget.locationId);
        } else {
          myLocation =
              Provider.of<MyLocationListProvider>(context, listen: false)
                  .getLocationById(widget.locationId);
        }
        setState(() {
          selectionMode = !selectionMode;
          if (selectionMode) {
            Provider.of<MyLocationListProvider>(context, listen: false)
                .addToSelection(myLocation);
          } else {
            Provider.of<MyLocationListProvider>(context, listen: false)
                .removeFromSelection(myLocation);
          }
        });
      },
      child: Container(
        color: Colors.grey.withOpacity(0.1),
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerLowest
              : Theme.of(context).cardColor.withOpacity(0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Text( widget.imageUrl),
                // Modify the call to _buildTopRow to handle campusId and tags
                _buildTopRow(
                  context,
                  widget.campusId != null && widget.campusId!.isNotEmpty
                      ? [widget.campusId!, ...widget.tags]
                      : widget.tags,
                  isSelected,
                  widget.imageUrl,
                ),

                SizedBox(height: 16),
                _buildScrollableScores(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the ScrollController when the widget is removed from the widget tree
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTopRow(BuildContext context, List<String> chipLabels,
      bool isSelected, String image) {
    return Row(
      children: [
        // Building Image

        isSelected
            ? CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primaryMain.withOpacity(0.5),
                child: Icon(Icons.check, color: Colors.white),
              )
            : widget.isConflict == true
                ? Container(
                    height: 50, // same as CircleAvatar's diameter (radius * 2)
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMain.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(
                          8), // Rounded square, adjust as needed
                    ),
                    child: Icon(Icons.block_rounded,
                        color: Colors.orange, size: 30),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: (widget.geocodingScore == 5)
                        ? CachedNetworkImage(
                            imageUrl:
                                "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${widget.lat},${widget.long}&key=AIzaSyBA8NoBrHa9JwGQT8Mk1s9lXqElfON_NGI",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          )
                        : image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              )
                            : Container(
                                color: Colors.lightBlueAccent,
                                // Image.asset(
                                // 'assets/images/building_image.png',
                                width: 50,
                                height: 50,
                                // fit: BoxFit.cover,
                              ),
                  ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chipLabels.length == 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip(context, chipLabels[0], isCampus: true),
                  ],
                ),
              if (chipLabels.length > 1)
                // Scrollable chip list with scrollbar for multiple chips
                Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 2,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: chipLabels
                            .map(
                              (label) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildChip(
                                  context,
                                  label,
                                  isCampus: label ==
                                      chipLabels[
                                          0], // Assuming the first chip is campus
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 4),
              // Overflowed address
              Text(
                widget.address,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryMain,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        /*SizedBox(width: 12),
        // Circular score with percentage and gaped border
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: widget.percentage / 100,
                strokeWidth: 4,
                strokeCap: StrokeCap.square,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            Text(
              '${widget.percentage}%',
              style: CustomTypography(context).InputLabel.copyWith(fontSize: 10),
            ),
          ],
        ),*/
        SizedBox(width: 4),
        // Popup menu for actions
        CustomPopupMenuButton(
          // geocodeingScore:  widget.geocodingScore,
          //   imageUrl: widget.
          locationId: widget.locationId,
          onDelete: widget.onDelete,
          onAddToSOV: widget.onAddToSOV,
          onAddTag: widget.onAddTag,
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label,
      {bool isCampus = false}) {
    return Chip(
      labelStyle: CustomTypography(context).InputLabel,
      label: Text(label),
      backgroundColor: isCampus
          ? AppColors.primaryMain.withOpacity(0.2)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      deleteIcon: isCampus ? null : Icon(Icons.close, size: 16),
      onDeleted: isCampus
          ? null
          : () {
              Provider.of<MyLocationListProvider>(context, listen: false)
                  .showDeleteTagDialog(
                context,
                widget.accountId ?? "",
                widget.subAccountId ?? "",
                widget.locationId,
                label,
              );
            },
    );
  }

  Widget _buildScrollableScores(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationProfile(
                      accountId: widget.accountId!,
                      accountName: widget.accountName,
                      subAccountId: widget.subAccountId!,
                      subAccountName: widget.subAccountName!,
                      sovId: widget.sovId ?? "",
                      sovName: widget.sovName ?? "",
                      searchQuery: widget.locationQuery ?? "",
                      page: (widget.index + 1).toString(),
                      totalPages: Provider.of<MyLocationListProvider>(context,
                              listen: false)
                          .locationHits
                          .toString(),
                      hazardProcess: widget.hazardProcess,
                      onConfirmCallback: widget.getData,
                      onNavigateBack: widget.onNavigateBack,
                      tab: 0,
                    ),
                  ));
            },
            child: _buildScoreCard(
              context,
              'Geocoding',
              widget.address,
              widget.geocodingScore,
              widget.accountId!,
              widget.subAccountId!,
            ),
          ),
          if (MediaQuery.of(context).size.width > 400) SizedBox(width: 5),
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationProfile(
                      accountId: widget.accountId!,
                      accountName: widget.accountName,
                      subAccountId: widget.subAccountId!,
                      subAccountName: widget.subAccountName!,
                      sovId: widget.sovId ?? "",
                      sovName: widget.sovName ?? "",
                      searchQuery: widget.locationQuery ?? "",
                      page: (widget.index + 1).toString(),
                      totalPages: Provider.of<MyLocationListProvider>(context,
                              listen: false)
                          .locationHits
                          .toString(),
                      hazardProcess: widget.hazardProcess,
                      onConfirmCallback: widget.getData,
                      onNavigateBack: widget.onNavigateBack,
                      tab: 1,
                    ),
                  ));
            },
            child: _buildScoreCard(
                context,
                'Risk Score',
                widget.address,
                widget.riskScore == 0 ? 5 : widget.riskScore,
                widget.accountId!,
                widget.subAccountId!),
          ),
          if (MediaQuery.of(context).size.width > 400) SizedBox(width: 5),
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationProfile(
                      accountId: widget.accountId!,
                      accountName: widget.accountName,
                      subAccountId: widget.subAccountId!,
                      subAccountName: widget.subAccountName!,
                      sovId: widget.sovId ?? "",
                      sovName: widget.sovName ?? "",
                      searchQuery: widget.locationQuery ?? "",
                      page: (widget.index + 1).toString(),
                      totalPages: Provider.of<MyLocationListProvider>(context,
                              listen: false)
                          .locationHits
                          .toString(),
                      hazardProcess: widget.hazardProcess,
                      onConfirmCallback: widget.getData,
                      onNavigateBack: widget.onNavigateBack,
                      tab: 2,
                    ),
                  ));
            },
            child: _buildScoreCard(
              context,
              'Completeness',
              widget.address,
              widget.dataCompletenessScore == 0
                  ? 1
                  : widget.dataCompletenessScore,
              widget.accountId!,
              widget.subAccountId!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, String title, String address,
      int score, String accountId, String subAccountId) {
    bool isCertified = score == 5; // Logic to check if it shows a certificate.
    List<Color> scoreColors = [
      Colors.grey[300]!, // Default color for unfilled bars
      Colors.red[900]!, // Dark Red for 1
      Colors.red[300]!, // Light Red for 2
      Colors.yellow[300]!, // Light Yellow for 3
      Colors.green[300]!, // Light Green for 4
      Colors.green[600]!, // Green for 5
    ];

    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(right: 5),
      padding: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width < 400 ? 165 : 190,
      height: MediaQuery.of(context).size.height < 400 ? 80 : 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: MediaQuery.of(context).size.width < 400
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                SizedBox(width: 8),
                if (title == 'Risk Score' || title == 'Geocoding') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => GeocodingDialog(title: title),
                      );
                    },
                    child: Icon(Icons.info),
                  ),
                ] else ...[
                  Icon(Icons.info, color: Colors.transparent),
                ]
              ],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.hazardProcess == true ||
                    title == 'Geocoding' ||
                    title == 'Completeness') ...[
                  title == 'Risk Score'
                      ? SvgPicture.asset('assets/images/hazard_icon.svg',
                          width: 24, height: 24)
                      : title == 'Completeness'
                          ? SvgPicture.asset(
                              'assets/images/data_completeness_icon.svg',
                              width: 24,
                              height: 24)
                          : title == 'Geocoding'
                              ? SvgPicture.asset(
                                  'assets/images/geocoding_icon.svg',
                                  width: 24,
                                  height: 24)
                              : const SizedBox(),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      if (title == 'Geocoding') {
                        showLocationDetailsPopup(
                            context,
                            widget.lat,
                            widget.long!,
                            widget.imageUrl,
                            widget.address,
                            widget.locationId,
                            widget.geocodingScore,
                            widget.overallScore!,
                            widget.dataCompletenessScore,
                            widget.hazards,
                            "MAc",
                            widget.accountId!,
                            widget.subAccountId!,
                            "widget.sovId!",
                            widget.accountName,
                            widget.subAccountName!,
                            widget.hazardProcess!,
                            widget.rented);
                      }
                    },
                    child: VerticalBarIndicator(score: score),
                  ),
                  SizedBox(width: 1),
                  isCertified
                      ? SvgPicture.asset('assets/images/certified_five.svg',
                          width: 24, height: 24)
                      : Container(
                          margin: EdgeInsets.only(left: 4),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                scoreColors[score].withOpacity(0.6),
                            child: Center(
                              child: Text(
                                score.toString(),
                                style: typography.Body1.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign:
                                    MediaQuery.of(context).size.width < 400
                                        ? TextAlign.center
                                        : TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                ] else ...[
                  Container(child: Text("Processing"))
                ]
              ],
            ),
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}

int scoreToStar(int? score) {
  if (score == null) return 0;
  if (score >= 80) return 5;
  if (score >= 60) return 4;
  if (score >= 40) return 3;
  if (score >= 20) return 2;
  return 0;
}

// Call this function to show the popup on tap
void showLocationDetailsPopup(
    BuildContext context,
    String? lat,
    String? long,
    String? imageUrl,
    String address,
    String locationId,
    int geocodingScore,
    dynamic overallScore,
    dynamic dataCompleteness,
    Map<String, HazardDetails>? hazards,
    String? professional,
    String accountId,
    String subAccountId,
    String sovId,
    String accountName,
    String subAccountName,
    bool? hazardProcess,
    bool? rented,
    [bool hideNavigation = false]) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return LocationDetailsPopup(
        lat: lat,
        long: long,
        // location.overallScore ?? 0,
        imageUrl: imageUrl,
        address: address ?? 'Unknown Address',
        locationId: locationId ?? 'Unknown ID',
        geocodingScore: geocodingScore,

        riskScore: overallScore.toString() ?? "5",
        dataCompleteness: scoreToStar(dataCompleteness),
        hazards: hazards ?? {},
        geocodedAt: [""],
        occupancy: ["--"],
        campus: locationId,
        rented: rented,
        accountId: accountId,
        subAccountId: subAccountId,
        sovId: sovId,
        accountName: accountName,
        subAccountName: subAccountName,
        sovName: address,
        hazardProcess: hazardProcess,
        // hideNavigation: "hideNavigation",
      );
    },
  );
}

class CustomPopupMenuButton extends StatelessWidget {
  final String? locationId;
  final void Function(String locationId)? onDelete;
  final void Function(String locationId)? onAddToSOV;
  final void Function(String locationId)? onAddTag;

  const CustomPopupMenuButton(
      {this.onAddToSOV, this.locationId = '', this.onDelete, this.onAddTag});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
      return GestureDetector(
        onTapDown: (details) {
          _showCustomMenu(context, details.globalPosition, trialStatus);
        },
        child: Icon(
          Icons.more_vert,
          size: 26,
        ),
      );
    });
  }

  void _showCustomMenu(BuildContext context, Offset offset, trialStatus) async {
    var typography = CustomTypography(context);
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 40, // Adjust for width offset if necessary
        offset.dy + 40, // Adjust for height offset if necessary
      ),
      items: onAddToSOV == null
          ? [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Location', style: typography.Body1),
              ),
              PopupMenuItem<String>(
                value: 'add_tag',
                child: Text('Add Tag', style: typography.Body1),
              ),
            ]
          : [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Location', style: typography.Body1),
              ),
              if (trialStatus.isEmpty)
                PopupMenuItem<String>(
                  value: 'add_sov',
                  child: Text('Add to SOV', style: typography.Body1),
                ),
              PopupMenuItem<String>(
                value: 'add_tag',
                child: Text('Add Tag', style: typography.Body1),
              ),
            ],
      elevation: 8.0,
      color: Theme.of(context).cardColor,
      // Customize the background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    // Handle the selection
    if (result != null) {
      if (result == 'delete') {
        onDelete?.call(locationId ?? "");
      } else if (result == 'add_sov') {
        print('Add to SOV');
        onAddToSOV?.call(locationId ?? "");
      } else if (result == 'add_tag') {
        print('Add Tag');
        onAddTag?.call(locationId ?? "");
      }
    }
  }
}

class GeocodingDialog extends StatefulWidget {
  final String? title;
  final bool? status;

  GeocodingDialog({super.key, this.title, this.status});

  @override
  State<GeocodingDialog> createState() => _GeocodingDialogState();
}

class _GeocodingDialogState extends State<GeocodingDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.black,
      child: Consumer<MyLocationListProvider>(
          builder: (context, locationProfileProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.status == true) ...[
                Text(
                  'Geocode Type: ${locationProfileProvider.locationProfile?.finalAddress?.locationType ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Property Type: ${locationProfileProvider.locationProfile?.finalAddress?.placeTypes?.join(', ') ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${locationProfileProvider.locationProfile?.finalAddress?.description ?? ""}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
              ] else ...[
                SizedBox(height: 10),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  // Keep background transparent if needed
                  shadowColor: Colors.white12,
                  // Remove button shadow
                  minimumSize: Size(double.infinity, 35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Define button action here
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // To ensure minimal button width
                  children: [
                    widget.title == 'Geocoding'
                        ? SvgPicture.asset('assets/images/geocoding_icon.svg',
                            width: 24, height: 24)
                        : SvgPicture.asset('assets/images/hazard_icon.svg',
                            width: 24, height: 24),
                    SizedBox(width: 8),
                    Text(
                      widget.title == 'Geocoding'
                          ? "Geocoding Rating"
                          : "Hazard Rating",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                    maxHeight: widget.status == true ? 350 : 500),
                // Set max height
                child: Scrollbar(
                  // Add scrollbar
                  thumbVisibility: true,
                  // Always show the scrollbar
                  trackVisibility: true,
                  // Show the scrollbar track
                  thickness: widget.status == true ? 1 : 0,
                  // Adjust scrollbar thickness
                  radius: Radius.circular(10),
                  // Optional: Round scrollbar edges
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        _buildRatingItem(
                          5,
                          "Exact Match: Indicates pinpoint precision, accurately identifying a specific building.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          4,
                          "Geometric Center: Represents the center of a complex of buildings or small area and is less precise than a specific building address.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          3,
                          "Range Interpolated: Represents an address located along a street. Lacking to pinpoint a single building.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          2,
                          "Sub Locality: The location is located in a sub locality like a small town or neighborhood and difficult to specify the building.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          1,
                          "Approximate: The location is located within a large region like a country, state or locality.",
                          "",
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMain,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size(double.infinity, 40),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Understood! Take me back.",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRatingItem(int rating, String title, String description) {
    Color getColor(int rating) {
      switch (rating) {
        case 5:
          return Colors.green;
        case 4:
          return Colors.lightGreen;
        case 3:
          return Colors.orange;
        case 2:
          return Colors.redAccent;
        case 1:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          rating == 5
              ? SvgPicture.asset('assets/images/certified_five.svg',
                  width: 24, height: 24)
              : CircleAvatar(
                  radius: 12,
                  backgroundColor: getColor(rating),
                  child: Text(
                    rating.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
