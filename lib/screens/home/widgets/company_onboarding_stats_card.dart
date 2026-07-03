import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../utils/global_imports.dart';
import '../../../../design_system/components/expandable_card_container.dart';

class CompanyOnboardingStatsCard extends StatefulWidget {
  const CompanyOnboardingStatsCard({super.key});

  @override
  State<CompanyOnboardingStatsCard> createState() => _CompanyOnboardingStatsCardState();
}

class _CompanyOnboardingStatsCardState extends State<CompanyOnboardingStatsCard> {
  bool _isExpanded = false;
  DateTime? _selectedDateCompany;

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

  Widget _companyOnboardingStatsProgressCards(
      CompanyType corporate, DashboardProvider dashboardProvider, CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          corporate.name ?? '',
          style: typography.Body1,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: corporate.count == null
                    ? 0
                    : corporate.count! /
                        (dashboardProvider.dashboardModel?.max ?? 1),
              ),
            ),
            SizedBox(width: CustomSpacing.two),
            Text(
              corporate.count.toString(),
              style: typography.Subtitle1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _collapsedCompanyCardWidget(CustomTypography typography) {
    final title = Text(
      LanguageService.getTranslated(context, 'usermanagement_dash_company_onboarding_status_title'),
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
                            text: _selectedDateCompany == null
                                ? ''
                                : DateFormat('MMMM yyyy')
                                    .format(_selectedDateCompany!)),
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
                            initialDate: _selectedDateCompany ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null &&
                              pickedDate != _selectedDateCompany) {
                            setState(() {
                              _selectedDateCompany = pickedDate;
                            });
                            if (mounted) {
                              Provider.of<DashboardProvider>(context, listen: false)
                                  .getDashboardDataForCompanies(context, pickedDate);
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

  Widget _expandedCompanyOnboardingStatsWidget(DashboardProvider dashboardProvider, CustomTypography typography) {
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
                        'usermanagement_dash_company_onboarding_status_title'),
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
                        text: _selectedDateCompany == null
                            ? ''
                            : DateFormat('MMMM yyyy')
                                .format(_selectedDateCompany!)),
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
                        initialDate: _selectedDateCompany ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null &&
                          pickedDate != _selectedDateCompany) {
                        setState(() {
                          _selectedDateCompany = pickedDate;
                        });
                        if (mounted) {
                          Provider.of<DashboardProvider>(context, listen: false)
                              .getDashboardDataForCompanies(context, pickedDate);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.six),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.two),
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: []..addAll(dashboardProvider
                        .dashboardModel?.companyType
                        ?.map((corporate) {
                      return _companyOnboardingStatsProgressCards(
                          corporate, dashboardProvider, typography);
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
                        dashboardProvider.dashboardModel?.companyPercent ??
                            "0"),
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
      collapsedChild: _collapsedCompanyCardWidget(typography),
      expandedChild: _expandedCompanyOnboardingStatsWidget(dashboardProvider, typography),
    );
  }
}
