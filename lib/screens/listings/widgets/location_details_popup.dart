import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/models/my_location_list_model.dart';
import 'package:green/screens/listings/widgets/my_scrollable_scores_widget.dart';
import 'package:green/screens/listings/widgets/vertical_bar_indicator.dart';

import '../../../design_system/primitives/custom_typography.dart';
import 'hazard_section_widget.dart';

class LocationDetailsPopup extends StatelessWidget {
  final String address;
  final String locationId;
  final int geocodingScore;
  final int riskScore;
  final Map<String, Hazard> hazards;
  final List<String> geocodedAt;
  final List<String> occupancy;
  final String? campus;

  LocationDetailsPopup({
    required this.address,
    required this.locationId,
    required this.geocodingScore,
    required this.riskScore,
    required this.hazards,
    required this.geocodedAt,
    required this.occupancy,
    this.campus,
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
            // Address and Location ID
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: typography.InputLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),

                Text(
                  campus??"",
                  style: typography.Body2,
                ),
                SizedBox(height: 8),

                Chip(
                  label: Text('Rented/Leased', style: typography.Caption),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Scores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: MyScrollableScoresWidget(geocodingScore: geocodingScore, riskScore: riskScore),
            ),
            SizedBox(height: 16),

            Text(
              'Hazard Ratings',
              style: typography.Body1,
            ),
            // Hazards Section
            HazardsSection(hazards: hazards),
            SizedBox(height: 16),

            // Information Section
            _buildInformationSection(typography),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add your View Profile action here
                  },
                  child: Text('View Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the new information section
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
              children: [
                Text(entry.key, style: typography.Body2),
                Text(entry.value, style: typography.Body2),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
