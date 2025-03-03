import 'package:flutter/material.dart';

class VerticalBarIndicator extends StatelessWidget {
  final int score; // Score from 1 to 5

  VerticalBarIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    // Define colors for each score level
    List<Color> scoreColors = [
      Colors.grey[300]!, // Default color for unfilled bars
      Colors.red[900]!,  // Dark Red for 1
      Colors.red[300]!,  // Light Red for 2
      Colors.yellow[300]!, // Light Yellow for 3
      Colors.green[300]!,  // Light Green for 4
      Colors.green[600]!,  // Green for 5
    ];

    // Create a list of bars based on the score
    List<Widget> bars = List.generate(5, (index) {
      return Container(
        width: 10,  // Width of each bar
        height: 16,  // Height of each bar
        margin: EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: index < score ? scoreColors[score] : scoreColors[0],
          borderRadius: BorderRadius.circular(4), // Rounded corners for each bar
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: bars,
    );
  }
}
