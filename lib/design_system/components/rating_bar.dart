import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final int rating;
  final int maxRating;
  final IconData filledIcon;
  final IconData unfilledIcon;
  final double iconSize;

  RatingBar({
    this.rating = 0,
    this.maxRating = 5,
    this.filledIcon = Icons.star,
    this.unfilledIcon = Icons.star_border,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxRating, (index) {
        if (index < rating) {
          return Icon(
            filledIcon,
            size: iconSize,
            color: Colors.amber,
          );
        } else {
          return Icon(
            unfilledIcon,
            size: iconSize,
          );
        }
      }),
    );
  }
}
