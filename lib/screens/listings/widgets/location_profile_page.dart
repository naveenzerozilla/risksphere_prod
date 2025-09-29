import 'package:flutter/material.dart';
import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:RiskSphere/screens/listings/widgets/my_scrollable_scores_widget.dart';

import '../../../design_system/primitives/custom_typography.dart';
import 'hazard_section_widget.dart';

class LocationProfileDetailsPage extends StatelessWidget {
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
  final bool? hazardProcess;

  const LocationProfileDetailsPage({
    super.key,
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
    this.hazardProcess,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address and Location Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (geocodingScore == 5)
                      ? Image.network(
                    "https://maps.googleapis.com/maps/api/streetview?size=600x300&location=$lat,$long&key=AIzaSyB3NiU-vWDp1TUIARsRKqLBvTGAVcka0yI",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                      : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(
                    imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    'assets/images/building_image.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    address,
                    style: typography.InputLabel,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                label: Text(
                  (rented ?? true) ? 'Rented' : "Owned",
                  style: typography.Caption,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scores Section
            MyScrollableScoresWidget(
              geocodingScore: geocodingScore,
              riskScore: riskScore,
              dataCompleteness: dataCompleteness,
              hazardProcess: hazardProcess,
            ),

            const SizedBox(height: 16),

            // Hazards Section
            Text("Geocoded at", style: typography.Body1),
            HazardsSection(hazards: hazards),

            const SizedBox(height: 16),

            // Info Section
            _buildInformationSection(typography),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection(CustomTypography typography) {
    final information = {
      'Location Geocoded at': geocodedAt.join(', '),
      'Occupancy':
      occupancy.isNotEmpty ? occupancy[0][0].toUpperCase() + occupancy[0].substring(1) : "--",
      'Construction': '--',
      'Floor Area': '--',
      'Year of construction': '--',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: information.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: typography.Body2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: typography.Body2,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
