import 'package:flutter/material.dart';

import 'circular_percent_indicator.dart';
import 'score_widget.dart';

class OverallListCard extends StatelessWidget {
  const OverallListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image, 100% Indicator, RS Code
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    'https://via.placeholder.com/50', // Replace with your image
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'C-231',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'RS/00003',
                      style: TextStyle(color: Colors.blue[300]),
                    ),
                  ],
                ),
                Spacer(),
                CircularPercentIndicator(),
                // Replace with your circular progress indicator widget
              ],
            ),
            SizedBox(height: 20),

            // Scores Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScoreWidget(
                  icon: Icons.electric_bolt,
                  label: 'Risk Score',
                  score: 4,
                  color: Colors.green,
                ),
                ScoreWidget(
                  icon: Icons.people_alt,
                  label: 'Occupancy',
                  score: 2,
                  color: Colors.red,
                ),
                ScoreWidget(
                  icon: Icons.construction,
                  label: 'Construction',
                  score: 3,
                  color: Colors.yellow,
                ),
              ],
            ),

            SizedBox(height: 10),

            // Geocoding Score
            ScoreWidget(
              icon: Icons.gps_fixed,
              label: 'Geocoding Score',
              score: 5,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}