import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_colors.dart';

class AdaptiveTabBarExample extends StatefulWidget {
  @override
  _AdaptiveTabBarExampleState createState() => _AdaptiveTabBarExampleState();
}

class _AdaptiveTabBarExampleState extends State<AdaptiveTabBarExample>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController.addListener(() {
      setState(() {}); // Update UI on tab change
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
        decoration: BoxDecoration(
         // color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16), // Rounded edges
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: DefaultTabController(
          length: 3,
          child: Builder(builder: (context) {
            return Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  child: TabBar(
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    indicatorPadding: EdgeInsets.symmetric(horizontal: 0),
                    controller: _mainTabController,
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.symmetric(horizontal: 24),
                    indicatorSize: TabBarIndicatorSize.label, // Dynamic size
                    isScrollable: true, // Allow adaptive widths
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryMain.withOpacity(0.16), // Active tab color
                    ),
                    labelColor: AppColors.primaryMain,
                    unselectedLabelColor: Colors.grey,
                    splashBorderRadius: BorderRadius.circular(8),
                    tabs: [
                      Tab(
                        child: _buildTabIcon(
                          context,
                          'assets/images/location_list_icon.svg',
                          'Location List',
                          0,
                          18,
                        ),
                      ),
                      Tab(
                        child: _buildTabIcon(
                          context,
                          'assets/images/map_view_icon.svg',
                          'Map View',
                          1,
                          18,
                        ),
                      ),
                      Tab(
                        child: _buildTabIcon(
                          context,
                          'assets/images/overall_tab_icon.svg',
                          'Overall Score',
                          2,
                          30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      );

  }

  Widget _buildTabIcon(
      BuildContext context, String iconPath, String text, int index, double iconSize) {
    final isSelected = _mainTabController.index == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 0),
   /*   decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppColors.primaryMain.withOpacity(0.1) : Colors.transparent,
      ),*/
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replace Icon with your SVG image logic
          Icon(Icons.star, size: iconSize, color: isSelected ? AppColors.primaryMain : Colors.grey),
          if (isSelected) ...[
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.primaryMain),
            ),
          ],
        ],
      ),
    );
  }
}