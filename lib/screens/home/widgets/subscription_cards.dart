import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../listings/widgets/message_card.dart';
import '../../payments/purchase_license.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconPath;
  final bool isSubscribed;
  final Function()? onSubscribe;
  final bool isPgAdmin;
  final bool isAdmin;
  final bool isSuperAdmin;

  const SubscriptionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isSubscribed,
    this.onSubscribe,
    required this.isPgAdmin,
    required this.isAdmin,
    required this.isSuperAdmin,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Icon Container
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(CustomSpacing.two),
                  child: CachedNetworkImage(
                    imageUrl: iconPath,
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                    height: 50,
                    width: 50,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                SizedBox(width: CustomSpacing.two),
                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.Body1,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(title.toString() ==
                                            "Hurricane (Kinetic Analysis Corporation)"
                                        ? "Hurricane Event Monitoring Subscription"
                                        : title.toString() ==
                                                "Earthquake Event Monitoring Subscription"
                                            ? "Earthquake Event Monitoring Subscription"
                                            : title.toString()),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title.toString() ==
                                                "Hurricane (Kinetic Analysis Corporation)"
                                            ? "Get real-time hurricane alerts and automated tracking."
                                            : "The Earthquake Event Monitoring Subscription keeps you updated with timely alerts on seismic activity."),
                                        SizedBox(height: 8),
                                        Text("Key Information:"),
                                        SizedBox(height: 10),
                                        _buildBulletPoint(
                                            "Activation: Monitoring begins 24 hours after subscribing."),
                                        _buildBulletPoint(title.toString() ==
                                                "Hurricane (Kinetic Analysis Corporation)"
                                            ? "Automatic Tracking: New locations added start monitoring within 24 hours."
                                            : "Automatic Location Tracking: New locations monitoring starts after 24 hours."),
                                        _buildBulletPoint(
                                            "Event Alerts: Alerts every 6 hours on potential impacts."),
                                        SizedBox(height: 8),
                                        Text("Subscribe now."),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("OK"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Icon(Icons.info, size: 20),
                          ),
                        ],
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
          if (Platform.isAndroid) ...[
            Consumer<UserProfileProvider>(
                builder: (context, userProfile, child) {
              final trialStatus = userProfile.trialInfo['status'] ?? '';
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: isSubscribed
                        ? isPgAdmin || isAdmin || isSuperAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  isPgAdmin || isAdmin || isSuperAdmin
                                      ? ElevatedButton(
                                          onPressed: onSubscribe,
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            backgroundColor: Colors.grey,
                                          ),
                                          child: Text(
                                            isSubscribed == true
                                                ? "subscribed"
                                                : "Try now",
                                            style: typography.Body1.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: onSubscribe,
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            backgroundColor: Colors.amber,
                                          ),
                                          child: Text(
                                            trialStatus.isEmpty
                                                ? "  Unsubscribe  "
                                                : trialStatus.toLowerCase() ==
                                                        'expired'
                                                    ? "  Upgrade Now  "
                                                    : "  Trial Activated",
                                            style: typography.Body1.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                          ),
                                        ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: onSubscribe,
                                child: Text(
                                  "unSubscribed",
                                  // style: typography.Body1.copyWith(
                                  //   color: Theme.of(context).colorScheme.surface,
                                  // ),
                                ),
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
                                  "Subscribe Now",
                                  style: typography.Body1.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              )
                            ],
                          ),
                  ),
                ],
              );
            }),
            isSubscribed == true
                ? Container()
                : Consumer<UserProfileProvider>(
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
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  PurchaseLicensePage()));
                                    },
                                ),
                              ],
                            )),
                      );
                    },
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
