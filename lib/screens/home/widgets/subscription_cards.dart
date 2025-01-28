import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../listings/widgets/message_card.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconPath;
  final bool isSubscribed;
  final Function()? onSubscribe;

  const SubscriptionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isSubscribed,
    this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 8,
          ),
          // Top Row: Icon and Title
          Container(
            padding: EdgeInsets.symmetric(
              vertical: CustomSpacing.two,
              horizontal: CustomSpacing.four,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Icon Container
                Card(
                  elevation: 100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(CustomSpacing.two),
                    child: SvgPicture.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onBackground,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: typography.Body1,
                      ),
                      SizedBox(height: CustomSpacing.two),
                      Text(
                        description,
                        style: typography.Body2.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            thickness: 2,
          ),

          // Bottom Section: Subscribed or Subscribe Button
          Consumer<UserProfileProvider>(builder: (context, userProfile, child) {
            final trialStatus = userProfile.trialInfo['status'] ?? '';
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: isSubscribed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: onSubscribe,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                backgroundColor: Colors.amber,
                              ),
                              child: Text(
                                trialStatus.isEmpty?"  Unsubscribe  ": trialStatus.toLowerCase() == 'expired'?"  Upgrade Now  ":"  Trial Activated  ",
                                style: typography.Body1.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: onSubscribe,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                backgroundColor: AppColors.primaryMain,
                              ),
                              child: Text(
                                //"Subscribe Now",
                                trialStatus.isEmpty?"  Subscribe Now  ": trialStatus.toLowerCase() == 'expired'?"  Upgrade Now  ":"  Try now!  ",
                                style: typography.Body1.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          }),

          Consumer<UserProfileProvider>(
            builder: (context, userProfile, child) {
              final trialStatus = userProfile.trialInfo['status'] ?? '';
              if (trialStatus.isEmpty) {
                return const SizedBox();
              }
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 12),
                    child: MessageCard(
                      messageTextSpans: [
                        TextSpan(
                          text: "For yearly alerts subscription.",
                          style: typography.Body2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                        TextSpan(
                          text: " Upgrade Now!",
                          style: typography.Body2.copyWith(
                            color: AppColors.primaryMain,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Handle subscription logic
                              //Coming soon Snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Coming soon!',
                                      style: typography.Body1.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      )),
                                ),
                              );
                            },
                        ),
                      ],
                    )),
              );
            },
          ),
        ],
      ),
    );
  }
}
