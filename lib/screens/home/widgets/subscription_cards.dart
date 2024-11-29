import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/app_colors.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
class SubscriptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconPath;
  final bool isSubscribed;

  const SubscriptionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isSubscribed,
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
          SizedBox(height: 8,),
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
                        style: typography.Body2,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: isSubscribed
                    ? ElevatedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Theme.of(context).disabledColor,),
                          SizedBox(width: 4,),
                          Text(
                                          "Subscribed",
                                          style: typography.Body2.copyWith(
                           color: Theme.of(context).disabledColor,
                          fontWeight: FontWeight.bold,
                                          ),
                                        ),
                        ],
                      ),
                    )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                                        onPressed: () {
                        // Handle subscription logic
                                        },
                                        style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        backgroundColor: AppColors.primaryMain,),
                                        child: Text("Subscribe Now", style: typography.Body1.copyWith(color: Theme.of(context).colorScheme.surface,),
                                      ),
                                    ),
                      ],
                    ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
