import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/app_colors.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryMain, primary: AppColors.primaryMain),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(
      useMaterial3: true,
    ).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryMain, primary: AppColors.primaryMain),
    );
  }
}