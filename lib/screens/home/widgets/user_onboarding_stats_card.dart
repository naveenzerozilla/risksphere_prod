import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../utils/global_imports.dart';
import '../../../../design_system/components/expandable_card_container.dart';

class UserOnboardingStatsCard extends StatefulWidget {
  const UserOnboardingStatsCard({super.key});

  @override
  State<UserOnboardingStatsCard> createState() => _UserOnboardingStatsCardState();
}

class _UserOnboardingStatsCardState extends State<UserOnboardingStatsCard> {
  bool _isExpanded = true; // Starts as expanded by default
  DateTime? _selectedDateUser;

  String _getPercentConversions(String percent) {
    String rolePercentText = percent;

    // Remove '%' sign but keep negative signs and decimal points
    String rolePercentCleaned =
        rolePercentText.replaceAll(RegExp(r'[^0-9.-]'), '');

    if (rolePercentCleaned.isEmpty) {
      rolePercentCleaned = "0";
    }

    double rolePercent = double.tryParse(rolePercentCleaned) ?? 0.0;

    String changeText;
    if (rolePercent < 0) {
      rolePercent = -rolePercent; // Make it positive
      changeText =
          "${rolePercent.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_decrease_cap')}";
    } else {
      changeText =
          "${rolePercent.toStringAsFixed(2)}% ${LanguageService.getTranslated(context, 'usermanagement_dash_increase_cap')}";
    }

    return changeText;
  }

  Widget _userOnboardingStatsProgressCards(
      DashboardRoles role, DashboardProvider dashboardProvider, CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          role.name ?? '',
          style: typography.Body1,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: role.count == null
                    ? 0
                    : role.count! /
                        (dashboardProvider.dashboardModel?.max ?? 1),
              ),
            ),
            SizedBox(width: CustomSpacing.two),
            Text(
              role.count.toString(),
              style: typography.Subtitle1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _collapsedUserCardWidget(CustomTypography typography) {
    final title = Text(
      LanguageService.getTranslated(context, 'usermanagement_dash_user_on_boarding_status'),
      style: typography.Body1,
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_outlined,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                    SizedBox(width: CustomSpacing.two),
                    Flexible(child: title),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),

                // Select Period Datetime Picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: _selectedDateUser == null
                                ? ''
                                : DateFormat('MMMM yyyy')
                                    .format(_selectedDateUser!)),
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context,
                              'usermanagement_dash_select_period_label'),
                          hintText: LanguageService.getTranslated(
                              context, 'usermanagement_dash_calendar'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? pickedDate = await showMonthPicker(
                            context: context,
                            initialDate: _selectedDateUser ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null &&
                              pickedDate != _selectedDateUser) {
                            setState(() {
                              _selectedDateUser = pickedDate;
                            });
                            if (mounted) {
                              Provider.of<DashboardProvider>(context, listen: false)
                                  .getDashboardDataForRoles(context, pickedDate);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedUserOnboardingStatsWidget(DashboardProvider dashboardProvider, CustomTypography typography) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_up_outlined,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                SizedBox(width: CustomSpacing.two),
                Flexible(
                  child: Text(
                    LanguageService.getTranslated(context,
                        'usermanagement_dash_user_on_boarding_status'),
                    style: typography.Body1,
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),

            // Select Period Datetime Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: _selectedDateUser == null
                            ? ''
                            : DateFormat('MMMM yyyy')
                                .format(_selectedDateUser!)),
                    decoration: InputDecoration(
                      labelText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_select_period_label'),
                      hintText: LanguageService.getTranslated(
                          context, 'usermanagement_dash_calendar'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showMonthPicker(
                        context: context,
                        initialDate: _selectedDateUser ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null &&
                          pickedDate != _selectedDateUser) {
                        setState(() {
                          _selectedDateUser = pickedDate;
                        });
                        if (mounted) {
                          Provider.of<DashboardProvider>(context, listen: false)
                              .getDashboardDataForRoles(context, pickedDate);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: []..addAll(dashboardProvider.dashboardModel?.roles?.map((role) {
                      return _userOnboardingStatsProgressCards(
                          role, dashboardProvider, typography);
                    }) ??
                    []),
              ),
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPercentConversions(
                        dashboardProvider.dashboardModel?.rolePercent ?? "0"),
                    style: typography.H4.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Text(
                    LanguageService.getTranslated(
                        context, 'usermanagement_dash_conversions'),
                    style: typography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_1'),
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                              TextSpan(
                                text: LanguageService.getTranslated(context,
                                    'usermanagement_dash_forcast_part_2'),
                                style: typography.Body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return ExpandableCardContainer(
      isExpanded: _isExpanded,
      collapsedChild: _collapsedUserCardWidget(typography),
      expandedChild: _expandedUserOnboardingStatsWidget(dashboardProvider, typography),
    );
  }
}
