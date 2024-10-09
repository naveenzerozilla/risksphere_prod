import 'package:flutter/material.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';

class CustomDropdownMenuItem extends StatelessWidget {
  final IconData? icon;
  final String text;
  final String value;
  final bool isVisible;

  const CustomDropdownMenuItem({
    Key? key,
    this.icon,
    required this.text,
    required this.value,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return isVisible
    
        ? DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          if (icon != null) Icon(icon),
          if (icon != null) SizedBox(width: CustomSpacing.two),
          Text(
            text,
            style: typography.BottomNavigationActiveLabel,
          ),
        ],
      ),
    )
        : SizedBox.shrink();
  }
}