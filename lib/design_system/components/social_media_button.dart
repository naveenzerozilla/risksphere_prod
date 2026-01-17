import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../primitives/custom_typography.dart';

class SocialMediaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final String iconPath;

  const SocialMediaButton({
    required this.onPressed,
    required this.buttonText,
    required this.iconPath,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
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
            icon: Container(
              width: 19.60,
              height: 20,
              child: SvgPicture.asset(
                iconPath,
              ),
            ),
            label: Text(
              buttonText,
              style: typography.BottomNavigationActiveLabel.copyWith(
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
