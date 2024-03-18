import 'package:flutter/material.dart';

class InputStyles {
  static const List<BoxShadow> rangeSliderTouchArea = [
    BoxShadow(
      color: Color(0x0000000f),
      blurRadius: 2,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x9ca3af59),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const BoxShadow circlesPieChart = BoxShadow(
    color: Color(0x00000014),
    blurRadius: 24,
    spreadRadius: 0,
  );

  static const TextStyle smallMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const TextStyle smallSemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const TextStyle defaultMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const TextStyle mediumSemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const TextStyle largeMedium = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 20,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const TextStyle largeSemiBold = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    letterSpacing: 0,
    height: 1.0,
    decoration: TextDecoration.none,
  );
}