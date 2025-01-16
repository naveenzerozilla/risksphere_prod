import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';

class MessageCard extends StatelessWidget {
  final List<InlineSpan> messageTextSpans;
  final IconData icon;
  final Color iconColor;
  final bool isError;  // New optional parameter

  const MessageCard({
    Key? key,
    required this.messageTextSpans,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.orange,
    this.isError = false,  // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    // Conditional styling based on isError
    final Color backgroundColor = isError
        ? AppColors.error.withOpacity(0.1)
        : AppColors.warning.withOpacity(0.1);

    final Color borderColor = isError
        ? AppColors.error.withOpacity(0.3)
        : AppColors.warning.withOpacity(0.3);

    final Color effectiveIconColor = isError ? AppColors.error : iconColor;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 20,
              ),
            ),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    ...messageTextSpans,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
