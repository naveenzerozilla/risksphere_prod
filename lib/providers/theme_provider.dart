import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData);

  ThemeData get getTheme => _themeData;

  Future<void> setTheme(ThemeMode themeMode) async {
    print('Setting theme to $themeMode');
    _themeData = themeMode == ThemeMode.light ? AppThemes.lightTheme : AppThemes.darkTheme;
    notifyListeners();
    print('Theme set to ${_themeData.brightness}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark mode
    _themeData = isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    print('Toggling theme');
    bool isDarkMode = prefs.getBool('isDarkMode') ?? true;
print('isDarkMode: $isDarkMode');
    isDarkMode = !isDarkMode;
    print('isDarkMode: $isDarkMode');
    await setTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    print('Theme toggled to ${_themeData.brightness}');
    // notifyListeners() is already called inside setTheme
  }
}
