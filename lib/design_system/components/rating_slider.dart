import 'package:flutter/material.dart';

class RatingSlider extends StatelessWidget {
  final int progress;
  final int total;
  final Color thumbColor;
  final Color progressColor;
  final double progressHeight;
  final Color textColor;
  final double width;

  const RatingSlider({
    Key? key,
    required this.progress,
    required this.total,
    this.thumbColor = Colors.blue,
    this.progressColor = Colors.blue,
    this.progressHeight = 8.0,
    this.textColor = Colors.black,
    this.width = 250.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progressPercentage = (progress / total) * 100;
    return Container(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: progressHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              height: progressHeight,
              width: width * (progressPercentage / 100),
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Positioned(
            top: -10,
            left: (width / 2)-10, // Center the thumb
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$progress/$total',
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

