import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';

class MessageCard extends StatelessWidget {
  final List<InlineSpan> messageTextSpans;
  final IconData icon;
  final Color iconColor;
  final bool isError; // New optional parameter
  final bool isUpgrade; // New optional parameter

  const MessageCard({
    Key? key,
    required this.messageTextSpans,
    this.icon = Icons.info,
    this.iconColor = Colors.orange,
    this.isError = false, // Default to false
    this.isUpgrade = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    // Conditional styling based on isError
    final Color backgroundColor = isError
        ? AppColors.error.withOpacity(0.1)
        : isUpgrade
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : AppColors.warning.withOpacity(0.1);

    final Color borderColor = isError
        ? AppColors.error.withOpacity(0.3)
        : isUpgrade
            ? AppColors.primaryMain.withOpacity(0.3)
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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isUpgrade
                    ? SizedBox.shrink()
                    : Padding(
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
            !isUpgrade
                ? SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(height: 16),
                      CustomButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.crown_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Upgrade Now',
                                style: typography.ButtonLarge.copyWith(
                                    color: Colors.black)),
                          ],
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Coming soon!', style: typography.Body1),
                            ),
                          );
                        },
                        type: ButtonType.filled,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class MessageCard1 extends StatelessWidget {
  final List<InlineSpan> messageTextSpans;
  final IconData icon;
  final Color iconColor;
  final bool isError; // New optional parameter
  final bool isUpgrade; // New optional parameter

  const MessageCard1({
    Key? key,
    required this.messageTextSpans,
    this.icon = Icons.info,
    this.iconColor = Colors.green,
    this.isError = false, // Default to false
    this.isUpgrade = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    // Conditional styling based on isError
    final Color backgroundColor = isError
        ? AppColors.progressGoodGradient2.withOpacity(0.1)
        : isUpgrade
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : AppColors.progressGoodGradient2.withOpacity(0.1);

    final Color borderColor = isError
        ? AppColors.progressGoodGradient2.withOpacity(0.3)
        : isUpgrade
            ? AppColors.progressGoodGradient2.withOpacity(0.3)
            : AppColors.warning.withOpacity(0.3);

    final Color effectiveIconColor =
        isError ? AppColors.progressGoodGradient2 : iconColor;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isUpgrade
                    ? SizedBox.shrink()
                    : Padding(
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
            !isUpgrade
                ? SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(height: 16),
                      CustomButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.crown_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Upgrade Now',
                                style: typography.ButtonLarge.copyWith(
                                    color: Colors.black)),
                          ],
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Coming soon!', style: typography.Body1),
                            ),
                          );
                        },
                        type: ButtonType.filled,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
//   }
