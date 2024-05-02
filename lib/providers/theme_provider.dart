import 'package:flutter/material.dart';
import 'package:green/design_system/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/enums.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData);

  ThemeData get getTheme => _themeData;

  setTheme(ThemeData theme) {
    _themeData = theme;
    notifyListeners();
  }



  void setLightTheme() {
    _themeData = AppThemes.lightTheme;
  }

  void setDarkTheme() {
    _themeData = AppThemes.darkTheme;
  }

  void toggleTheme() async {


    if (_themeData == ThemeMode.light) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }

}

