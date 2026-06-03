import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';

class RatingWidget extends StatelessWidget {
  final int score; // Rating score from 1 to 5

  const RatingWidget({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular score widget
        Container(
          width: 40, // Adjust size as necessary
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getCircleColor(), // Dynamic color based on score
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        // Background behind stars with overlap
        Transform.translate(
          offset: const Offset(-15, 0), // Shift the stars background towards the circle
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getCircleColor().withAlpha(30), // Lighter color background for the stars
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ), // Rounded corners for the star background
            ),
            child: Row(
              children: [
                SizedBox(width: 8,),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    if (index < score) {
                      return Icon(Icons.star, color: _getStarColor(), size: 18);
                    } else {
                      return Icon(Icons.star_border, color: _getStarColor(), size: 18);
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to determine the circle color based on score
  Color _getCircleColor() {
    if (score == 5) {
      return Colors.green;
    } else if (score >= 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getStarColor() {
    if (score == 5) {
      return Colors.green.shade300; // Light green for stars
    } else if (score >= 3) {
      return Colors.orange.shade300; // Light orange for stars
    } else {
      return Colors.red.shade300; // Light red for stars
    }
  }
}
