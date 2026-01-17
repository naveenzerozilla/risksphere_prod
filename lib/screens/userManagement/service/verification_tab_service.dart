import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../service/language_service.dart';

import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';
import '../../listings/widgets/message_card.dart';

class VerificationTabsService {
  final List<Tab> _verificationTabs = [];

  List<Tab> verificationTabs(BuildContext context) {
    var typography = CustomTypography(context);

    return _verificationTabs.isEmpty
        ? [
      // Corporate Verification Tab
      Tab(
        child: Text(

          LanguageService.getTranslated(
              context, 'usermanagement_corporate_verification_tab'),
          style: typography.BottomNavigationActiveLabel,
        ),
      ),

      // User Verification Tab
      Tab(
        child: Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
            final trialStatus =
                userProfileProvider.trialInfo['status'] ?? '';
            return IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User Verification Text
                  Text(
                    LanguageService.getTranslated(
                        context, 'user_verification'),
                    style: typography.BottomNavigationActiveLabel,
                  ),
                  if (trialStatus.isNotEmpty)
                    SizedBox(width: 8.0),
                  if (trialStatus.isNotEmpty)
                  // Trial Badge
                    InkWell(
                      onTap: () {
                        // Show trial info dialog
                        showDialog(
                          context: context,
                          barrierColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                          builder: (BuildContext context) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                                MessageCard(
                                  isUpgrade: true,
                                  messageTextSpans: [
                                    TextSpan(
                                      text: 'During the trial period you can accept ',
                                      style: CustomTypography(context).Body1,
                                    ),
                                    TextSpan(
                                      text: '“maximum 2 users”',
                                      style: CustomTypography(context).Body1.copyWith(
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                      ' requests. Upgrade now to add more!',
                                      style: CustomTypography(context).Body1,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(

                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Trial",
                                style: typography.BottomNavigationActiveLabel
                                    .copyWith(color: AppColors.warning),
                              ),
                              SizedBox(width: 4.0),
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 16.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ]
        : _verificationTabs;
  }

  // Dynamically update the tabs
  void setVerificationTabs(BuildContext context, List<Tab> newTabs) {
    _verificationTabs.clear();
    _verificationTabs.addAll(newTabs);
  }
}

