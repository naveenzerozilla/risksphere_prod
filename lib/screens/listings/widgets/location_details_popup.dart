import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:RiskSphere/screens/listings/location_profile.dart';
import 'package:RiskSphere/screens/listings/widgets/my_scrollable_scores_widget.dart';

import '../../../design_system/primitives/custom_typography.dart';
import 'hazard_section_widget.dart';

class LocationDetailsPopup extends StatelessWidget {
  final String? lat;
  final String? long;
  final String? imageUrl;
  final String address;
  final String locationId;
  final int geocodingScore;
  final dynamic riskScore;
  final dynamic dataCompleteness;
  final Map<String, HazardDetails> hazards;
  final List<String> geocodedAt;
  final List<String> occupancy;

  final String? accountId;
  final String? accountName;
  final String? subAccountId;
  final String? subAccountName;
  final String? sovId;
  final String? sovName;
  final String? campus;
  final bool? rented;
  final bool? hideNavigation;
  final bool? hazardProcess;

  LocationDetailsPopup({
    this.lat,
    this.long,
    this.imageUrl,
    required this.address,
    required this.locationId,
    required this.geocodingScore,
    required this.riskScore,
    required this.dataCompleteness,
    required this.hazards,
    required this.geocodedAt,
    required this.occupancy,
    this.accountId,
    this.accountName,
    this.subAccountId,
    this.subAccountName,
    this.sovId,
    this.sovName,
    this.campus,
    this.rented,
    this.hideNavigation = false,
    this.hazardProcess,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // Address and Location Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (geocodingScore == 5)
                          ? Image.network(
                              "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=${lat},${long}&key=AIzaSyB3NiU-vWDp1TUIARsRKqLBvTGAVcka0yI",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : (imageUrl != null && imageUrl!.isNotEmpty)
                              ? Image.network(
                                  imageUrl!,
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

                    Container(
                      width: 180,
                      child: Text(
                        address,
                        textAlign: TextAlign.right,
                        style: typography.InputLabel,
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(
                        (rented ?? true) ? 'Rented' : "owned",
                        style: typography.Caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Scores Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: MyScrollableScoresWidget(
                geocodingScore: geocodingScore,
            riskScore: (int.parse(riskScore.toString()) == 0) ? 5 : riskScore,
                dataCompleteness: dataCompleteness,
                hazardProcess: hazardProcess,
              ),
            ),
            SizedBox(height: 16),

            // Hazard Ratings Section
            Text(
              'Geocoded at',
              style: typography.Body1,
            ),

            HazardsSection(hazards: hazards),
            SizedBox(height: 16),

            // Information Section
            // _buildInformationSection(typography),

            // Navigation and Close Buttons
            SizedBox(height: 16),
            hideNavigation ?? false
                ? _buildCloseButton(context, typography)
                : _buildNavigationButtons(context, typography),
          ],
        ),
      ),
    );
  }

  // Information Section Widget
  Widget _buildInformationSection(CustomTypography typography) {
    final information = {
      'Location Geocoded at': geocodedAt.join(', '),
      'Occupancy': occupancy[0][0].toUpperCase() + occupancy[0].substring(1),
      'Construction': '--',
      'Floor Area': '--',
      'Year of construction': '--',
    };

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: information.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: typography.Body2),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    entry.value,
                    style: typography.Body2,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Close Button for Hide Navigation = true
  Widget _buildCloseButton(BuildContext context, CustomTypography typography) {
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
              width: 2), // Change border color and width
        ),
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Close',
          style: typography.ButtonLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // Navigation Buttons for Hide Navigation = false
  Widget _buildNavigationButtons(
      BuildContext context, CustomTypography typography) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: typography.ButtonLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => LocationProfile(
        //           accountId: accountId ?? "",
        //           accountName: accountName ?? "",
        //           subAccountId: subAccountId ?? "",
        //           subAccountName: subAccountName ?? "",
        //           sovId: sovId ?? "",
        //           sovName: sovName ?? "",
        //           page: "0",
        //           totalPages: "0",
        //           searchQuery: "",
        //         ),
        //       ),
        //     );
        //   },
        //   child: Text(
        //     'View Profile',
        //     style: typography.ButtonLarge.copyWith(
        //       color: Theme.of(context).colorScheme.onSurface,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
