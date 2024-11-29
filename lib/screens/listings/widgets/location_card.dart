import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/models/my_location_list_model.dart';
import 'package:green/providers/my_location_list_provider.dart';
import 'package:green/screens/listings/widgets/vertical_bar_indicator.dart';
import 'package:provider/provider.dart';

import '../../../design_system/primitives/app_colors.dart';
import '../../../providers/location_list_provider.dart';
import '../location_profile.dart'; // For SVG rendering.

class MyLocationCard extends StatefulWidget {
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
  final int index;
  final String? sovId;
  final String? sovName;
  final String? subAccountName;
  final String? locationQuery;
  final String? campusId;
  // callback to get gata after coming back from profile page (nullable)
  final void Function()? getData;

  const MyLocationCard({
    super.key,
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
    required this.index,
    this.sovId,
    this.sovName,
    this.subAccountName,
    this.locationQuery,
    this.getData,

  });

  @override
  State<MyLocationCard> createState() => _MyLocationCardState();
}

class _MyLocationCardState extends State<MyLocationCard> {
  List<Color> scoreColors = [
    Colors.grey[300]!, // Default color for unfilled bars
    Colors.red[900]!,  // Dark Red for 1
    Colors.red[300]!,  // Light Red for 2
    Colors.yellow[300]!, // Light Yellow for 3
    Colors.green[300]!,  // Light Green for 4
    Colors.green[600]!,  // Green for 5
  ];

  ScrollController _scrollController = ScrollController();

  bool selectionMode = false;


  @override
  Widget build(BuildContext context) {
    print("Campus ID: ${widget.campusId}");
    selectionMode = Provider.of<MyLocationListProvider>(context).selectedLocations.isNotEmpty;
    MyLocation? myLocation;
    if (widget.isCertified) {
      myLocation = Provider.of<MyLocationListProvider>(
          context, listen: false).getCertifiedLocationById(widget.locationId);
    } else {
      myLocation = Provider.of<MyLocationListProvider>(
          context, listen: false).getLocationById(widget.locationId);
    }
    // Check if the location is selected
    final isSelected = Provider.of<MyLocationListProvider>(context)
        .selectedLocations
        .contains(myLocation);
    final image = widget.imageUrl;
    return GestureDetector(
      onTap: () {
        // In selection mode, toggle the selection if its last selection getting unselected we remove the selection mode
        if (selectionMode) {
          setState(() {
            if (isSelected) {
              Provider.of<MyLocationListProvider>(context, listen: false).removeFromSelection(myLocation);
            } else {
              Provider.of<MyLocationListProvider>(context, listen: false).addToSelection(myLocation);
            }
            if (Provider.of<MyLocationListProvider>(context, listen: false).selectedLocations.isEmpty) {
              selectionMode = false;
            }
          });
        } else {
          // Handle the tap event
          print('Tapped on location: ${widget.locationId}');
          print('Going to page ${widget.index}');
          var locationListProvider = Provider.of<MyLocationListProvider>(context, listen: false);
          // Open location details screen
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LocationProfile(
              accountId: widget.accountId??"",
              accountName: widget.accountName??"",
              subAccountId: widget.subAccountId??"",
              subAccountName: widget.subAccountName??"",
              sovId: widget.sovId??"",
              sovName: widget.sovName??"",
              searchQuery: widget.locationQuery??"",
              page: (widget.index+1).toString(),
              totalPages: locationListProvider.locationHits.toString(),
            ),
          )).then((_) {
            // Call getData after pop
            widget.getData?.call();
          });
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
          myLocation = Provider.of<MyLocationListProvider>(
              context, listen: false).getCertifiedLocationById(widget.locationId);
        } else {
          myLocation = Provider.of<MyLocationListProvider>(
              context, listen: false).getLocationById(widget.locationId);
        }
        setState(() {
          selectionMode = !selectionMode;
          if (selectionMode) {
            Provider.of<MyLocationListProvider>(context, listen: false).addToSelection(myLocation);
          } else {
            Provider.of<MyLocationListProvider>(context, listen: false).removeFromSelection(myLocation);
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Modify the call to _buildTopRow to handle campusId and tags
              _buildTopRow(
                context,
                widget.campusId != null && widget.campusId!.isNotEmpty
                    ? [widget.campusId!, ...widget.tags]
                    : widget.tags,
                isSelected,
                image,
              ),


              SizedBox(height: 16),
              _buildScrollableScores(context),
            ],
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

  Widget _buildTopRow(BuildContext context, List<String> chipLabels, bool isSelected, String image) {
    return Row(
      children: [
        // Building Image
        isSelected
            ? CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primaryMain.withOpacity(0.5),
          child: Icon(Icons.check, color: Colors.white),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: image.isNotEmpty
              ? Image.network(
            image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Image.asset(
            'assets/images/building_image.png',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 8),

        // Expanded chip list or single chip
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chipLabels.length == 1)
              // Center single chip to take full width
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
                              isCampus: label == chipLabels[0], // Assuming the first chip is campus
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
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        SizedBox(width: 12),
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
        ),
        SizedBox(width: 4),
        // Popup menu for actions
        CustomPopupMenuButton(
          locationId: widget.locationId,
          onDelete: widget.onDelete,
          onAddToSOV: widget.onAddToSOV,
          onAddTag: widget.onAddTag,
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, {bool isCampus = false}) {
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
        Provider.of<MyLocationListProvider>(context, listen: false).showDeleteTagDialog(
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
        children: [
          _buildScoreCard(context, 'Geocoding', widget.geocodingScore),
          _buildScoreCard(context, 'Risk Score', widget.riskScore),
          _buildScoreCard(context, 'Data Completeness', widget.dataCompletenessScore),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, String title, int score) {
    bool isCertified = score == 5; // Logic to check if it shows a certificate.
    List<Color> scoreColors = [
      Colors.grey[300]!, // Default color for unfilled bars
      Colors.red[900]!,  // Dark Red for 1
      Colors.red[300]!,  // Light Red for 2
      Colors.yellow[300]!, // Light Yellow for 3
      Colors.green[300]!,  // Light Green for 4
      Colors.green[600]!,  // Green for 5
    ];

    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.all(8),
      width: 100,
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
        children: [
          Center(
            child: Text(
              title,
              style: typography.InputLabel,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                title == 'Risk Score'
                    ? SvgPicture.asset('assets/images/hazard_icon.svg', width: 24, height: 24)
                    : title == 'Data Completeness'
                    ? SvgPicture.asset('assets/images/data_completeness_icon.svg', width: 24, height: 24)
                    : title == 'Geocoding'
                    ? SvgPicture.asset('assets/images/geocoding_icon.svg', width: 24, height: 24)
                : const SizedBox(),
                SizedBox(width: 4),
                VerticalBarIndicator(score: score), // This will display 4 light green bars and 1 grey bar
                SizedBox(width: 1),
                isCertified
                    ? SvgPicture.asset('assets/images/certified_five.svg', width: 24, height: 24)
                    : Container(
                  margin: EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: scoreColors[score].withOpacity(0.6),
                                      child: Center(child: Text(score.toString(), style: typography.Body1.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),)),
                                    ),
                    ),
              ],
            ),
          ),
          // Display SVG based on the score

          SizedBox(height: 4),

        ],
      ),
    );
  }
}


class CustomPopupMenuButton extends StatelessWidget {

  final String? locationId;
  final void Function(String locationId)? onDelete;
  final void Function(String locationId)? onAddToSOV;
  final void Function(String locationId)? onAddTag;

  const CustomPopupMenuButton({this.onAddToSOV, this.locationId = '', this.onDelete, this.onAddTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _showCustomMenu(context, details.globalPosition);
      },
      child: Icon(
        Icons.more_vert,
        size: 26,
      ),
    );
  }

  void _showCustomMenu(BuildContext context, Offset offset) async {
    var typography = CustomTypography(context);
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 40, // Adjust for width offset if necessary
        offset.dy + 40, // Adjust for height offset if necessary
      ),
      items: onAddToSOV == null?[
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete Location', style: typography.Body1),
        ),
        PopupMenuItem<String>(
          value: 'add_tag',
          child: Text('Add Tag', style: typography.Body1),
        ),
      ]:[
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete Location', style: typography.Body1),
        ),
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
      color: Theme.of(context).cardColor, // Customize the background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    // Handle the selection
    if (result != null) {
      if (result == 'delete') {
        onDelete?.call(locationId??"");
      } else if (result == 'add_sov') {
        print('Add to SOV');
        onAddToSOV?.call(locationId??"");
      } else if (result == 'add_tag') {
        print('Add Tag');
        onAddTag?.call(locationId??"");
      }
    }
  }
}
