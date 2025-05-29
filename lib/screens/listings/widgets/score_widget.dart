import 'package:flutter/material.dart';

class ScoreWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final Color color;

  ScoreWidget({
    required this.icon,
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Text(
              '$label',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                Icons.circle,
                size: 10,
                color: i < score ? color : Colors.grey,
              ),
            SizedBox(width: 8),
            Text(
              '$score',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ],
    );
  }
}
