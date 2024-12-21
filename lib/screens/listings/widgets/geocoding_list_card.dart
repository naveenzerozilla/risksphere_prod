
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/screens/listings/widgets/score_bar.dart';

import '../../../design_system/primitives/custom_typography.dart';

class GeoCodingListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Left Section: Badge Icon and Image
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/certified.svg',
                  semanticsLabel: 'Location',
                ),
                SizedBox(width: 8),
                ClipOval(
                  child: Image.asset(
                    'assets/images/location_thumbnail.png',
                    // Replace with your image
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            SizedBox(width: 10),

            // Middle Section: RS Code and C-231
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'RS/00002',
                        style: TextStyle(color: Colors.blue[300], fontSize: 16),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Chip(
                    backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                    label: Text(
                      'C-231',
                      style: CustomTypography(context).Body2,
                    ),
                  ),
                ],
              ),
            ),

            // Right Section: Geocoding Score
            Row(
              children: [
                ScoreBar(),
                SizedBox(width: 5),
                Text(
                  '5',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],
            ),

            // Optional: More icon on the right
            SizedBox(width: 10),
            Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
