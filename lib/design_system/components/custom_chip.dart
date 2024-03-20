import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final Widget label;
  final VoidCallback? onPressed;
  final Widget? avatar;
  final bool selected;
  final Color? selectedColor;
  final Color? backgroundColor;
  final Color? labelColor;

  const CustomChip({
    Key? key,
    required this.label,
    this.onPressed,
    this.avatar,
    this.selected = false,
    this.selectedColor,
    this.backgroundColor,
    this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = selected ? (selectedColor ?? colorScheme.primary) : (backgroundColor ?? colorScheme.surface);
    final textColor = labelColor ?? colorScheme.onSurface;

    return GestureDetector(
      onTap: onPressed,
      child: Chip(
        avatar: avatar, // Set the avatar
        label: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
          ),
          child: label,
        ),
        backgroundColor: chipColor,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}
