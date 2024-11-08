import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/my_location_list_model.dart';

class HazardsSection extends StatelessWidget {
  final Map<String, Hazard> hazards;
  final List<Color> scoreColors = [
    Colors.grey[300]!,
    Colors.red[900]!,
    Colors.red[300]!,
    Colors.yellow[300]!,
    Colors.green[300]!,
    Colors.green[600]!,
  ];

  HazardsSection({required this.hazards});

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    final ScrollController _scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true, // Always visible scrollbar
        child: Column(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: hazards.entries.map((entry) {
                  final hazardName = entry.key;
                  final hazard = entry.value;
                  final rating = hazard.rating ?? 0;
                  final color = rating >= 0 && rating < scoreColors.length
                      ? scoreColors[rating]
                      : Colors.grey;

                  return Container(
                    width: 100,
                    margin: EdgeInsets.symmetric(horizontal: 8), // Add spacing between boxes
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Display Hazard Rating with background color based on score
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color, // Color based on hazard rating
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rating != 0 ? rating.toString() : 'N/A',
                            style: typography.InputLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Display Hazard Name
                        Text(
                          hazardName,
                          style: typography.InputLabel,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
