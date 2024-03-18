import 'package:flutter/material.dart';

import 'box_shadow_confix.dart';


class DropShadowStyles {
  static  BoxShadowConfig sm = BoxShadowConfig(
    color: Color(0x0000000d),
    x: 0,
    y: 1,
    blur: 2,
    spread: 0,
  );

  static List<BoxShadowConfig> defaultDrop = [
    BoxShadowConfig(
      color: Color(0x0000000f),
      x: 0,
      y: 1,
      blur: 1,
      spread: 0,
    ),
    BoxShadowConfig(
      color: Color(0x0000001a),
      x: 0,
      y: 1,
      blur: 2,
      spread: 0,
    ),
  ];

  static List<BoxShadowConfig> md = [
    BoxShadowConfig(
      color: Color(0x0000000f),
      x: 0,
      y: 2,
      blur: 2,
      spread: 0,
    ),
    BoxShadowConfig(
      color: Color(0x00000012),
      x: 0,
      y: 4,
      blur: 3,
      spread: 0,
    ),
  ];

  static List<BoxShadowConfig> lg = [
    BoxShadowConfig(
      color: Color(0x0000001a),
      x: 0,
      y: 4,
      blur: 3,
      spread: 0,
    ),
    BoxShadowConfig(
      color: Color(0x0000000a),
      x: 0,
      y: 10,
      blur: 8,
      spread: 0,
    ),
  ];

  static List<BoxShadowConfig> xl = [
    BoxShadowConfig(
      color: Color(0x00000014),
      x: 0,
      y: 8,
      blur: 5,
      spread: 0,
    ),
    BoxShadowConfig(
      color: Color(0x00000008),
      x: 0,
      y: 20,
      blur: 13,
      spread: 0,
    ),
  ];

  static BoxShadowConfig xxl = BoxShadowConfig(
    color: Color(0x00000026),
    x: 0,
    y: 25,
    blur: 25,
    spread: 0,
  );
}