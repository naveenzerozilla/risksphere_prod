import 'package:flutter/material.dart';

import '../primitives/app_colors.dart';
import '../primitives/custom_typography.dart';

import 'package:flutter/material.dart';
import '../primitives/app_colors.dart';
import '../primitives/custom_typography.dart';

class CustomGradientCircularProgressBar extends StatelessWidget {
  final double strokeWidth;
  final double value;
  final double radius;
  final double fontSize;
  final String text;
  final Color textColor;
  final bool showText;

  CustomGradientCircularProgressBar({
    this.strokeWidth = 10.0,
    this.value = 0.0,
    this.radius = 50.0,
    this.fontSize = 20.0,
    this.text = "",
    this.textColor = Colors.black,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    // Determine colors based on value
    Color backgroundColor1;
    Color backgroundColor2;
    Color valueColor1;
    Color valueColor2;

    if (value >= 100) {
      backgroundColor1 = AppColors.progressExcellentBackgroundGradient1;
      backgroundColor2 = AppColors.progressExcellentBackgroundGradient2;
      valueColor1 = AppColors.progressExcellentGradient1;
      valueColor2 = AppColors.progressExcellentGradient2;
    } else if (value <= 20) {
      backgroundColor1 = AppColors.progressBadBackgroundGradient1;
      backgroundColor2 = AppColors.progressBadBackgroundGradient2;
      valueColor1 = AppColors.progressBadGradient1;
      valueColor2 = AppColors.progressBadGradient2;
    } else {
      backgroundColor1 = AppColors.progressGoodBackgroundGradient1;
      backgroundColor2 = AppColors.progressGoodBackgroundGradient2;
      valueColor1 = AppColors.progressGoodGradient1;
      valueColor2 = AppColors.progressGoodGradient2;
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        children: <Widget>[
          Center(
            child: Container(
              width: radius * 2,
              height: radius * 2,
              child: CustomPaint(
                painter: GradientArcPainter(
                  backgroundColor1: backgroundColor1,
                  valueColor1: valueColor1,
                  backgroundColor2: backgroundColor2,
                  valueColor2: valueColor2,
                  strokeWidth: strokeWidth,
                  value: value,
                ),
              ),
            ),
          ),
          Center(
            child: showText
                ? Text(
              text,
              style: typography.Subtitle2.copyWith(
                color: textColor,
              ),
            )
                : Container(),
          ),
        ],
      ),
    );
  }
}

class GradientArcPainter extends CustomPainter {
  final double strokeWidth;
  final double value;
  final Color backgroundColor1;
  final Color valueColor1;
  final Color backgroundColor2;
  final Color valueColor2;

  GradientArcPainter({
    required this.strokeWidth,
    required this.value,
    required this.backgroundColor1,
    required this.valueColor1,
    required this.backgroundColor2,
    required this.valueColor2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double startAngle = -3 * 3.14 / 4;
    final double sweepAngle = 3.14 * 2 * (value / 100);

    // Paint the background arc
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3) // Adjust the background color as needed
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, startAngle, 3.14 * 2, false, backgroundPaint);

    // Paint the gradient arc
    final Gradient gradient = LinearGradient(
      colors: [backgroundColor1, valueColor1, backgroundColor2, valueColor2],
      stops: [0.0, 0.5, 0.5, 1.0],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
