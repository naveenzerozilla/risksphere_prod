import 'package:flutter/material.dart';

import '../../constants/enums.dart';

class CustomButton extends StatelessWidget {
  final ButtonType type;
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final MainAxisAlignment iconAlignment;

  const CustomButton({
    Key? key,
    required this.type,
    required this.onPressed,
    required this.child,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.iconAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = child;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (icon != null) {
      List<Widget> children = [];

      if (iconAlignment == MainAxisAlignment.start) {
        children.addAll([
          Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
          const SizedBox(width: 8.0),
          Expanded(child: buttonChild),
        ]);
      } else {
        children.addAll([
          Expanded(child: buttonChild),
          const SizedBox(width: 8.0),
          Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ]);
      }

      buttonChild = Row(
        mainAxisAlignment: iconAlignment,
        children: children,
      );
    }

    switch (type) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onPrimary, backgroundColor: colorScheme.primary, elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          child: buttonChild,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            side: BorderSide(color: colorScheme.primary),
          ),
          child: buttonChild,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary, shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          child: buttonChild,
        );
      case ButtonType.filled:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onPrimary, backgroundColor: colorScheme.primary, elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          child: buttonChild,
        );
      case ButtonType.tonal:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onPrimary, backgroundColor: colorScheme.primary.withOpacity(0.12), elevation: 1.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          child: buttonChild,
        );
      default:
        throw Exception('Unsupported button type');
    }
  }
}
