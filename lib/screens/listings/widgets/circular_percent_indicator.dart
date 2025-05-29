import 'package:flutter/material.dart';

class CircularPercentIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: 1.0, // This should be in the range of 0.0 to 1.0
                strokeWidth: 5,
                color: Colors.green,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
