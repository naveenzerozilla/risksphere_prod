import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';

import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/custom_typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isExpanded: _isExpanded,
        showNotificationDot: _showNotificationDot,
        onExpandPressed: (isExpanded) {
          setState(() {
            _isExpanded = isExpanded;
          });
        },
        onSearchPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
      ),
      drawer: CustomDrawer(),
      body: Center(
        child: Text('Welcome to the Home Screen'),
      ),
    );
  }
}


