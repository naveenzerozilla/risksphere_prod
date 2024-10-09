import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../primitives/app_colors.dart';

class ThemeSwitcher extends StatefulWidget {
  @override
  _ThemeSwitcherState createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> {
  bool isDarkMode = false;

  initState() {
    super.initState();
    var provider = Provider.of<ThemeProvider>(context, listen: false);
    isDarkMode = provider.getTheme.brightness == Brightness.dark;
    print('isDarkMode: $isDarkMode');
    print('isDarkMode: ${Provider.of<ThemeProvider>(context, listen: false).getTheme.brightness}');

  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            isDarkMode = !isDarkMode;
          });
          await Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 70,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.0),
            color: isDarkMode ? AppColors.paperElavation25 : Colors.grey[300],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 2.5,
                left: isDarkMode ? 35.0 : 0.0,
                right: isDarkMode ? 0.0 : 35.0,
                child: CircleAvatar(
                  radius: 15.0,
                  backgroundColor: isDarkMode ? Colors.grey[600] : Colors.white,
                  child: Icon(
                    isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: isDarkMode ? Colors.white : Colors.amber,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: 18,
                  color: isDarkMode ? Colors.grey : Colors.amber,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Icon(
                  Icons.nightlight_round,
                  size: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

