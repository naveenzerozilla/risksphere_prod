import 'package:flutter/material.dart';

class BoxShadowConfig {
  final Color color;
  final double x;
  final double y;
  final double blur;
  final double spread;

  BoxShadowConfig({
    required this.color,
    required this.x,
    required this.y,
    required this.blur,
    required this.spread,
  });

  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color,
      offset: Offset(x, y),
      blurRadius: blur,
      spreadRadius: spread,
    );
  }
}

class BoxShadowStyles {
  static  BoxShadowConfig sm = BoxShadowConfig(
    color: Color(0x00000008),
    x: 0,
    y: 6,
    blur: 12,
    spread: 0,
  );

  static  BoxShadowConfig defaultBox = BoxShadowConfig(
    color: Color(0x00000014),
    x: 0,
    y: 10,
    blur: 70,
    spread: 0,
  );

  static  BoxShadowConfig md = BoxShadowConfig(
    color: Color(0x00000014),
    x: 0,
    y: 10,
    blur: 40,
    spread: 10,
  );
}


