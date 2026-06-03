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
import '../../../providers/account_list_provider.dart';
import '../../../providers/location_list_provider.dart';
import '../../../service/language_service.dart';
import '../../payments/purchase_license.dart';
import '../location_profile.dart'; // For SVG rendering.

class MyLocationCard extends StatefulWidget {
  final String? locationName;
  final String? hasAnyPlan;
  final Map<String, HazardDetails>? hazards;
  final bool? isConflict;
  final String imageUrl;
  final String locationId;
  final String accountName;
  final String ownerName;
  final String companyName;
  final String address;
  final double percentage;
  final int geocodingScore;
  final int riskScore;
  final dynamic dataCompletenessScore;
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
  String? role;
  bool? hasVendorData;
  bool? usFlag;
  bool? hasSov;
  String? hasHazardHubCount;

  MyLocationCard(
      {super.key,
      this.locationName,
      this.hasAnyPlan,
      this.hazards,
      this.isConflict,
      required this.imageUrl,
      required this.locationId,
      required this.accountName,
      required this.ownerName,
      required this.companyName,
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
      this.role,
      this.hasVendorData,
      this.hasSov,
      this.usFlag,
      this.hasHazardHubCount});

  @override
  State<MyLocationCard> createState() => _MyLocationCardState();
}

class _MyLocationCardState extends State<MyLocationCard> {
  List<Color> scoreColors = [
    Colors.grey[300]!,
    Colors.red[900]!,
    Colors.red[300]!,
    Colors.yellow[300]!,
    Colors.green[300]!,
    Colors.green[600]!,
  ];

  ScrollController _scrollController = ScrollController();

  final Set<String> _optimisticProcessingIds = {};
  final Set<String> _optimisticUnlockedHazards = {};
  bool selectionMode = false;

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    final provider = Provider.of<MyLocationListProvider>(context);

    selectionMode =
        provider.isGlobalSelectAll || provider.selectedLocationIds.isNotEmpty;

    // selectionMode = Provider.of<MyLocationListProvider>(context)
    //     .selectedLocations
    //     .isNotEmpty;
    MyLocation? myLocation;
    if (widget.isCertified) {
      myLocation = Provider.of<MyLocationListProvider>(context, listen: false)
          .getCertifiedLocationById(widget.locationId);
    } else {
      myLocation = Provider.of<MyLocationListProvider>(context, listen: false)
          .getLocationById(widget.locationId);
    }
    // Check if the location is selected
    // final isSelected = provider.selectedLocationIds.contains(widget.locationId);
    final isSelected = provider.isSelected(widget.locationId);
    bool showViewHazard = widget.hasVendorData == true &&
        widget.usFlag == true &&
        widget.hasSov == true;

    bool showUnlockHazard = widget.hasVendorData == false &&
        widget.usFlag == true &&
        widget.hasSov == true;
    return GestureDetector(
      onTap: () {
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);

        // In selection mode, toggle the selection
        if (selectionMode) {
          provider.toggleItem(widget.locationId);

          if (provider.selectedCount == 0) {
            provider.clearSelection();
          }
        } else {
          // Open location details screen
          if (widget.isConflict == true) {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
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
                  sovId: "",
                ),
              ),
            )
                .then((result) {
              if (result == true) {
                widget.onNavigateBack?.call();
              }
            });
          } else {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (_) => LocationProfile(
                  locationName: widget.locationName,
                  accountId: widget.accountId ?? "",
                  accountName: widget.accountName ?? "",
                  subAccountId: widget.subAccountId ?? "",
                  subAccountName: widget.subAccountName ?? "",
                  sovId: widget.sovId ?? "",
                  sovName: widget.sovName ?? "",
                  searchQuery: widget.locationQuery ?? "",
                  locationId: '',
                  // Should this be widget.locationId?
                  page: (widget.index + 1).toString(),
                  totalPages: locationListProvider.locationHits.toString(),
                  hazardProcess: widget.hazardProcess,
                  onConfirmCallback: widget.getData,
                  onNavigateBack: widget.onNavigateBack,
                ),
              ),
            )
                .then((result) {
              if (result == true) {
                widget.onNavigateBack?.call();
              }
            });
          }

          widget.onNavigateStart?.call();
        }
      },
      onLongPress: () {
        var locationListProvider =
            Provider.of<MyLocationListProvider>(context, listen: false);

        // Toggle selection mode
        setState(() {
          selectionMode = true;
        });

        // Toggle selection for this item
        if (locationListProvider.isSelected(widget.locationId)) {
          locationListProvider.removeIdFromSelection(widget.locationId);
        } else {
          locationListProvider.addIdToSelection(widget.locationId);
        }
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                (showViewHazard || showUnlockHazard)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (showViewHazard) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LocationProfile(
                                      accountId: widget.accountId!,
                                      accountName: widget.accountName,
                                      subAccountId: widget.subAccountId!,
                                      subAccountName: widget.subAccountName!,
                                      sovId: "",
                                      sovName: "test",
                                      searchQuery: "",
                                      locationId: widget.locationId,
                                      page: "1",
                                      totalPages: "1",
                                      tab: 2,
                                    ),
                                  ),
                                );
                              } else if (showUnlockHazard) {
                                showInsufficientCreditsBottomSheet(
                                  context,
                               locationName: widget.address,
                                  hasHazardHubCount: widget.hasHazardHubCount,
                                  selectedLocationIds: [widget.locationId],
                                  onConfirmStart: () {
                                    setState(() {
                                      _optimisticProcessingIds
                                          .add(widget.locationId);
                                    });
                                  },
                                  onFinish: () async {
                                    setState(() {
                                      _optimisticUnlockedHazards.clear();
                                      _optimisticProcessingIds.clear();
                                    });

                                    widget.onNavigateBack?.call();
                                  },
                                  // onFinish: () async {
                                  //   setState(() {
                                  //     _optimisticUnlockedHazards.clear();
                                  //     _optimisticProcessingIds.clear();
                                  //     // selectedHazardLocationIds.clear();
                                  //   });
                                  //
                                  //   await context
                                  //       .read<AccountListProvider>()
                                  //       .fetchMissingParameterList(
                                  //         context,
                                  //         widget.sovId!,
                                  //         isRefresh: true,
                                  //       );
                                  //
                                  //   widget.getData?.call();
                                  //   widget.onNavigateBack?.call();
                                  // },
                                );

                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: showViewHazard
                                      ? AppColors.primaryMain
                                      : Color(0xFF2ECC71),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                showViewHazard
                                    ? 'View HazardHub'
                                    : 'Unlock HazardHub',
                                style: TextStyle(
                                  color: showViewHazard
                                      ? AppColors.primaryMain
                                      : const Color(0xFF2ECC71),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
                _buildTopRow(
                  context,
                  widget.campusId != null && widget.campusId!.isNotEmpty
                      ? [widget.campusId!, ...widget.tags]
                      : widget.tags,
                  isSelected,
                  widget.imageUrl,
                ),
                if (widget.sovId == null || widget.sovId!.isEmpty) ...[
                  Container()
                ] else ...[
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Owner : ",
                          style: typography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: widget.ownerName ?? "",
                          style: typography.Body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.white
                                    : AppColors.black,
                            fontSize: 14,
                            // Different font size for owner name
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  widget.companyName.toString().isNotEmpty
                      ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Company : ",
                                style: typography.Body2.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: widget.companyName.toString() ?? "",
                                style: typography.Body2.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontSize: 14,
                                  // Different font size for owner name
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Container(),
                  SizedBox(height: 8),
                  if (widget.role != null &&
                      widget.role.toString() != "null" &&
                      widget.role!.trim().isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Role : ",
                            style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: widget.role!,
                            style: typography.Body2.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.white
                                  : AppColors.blue50,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                  ]
                ],
                SizedBox(height: 8),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                        height: 50,
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
                                        CircularProgressIndicator(
                                            strokeWidth: 2),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  )
                                : Container(
                                    color: Colors.lightBlueAccent,
                                    width: 50,
                                    height: 50,
                                  ),
                      ),

            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  if (widget.sovId == null || widget.sovId!.isEmpty) ...[
                    Container()
                  ] else ...[
                    Text(
                      widget.locationName.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryMain,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Text(
                    widget.address.replaceFirst(RegExp(r'^\s*,\s*'), ''),
                    style: const TextStyle(
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
            SizedBox(width: 4),
            // Popup menu for actions
            CustomPopupMenuButton(
              locationId: widget.locationId,
              onDelete: widget.onDelete,
              onAddToSOV: widget.onAddToSOV,
              onAddTag: widget.onAddTag,
              hasAnyPlan: widget.hasAnyPlan.toString(),
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label,
      {bool isCampus = false}) {
    return Chip(
      labelStyle: CustomTypography(context).InputLabel,
      label: Text(label),
      backgroundColor:
          // isCampus
          //     ? AppColors.primaryMain.withOpacity(0.2)
          //     :
          Theme.of(context).colorScheme.surfaceContainerHighest,
      deleteIcon: Icon(Icons.close, size: 16),
      onDeleted: () {
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
    final layout = _ScoreCardLayout.of(context);
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
                      locationName: widget.locationName,
                      accountId: widget.accountId!,
                      accountName: widget.accountName,
                      subAccountId: widget.subAccountId!,
                      subAccountName: widget.subAccountName!,
                      sovId: widget.sovId ?? "",
                      sovName: widget.sovName ?? "",
                      searchQuery: widget.locationQuery ?? "",
                      locationId: '',
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
              LanguageService.getTranslated(context, "geocoding"),
              widget.address,
              widget.geocodingScore,
              widget.accountId!,
              widget.subAccountId!,
            ),
          ),
          SizedBox(width: layout.cardSpacing),
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
                      locationId: '',
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
                LanguageService.getTranslated(context, "hazard_score"),
                widget.address,
                widget.riskScore, // == 0 ? 5 : widget.riskScore,
                widget.accountId!,
                widget.subAccountId!),
          ),
          SizedBox(width: layout.cardSpacing),
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
                      locationId: '',
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
            child: _buildScoreCardcompleteness(
              context,
              LanguageService.getTranslated(context, "completeness"),

              widget.address,
              widget.dataCompletenessScore,
              // normalizeScore(widget.dataCompletenessScore),
              widget.accountId!,
              widget.subAccountId!,
            ),
          ),
        ],
      ),
    );
  }

  double normalizeScore(num score) {
    if (score <= 0) return 1.0;
    final double value = double.parse(score.toStringAsFixed(2));

    final int whole = value.floor();
    final double decimal = value - whole;

    if (decimal < 0.25) {
      return whole.toDouble();
    } else if (decimal < 0.75) {
      return whole + 0.5;
    } else {
      return whole + 1.0;
    }
  }

  Widget _buildScoreCard(BuildContext context, String title, String address,
      dynamic scoreInt, String accountId, String subAccountId) {
    final layout = _ScoreCardLayout.of(context);
    final int score = scoreInt.toInt();
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
      padding: EdgeInsets.all(layout.cardPadding),
      width: layout.cardWidth,
      height: layout.cardHeight,
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
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: layout.compactLayout
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                SizedBox(width: 8),
                if (title == 'Geocoding') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            GeocodingDialog(title: "Geocoding Rating"),
                      );
                    },
                    child: Icon(Icons.info),
                  ),
                ] else if (title == 'Hazard Score') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            HazardDialog(title: "Hazard Score"),
                      );
                    },
                    child: Icon(Icons.info),
                  ),
                ] else if (title == 'Completeness') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            CompletenessDialog(title: "Data Completeness"),
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
                //check the processing status
                if (widget.hazardProcess == true ||
                    title == 'Geocoding' ||
                    title == 'Completeness') ...[
                  title == 'Hazard Score'
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
                    child: VerticalBarIndicator(score: score == 0 ? 5 : score),
                  ),
                  SizedBox(width: 1),
                  isCertified || score == 0
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
                                textAlign: layout.compactLayout
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

  int toCeilScore(dynamic value) {
    if (value == null) return 1;

    final double number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 1.0;

    return number.ceil().clamp(1, 5);
  }

  Widget _buildScoreCardcompleteness(BuildContext context, String title,
      String address, dynamic scoreInt, String accountId, String subAccountId) {
    final layout = _ScoreCardLayout.of(context);
    // final int score = scoreInt.toInt();
    // final dynamic rawScore = (scoreInt).toDouble();
    // final int displayScore = rawScore.ceil().clamp(1, 5);
    // bool isCertified = score == 5; // Logic to check if it shows a certificate.
    List<Color> scoreColors = [
      Colors.grey[300]!, // 0 (unused / empty)
      Colors.red[900]!, // 1
      Colors.red[300]!, // 2
      Colors.yellow[300]!, // 3
      Colors.green[300]!, // 4
      Colors.green[600]!, // 5
    ];
    final int displayScore = toCeilScore(scoreInt);

    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(right: 5),
      padding: EdgeInsets.all(layout.cardPadding),
      width: layout.cardWidth,
      height: layout.cardHeight,
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
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: layout.compactLayout
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                SizedBox(width: 8),
                if (title == 'Geocoding') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            GeocodingDialog(title: "Geocoding Rating"),
                      );
                    },
                    child: Icon(Icons.info),
                  ),
                ] else if (title == 'Hazard Score') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            HazardDialog(title: "Hazard Score"),
                      );
                    },
                    child: Icon(Icons.info),
                  ),
                ] else if (title == 'Completeness') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            CompletenessDialog(title: "Data Completeness"),
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
                //check the processing status
                if (widget.hazardProcess == true ||
                    title == 'Geocoding' ||
                    title == 'Completeness') ...[
                  title == 'Hazard Score'
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
                    child: VerticalBarIndicator(
                        score: scoreInt.toString() == "0" ? "1" : scoreInt),
                  ),
                  SizedBox(width: 1),
                  // isCertified
                  //     ? SvgPicture.asset('assets/images/certified_five.svg',
                  //         width: 24, height: 24)
                  //     :
                  Container(
                    margin: EdgeInsets.only(left: 4),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor:
                          scoreColors[displayScore].withOpacity(0.6),

                      // backgroundColor:
                      // scoreColors[score].withOpacity(0.6),
                      child: Center(
                        child: Text(
                          scoreInt.toString() == "0"
                              ? "1"
                              : scoreInt.toString(),
                          style: typography.Body1.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: layout.compactLayout
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

class _ScoreCardLayout {
  final double cardWidth;
  final double cardHeight;
  final double cardSpacing;
  final double cardPadding;
  final double titleFontSize;
  final bool compactLayout;

  const _ScoreCardLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.cardSpacing,
    required this.cardPadding,
    required this.titleFontSize,
    required this.compactLayout,
  });

  static _ScoreCardLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final shortestSide = size.shortestSide;

    // Tablet: iPad, Android tablets, large foldables
    if (shortestSide >= 600) {
      return const _ScoreCardLayout(
        cardWidth: 220,
        cardHeight: 96,
        cardSpacing: 20,
        cardPadding: 10,
        titleFontSize: 15,
        compactLayout: false,
      );
    }

    // Small phone (e.g. iPhone SE, compact Android)
    if (width < 360) {
      return const _ScoreCardLayout(
        cardWidth: 148,
        cardHeight: 76,
        cardSpacing: 8,
        cardPadding: 6,
        titleFontSize: 12,
        compactLayout: true,
      );
    }

    // Regular phone (most iPhones / Android)
    if (width < 400) {
      return const _ScoreCardLayout(
        cardWidth: 165,
        cardHeight: 80,
        cardSpacing: 10,
        cardPadding: 8,
        titleFontSize: 13,
        compactLayout: true,
      );
    }

    // Large phone (Plus / Pro Max / wide Android)
    if (width < 600) {
      return const _ScoreCardLayout(
        cardWidth: 160,
        cardHeight: 80,
        cardSpacing: 2,
        cardPadding: 8,
        titleFontSize: 14,
        compactLayout: false,
      );
    }

    // Wide layout (landscape phone, foldable inner display)
    return const _ScoreCardLayout(
      cardWidth: 200,
      cardHeight: 88,
      cardSpacing: 16,
      cardPadding: 8,
      titleFontSize: 14,
      compactLayout: false,
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
  final String? hasAnyPlan;

  const CustomPopupMenuButton(
      {this.onAddToSOV,
      this.locationId = '',
      this.onDelete,
      this.onAddTag,
      this.hasAnyPlan});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
      final trialStatus = userProfileProvider.trialInfo['status'] ?? '';
      return GestureDetector(
        onTapDown: (details) {
          _showCustomMenu(context, details.globalPosition, hasAnyPlan);
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
                child: Text(
                    LanguageService.getTranslated(context, "delete_location"),
                    style: typography.Body1),
              ),
              PopupMenuItem<String>(
                value: 'add_tag',
                child: Text(LanguageService.getTranslated(context, "add_tag"),
                    style: typography.Body1),
              ),
            ]
          : [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                    LanguageService.getTranslated(context, "delete_location"),
                    style: typography.Body1),
              ),
              if (hasAnyPlan.toString() == "true") ...[
                PopupMenuItem<String>(
                  value: 'add_sov',
                  child: Text(
                      LanguageService.getTranslated(context, "add_to_sov"),
                      style: typography.Body1),
                ),
              ],
              PopupMenuItem<String>(
                value: 'add_tag',
                child: Text(LanguageService.getTranslated(context, "add_tag"),
                    style: typography.Body1),
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

class HazardDialog extends StatefulWidget {
  final String? title;
  final bool? status;

  HazardDialog({super.key, this.title, this.status});

  @override
  State<HazardDialog> createState() => _HazardDialogState();
}

class _HazardDialogState extends State<HazardDialog> {
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
                      widget.title.toString(),
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
                          "Not Susceptible to Hazard: This means the area is very unlikely to face any hazard.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          4,
                          "Less Likely Susceptible to Hazard: This means the area has a lower chance of experiencing a hazard.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          3,
                          "Likely Susceptible to Hazard: This means the area is likely to face a hazard.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          2,
                          "Highly Susceptible to Hazard: This means the area has a high likelihood of facing a hazard.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          1,
                          "Susceptible to Catastrophic Hazard: This means the area is extremely likely to face severe hazards with potentially disastrous consequences.",
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

class CompletenessDialog extends StatefulWidget {
  final String? title;
  final bool? status;

  CompletenessDialog({super.key, this.title, this.status});

  @override
  State<CompletenessDialog> createState() => _CompletenessDialogState();
}

class _CompletenessDialogState extends State<CompletenessDialog> {
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
                      widget.title.toString(),
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
                          "Complete & Verified: All critical and supporting parameters are fully populated, validated, and up to date. Data quality is high and suitable for accurate risk assessment.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          4,
                          "Largely Complete: Most critical parameters are available with minimal gaps in secondary data. Overall data quality remains reliable for analysis.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          3,
                          "Moderately Complete: Key parameters are present, but several supporting fields are missing or incomplete, which may affect risk precision.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          2,
                          "Poorly Complete: Multiple critical parameters are missing or partially filled, significantly limiting confidence in risk evaluation.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          1,
                          "Insufficient Data: Data coverage is minimal or inconsistent. Risk analysis cannot be performed reliably.",
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

class GeocodingDialogProfile extends StatefulWidget {
  final String? title;
  final bool? status;

  GeocodingDialogProfile({super.key, this.title, this.status});

  @override
  State<GeocodingDialogProfile> createState() => _GeocodingDialogProfileState();
}

class _GeocodingDialogProfileState extends State<GeocodingDialogProfile> {
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
                    widget.title == 'Geocoding Rating'
                        ? SvgPicture.asset('assets/images/geocoding_icon.svg',
                            width: 24, height: 24)
                        : SvgPicture.asset('assets/images/hazard_icon.svg',
                            width: 24, height: 24),
                    SizedBox(width: 8),
                    Text(
                      widget.title.toString(),
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
                          widget.title == 'Geocoding Rating'
                              ? "Exact Match: Indicates pinpoint precision, accurately identifying a specific building."
                              : widget.title == 'Hazard Score'
                                  ? "Not Susceptible to Hazard: This means the area is very unlikely to face any hazard."
                                  : "Complete & Verified: All critical and supporting parameters are fully populated, validated, and up to date. Data quality is high and suitable for accurate risk assessment.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          4,
                          widget.title == 'Geocoding Rating'
                              ? "Geometric Center: Represents the center of a complex of buildings or small area and is less precise than a specific building address."
                              : widget.title == 'Hazard Score'
                                  ? "Less Likely Susceptible to Hazard: This means the area has a lower chance of experiencing a hazard."
                                  : " Largely Complete: Most critical parameters are available with minimal gaps in secondary data. Overall data quality remains reliable for analysis.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          3,
                          widget.title == 'Geocoding Rating'
                              ? "Range Interpolated: Represents an address located along a street. Lacking to pinpoint a single building."
                              : widget.title == 'Hazard Score'
                                  ? "Likely Susceptible to Hazard: This means the area is likely to face a hazard."
                                  : "Moderately Complete: Key parameters are present, but several supporting fields are missing or incomplete, which may affect risk precision.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          2,
                          widget.title == 'Geocoding Rating'
                              ? "Sub Locality: The location is located in a sub locality like a small town or neighborhood and difficult to specify the building."
                              : widget.title == 'Hazard Score'
                                  ? "Highly Susceptible to Hazard: This means the area has a high likelihood of facing a hazard."
                                  : "Poorly Complete: Multiple critical parameters are missing or partially filled, significantly limiting confidence in risk evaluation.",
                          "",
                        ),
                        Divider(),
                        _buildRatingItem(
                          1,
                          widget.title == 'Geocoding Rating'
                              ? "Approximate: The location is located within a large region like a country, state or locality."
                              : widget.title == 'Hazard Score'
                                  ? "Susceptible to Catastrophic Hazard: This means the area is extremely likely to face severe hazards with potentially disastrous consequences."
                                  : "Insufficient Data: Data coverage is minimal or inconsistent. Risk analysis cannot be performed reliably.",
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
                      widget.title.toString(),
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
                          widget.title == 'Geocoding Rating' ||
                                  widget.title == 'Hazard Score'
                              ? "Exact Match: Indicates pinpoint precision, accurately identifying a specific building."
                              : "Complete & Verified: All critical and supporting parameters are fully populated, validated, and up to date. Data quality is high and suitable for accurate risk assessment.",
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

void showInsufficientCreditsBottomSheet(
  BuildContext context, {
  required String? locationName,
  required String? hasHazardHubCount,
  required List<String> selectedLocationIds,
  required VoidCallback onConfirmStart,
  required VoidCallback onFinish,
}) {
  final int length = selectedLocationIds.length;
  final int availableCredits = int.tryParse(hasHazardHubCount ?? '0') ?? 0;

  final int remainingCredits = availableCredits;
  final int remainingAfterUnlock = remainingCredits - length;

  final bool insufficientCredits = remainingAfterUnlock < 0;

  /// how many locations we can unlock
  final int unlockableCount =
      availableCredits.clamp(0, selectedLocationIds.length);

  bool understandResetChecked = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insufficientCredits
                          ? "Insufficient Credits"
                          : "Unlock HazardHub",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      insufficientCredits
                          ? "You've selected $length locations, but only $availableCredits credits are available."
                          : "Unlock HazardHub data for ${locationName}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      insufficientCredits
                          ? "To continue, you can purchase more credits."
                      :"This will consume $length HazardHub credit. You have $hasHazardHubCount credits remaining.",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      insufficientCredits
                          ? "During payment, your current location selection will not be saved. After purchase, you'll need to reselect locations to unlock HazardHub data."
                          : "Credits remaining after unlock: $remainingAfterUnlock",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (insufficientCredits)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: understandResetChecked,
                              onChanged: (value) {
                                setState(() {
                                  understandResetChecked = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF8EC9FF),
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            const Expanded(
                              child: Text(
                                "I understand my selection will reset after payment",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// BUTTON SECTION
                    if (insufficientCredits)
                      Row(
                        children: [
                          /// Cancel
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade600),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// Buy Credit
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8EC9FF),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: understandResetChecked
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PurchaseLicensePage(),
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text("Buy Credit"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// Unlock available credits
                          Expanded(
                            child: Consumer<AccountListProvider>(
                              builder: (context, provider, _) {
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: const Color(0xFF8EC9FF),
                                    side: const BorderSide(
                                        color: Color(0xFF8EC9FF)),
                                  ),
                                  onPressed: (!provider.isUpdating &&
                                          unlockableCount > 0)
                                      ? () async {
                                          try {
                                            onConfirmStart();

                                            await provider.unlockHazardHubData(
                                              context,
                                              locationIds: selectedLocationIds
                                                  .take(unlockableCount)
                                                  .toList(),
                                            );

                                            Navigator.pop(context);
                                            onFinish();
                                          } catch (e) {
                                            onFinish();
                                          }
                                        }
                                      : null,
                                  child: provider.isUpdating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text("Unlock $unlockableCount"),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Consumer<AccountListProvider>(
                          builder: (context, provider, _) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8EC9FF),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: (!provider.isUpdating)
                                  ? () async {
                                      try {
                                        onConfirmStart();
                                        await provider.unlockHazardHubData(
                                          context,
                                          locationIds: selectedLocationIds
                                              .take(unlockableCount)
                                              .toList(),
                                        );

                                        Navigator.pop(context); // close bottom sheet

                                        await Future.delayed(
                                          const Duration(milliseconds: 300),
                                        );

                                        onFinish();
                                      } catch (e) {
                                        onFinish();
                                      }
                                    }
                                  : null,
                              child: provider.isUpdating
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    )
                                  : const Text("Confirm Unlock"),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
