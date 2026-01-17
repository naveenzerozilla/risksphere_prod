import 'package:flutter/material.dart';

class VerticalBarIndicator extends StatelessWidget {
  final dynamic score; // 1, 2, 2.5, 3.5, 4, 4.5

  const VerticalBarIndicator({super.key, required this.score});

  static final List<Color> scoreColors = [
    Colors.grey,            // 0 (unused)
    Colors.red[900]!,       // 1
    Colors.red[300]!,       // 2
    Colors.yellow[300]!,    // 3
    Colors.green[300]!,     // 4
    Colors.green[600]!,     // 5
  ];

  @override
  Widget build(BuildContext context) {
    final double value = score is num
        ? score.toDouble()
        : double.tryParse(score.toString()) ?? 1.0;

    final int filledBars = value.floor();
    final bool hasHalfBar = (value - filledBars) >= 0.5;

    final int colorIndex = value.ceil().clamp(1, 5);
    final Color activeColor = scoreColors[colorIndex];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < filledBars) {
          return _fullBar(activeColor);
        } else if (index == filledBars && hasHalfBar) {
          return _halfBar(activeColor);
        } else {
          return _emptyBar();
        }
      }),
    );
  }

  Widget _fullBar(Color color) {
    return _bar(color);
  }

  Widget _emptyBar() {
    return _bar(Colors.grey[300]!);
  }

  Widget _halfBar(Color color) {
    return Container(
      width: 12,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _bar(Color color) {
    return Container(
      width: 12,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}


// class VerticalBarIndicator extends StatelessWidget {
//   final dynamic score;
//
//   VerticalBarIndicator({required this.score});
//
//   @override
//   Widget build(BuildContext context) {
//     // Define colors for each score level
//     List<Color> scoreColors = [
//       Colors.grey[300]!, // Default color for unfilled bars
//       Colors.red[900]!,  // Dark Red for 1
//       Colors.red[300]!,  // Light Red for 2
//       Colors.yellow[300]!, // Light Yellow for 3
//       Colors.green[300]!,  // Light Green for 4
//       Colors.green[600]!,  // Green for 5
//     ];
//
//     // Create a list of bars based on the score
//     List<Widget> bars = List.generate(5, (index) {
//       return Container(
//         width: 10,  // Width of each bar
//         height: 16,  // Height of each bar
//         margin: EdgeInsets.symmetric(horizontal: 1),
//         decoration: BoxDecoration(
//           color: index < score ? scoreColors[score] : scoreColors[0],
//           borderRadius: BorderRadius.circular(4), // Rounded corners for each bar
//         ),
//       );
//     });
//
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: bars,
//     );
//   }
// }
