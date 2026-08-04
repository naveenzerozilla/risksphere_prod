import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../primitives/custom_typography.dart';

class SocialMediaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final String iconPath;
  final bool isLoading;

  const SocialMediaButton({
    required this.onPressed,
    required this.buttonText,
    required this.iconPath,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 19.60,
                    height: 20,
                    child: SvgPicture.asset(
                      iconPath,
                    ),
                  ),
            label: Text(
              isLoading ? "Connecting..." : buttonText,
              style: typography.BottomNavigationActiveLabel.copyWith(
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
