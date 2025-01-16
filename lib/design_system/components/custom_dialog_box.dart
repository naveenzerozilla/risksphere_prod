import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/components/custom_button.dart';
import '../../constants/enums.dart';

class CustomDialogBox extends StatelessWidget {
  final List<InlineSpan> messageTextSpans;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool isError;
  final bool isDismissible;
  final IconData icon;
  final Color iconColor;

  const CustomDialogBox({
    Key? key,
    required this.messageTextSpans,
    this.buttonText = 'Upgrade now',
    this.onButtonPressed,
    this.isError = false,
    this.isDismissible = true,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    final Color backgroundColor = isError
        ? AppColors.error.withOpacity(0.1)
        : Theme.of(context).colorScheme.surface.withOpacity(0.95);

    final Color borderColor =
    isError ? AppColors.error.withOpacity(0.5) : AppColors.primaryMain;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      backgroundColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 26),
                SizedBox(width: 8),
                Flexible(
                  child: RichText(
                    text: TextSpan(children: messageTextSpans),
                  ),
                ),
                if (isDismissible)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
                type: ButtonType.filled,
                child: Text(buttonText, style: typography.ButtonLarge.copyWith(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
