import 'package:flutter/material.dart';

class RatingHalfStars extends StatelessWidget {
  final double rating; // Change to double for half ratings
  final int maxRating;
  final IconData filledIcon;
  final IconData halfFilledIcon; // Add a half-filled icon
  final IconData unfilledIcon;
  final double iconSize;

  RatingHalfStars({
    this.rating = 0.0, // Default to double
    this.maxRating = 5,
    this.filledIcon = Icons.star,
    this.halfFilledIcon = Icons.star_half, // Default half-filled icon
    this.unfilledIcon = Icons.star_border,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxRating, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(
            filledIcon,
            size: iconSize,
            color: Colors.amber,
          );
        } else if (index < rating) {
          // Half star
          return Icon(
            halfFilledIcon,
            size: iconSize,
            color: Colors.amber,
          );
        } else {
          // Empty star
          return Icon(
            unfilledIcon,
            size: iconSize,
          );
        }
      }),
    );
  }
}
