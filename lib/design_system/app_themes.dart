import 'package:flutter/material.dart';
import 'package:RiskSphare/design_system/primitives/app_colors.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryMain, primary: AppColors.primaryMain),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorSchemeSeed: AppColors.primaryMain,
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}