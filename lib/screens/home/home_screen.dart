import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/components/expandable_card_container.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../design_system/primitives/custom_typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // App Bar
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  // Dashboard Body
  bool isCompanyOnboardingStatsExpanded = false;
  bool isUserOnboardingStatsExpanded = true;
  DateTime? _selectedDateCompany;
  DateTime? _selectedDateUser;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Scaffold(
            backgroundColor: themeProvider.getTheme.colorScheme.background,
            appBar: CustomAppBar(
              isExpanded: _isExpanded,
              showNotificationDot: _showNotificationDot,
              onExpandPressed: (isExpanded) {
                setState(() {
                  _isExpanded = isExpanded;
                });
              },
              onSearchPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            drawer: CustomDrawer(),
            body: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/mesh.png',
                    fit: BoxFit.cover,
                  ),
                ),

                _homeScreenBody(),
              ],
            ),
          );
        }
    );
  }

  _homeScreenBody() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: CustomSpacing.four,
            left: CustomSpacing.four,
            right: CustomSpacing.four),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          Text(
          'Overview',
          style: CustomTypography.H5_Regular,
        ),
        SizedBox(height: CustomSpacing.six),
        _overviewCardHorizontal(
          title: 'Total Corporates',
          amount: '860',
          icon: 'assets/images/total_corporates_list_check.svg',
          bottomWidget: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: CustomSpacing.two),
              Flexible(
                child: Text(
                  '15% increase vs last month',
                  style: CustomTypography.Subtitle1,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: CustomSpacing.four),
        _overviewCardHorizontal(
          title: 'Sign Ups',
          amount: '10,240',
          icon: 'assets/images/sign_ups_users.svg',
          bottomWidget: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: CustomSpacing.two),
              Flexible(
                child: Text(
                  '130% increase vs last month',
                  style: CustomTypography.Subtitle1,
                ),
              ),
            ],
          ),
        ),
        _overviewCardHorizontal(
          title: 'Verification Requests',
          amount: '07',
          icon: 'assets/images/verification_req_checks.svg',
          bottomWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CustomButton(
                  type: ButtonType.outlined,
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See List',
                        style: CustomTypography.Body1,
                      ),
                      SizedBox(width: CustomSpacing.two),
                      Icon(Icons.arrow_forward_ios, size: 14,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: CustomSpacing.four),
        _overviewCardHorizontal(
          title: 'Connection Requests',
          amount: '11',
          icon: 'assets/images/connection_request_people.svg',
          bottomWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //reduce border radius
              Expanded(
                child: CustomButton(
                  type: ButtonType.outlined,
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See List',
                        style: CustomTypography.Body1,
                      ),
                      SizedBox(width: CustomSpacing.two),
                      Icon(Icons.arrow_forward_ios, size: 14,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: CustomSpacing.one),
        ExpandableCardContainer(
          isExpanded: isCompanyOnboardingStatsExpanded,
          collapsedChild: _collapsedCompanyCardWidget(
            title: Text(
              'Company onboarding stats',
              style: CustomTypography.Body1,
            ),
          ),
          expandedChild: _expandedCompanyOnboardingStatsWidget(),
        ),
            SizedBox(height: CustomSpacing.one),
            ExpandableCardContainer(
              isExpanded: isUserOnboardingStatsExpanded,
              collapsedChild: _collapsedUserCardWidget(
                title: Text(
                  'User onboarding stats',
                  style: CustomTypography.Body1,
                ),
              ),
              expandedChild: _expandedUserOnboardingStatsWidget(),
            ),
            SizedBox(height: CustomSpacing.eight),

      ],
    ),)
    ,
    );
  }

  _overviewCard(
      {required String title, required String amount, required String icon, required Row bottomWidget}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: EdgeInsets.all(CustomSpacing.two),
        width: 160,
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular elevated container icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(CustomSpacing.two),
                    child: SvgPicture.asset(
                      icon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                SizedBox(height: CustomSpacing.two),
                Text(
                  title,
                  style: CustomTypography.Body1,
                ),
                SizedBox(height: CustomSpacing.two),
                Text(
                  amount,
                  style: CustomTypography.H4,
                ),
              ],
            ),
            Spacer(
            ),
            Divider(),
            SizedBox(height: CustomSpacing.one),
            bottomWidget,
          ],
        ),
      ),
    );
  }

  _overviewCardHorizontal(
      {required String title, required String amount, required String icon, required Row bottomWidget}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(top: CustomSpacing.two,
                left: CustomSpacing.four,
                right: CustomSpacing.four),
            child: Row(
              children: [
                Row(
                  children: [
                    Card(
                      elevation: 100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(CustomSpacing.two),
                        child: SvgPicture.asset(
                          icon,
                          width: 24,
                          height: 24,

                          colorFilter: ColorFilter.mode(Theme
                              .of(context)
                              .colorScheme
                              .onBackground, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    SizedBox(width: CustomSpacing.two),

                    SizedBox(height: CustomSpacing.two),
                    Text(
                      title,
                      style: CustomTypography.Body1,
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      amount,
                      style: CustomTypography.H4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.black, thickness: 2,),
          SizedBox(height: CustomSpacing.one),
          Container(
              padding: EdgeInsets.only(bottom: CustomSpacing.two,
                  left: CustomSpacing.four,
                  right: CustomSpacing.four),
              child: Center(child: bottomWidget)),
        ],
      ),
    );
  }

  _collapsedCompanyCardWidget({required Text title}) {
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
                    //Circular Icon button
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_outlined, size: 24,),
                      onPressed: () {
                        setState(() {
                          isCompanyOnboardingStatsExpanded =
                          !isCompanyOnboardingStatsExpanded;
                        });
                      },
                    ),
                    SizedBox(width: CustomSpacing.two),
                    title,
                    Spacer(),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),

                // Select Period Datetime Picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true, // Make the field read-only
                        controller: TextEditingController(
                            text: _selectedDateCompany == null
                                ? ''
                                : DateFormat('MMMM yyyy').format(_selectedDateCompany!)),
                        decoration: InputDecoration(
                          labelText: 'Select Period',
                          hintText: 'MM/YYYY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateCompany ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null && pickedDate != _selectedDateCompany) {
                            setState(() {
                              _selectedDateCompany = pickedDate;
                            });
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

  _expandedCompanyOnboardingStatsWidget() {
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
                //Circular Icon button
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_outlined, size: 24,),
                  onPressed: () {
                    setState(() {
                      isCompanyOnboardingStatsExpanded =
                      !isCompanyOnboardingStatsExpanded;
                    });
                  },
                ),
                SizedBox(width: CustomSpacing.two),
                Text(
                  'Company onboarding stats',
                  style: CustomTypography.Body1,
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),

            // Select Period Datetime Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true, // Make the field read-only
                    controller: TextEditingController(
                        text: _selectedDateCompany == null
                            ? ''
                            : DateFormat('MMMM yyyy').format(_selectedDateCompany!)),
                    decoration: InputDecoration(
                      labelText: 'Select Period',
                      hintText: 'MM/YYYY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateCompany ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null && pickedDate != _selectedDateCompany) {
                        setState(() {
                          _selectedDateCompany = pickedDate;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Wrap(
                children: [
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                  companyOnboardingStatsProgressCards(),
                ],
              ),
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '15%',
                    style: CustomTypography.H4.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Text(
                    'Increase in conversions compared to last year',
                    style: CustomTypography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'This year ',
                                style: CustomTypography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                              TextSpan(
                                text: 'is forecasted to increase in your conversion by 0.5% the end of the current year.',
                                style: CustomTypography.Body1,
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

  Widget companyOnboardingStatsProgressCards() {
    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vendor',
                    style: CustomTypography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 0.7,
                        ),
                      ),
                      SizedBox(width: CustomSpacing.two),
                      Text(
                        '860',
                        style: CustomTypography.Subtitle1,
                      ),
                    ],
                  ),
                ],
              );
  }

  _collapsedUserCardWidget({required Text title}) {
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
                    //Circular Icon button
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_outlined, size: 24,),
                      onPressed: () {
                        setState(() {
                          isUserOnboardingStatsExpanded =
                          !isUserOnboardingStatsExpanded;
                        });
                      },
                    ),
                    SizedBox(width: CustomSpacing.two),
                    title,
                    Spacer(),
                  ],
                ),
                SizedBox(height: CustomSpacing.two),

                // Select Period Datetime Picker
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true, // Make the field read-only
                        controller: TextEditingController(
                            text: _selectedDateUser == null
                                ? ''
                                : DateFormat('MMMM yyyy').format(_selectedDateUser!)),
                        decoration: InputDecoration(
                          labelText: 'Select Period',
                          hintText: 'MM/YYYY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateUser ?? DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null && pickedDate != _selectedDateUser) {
                            setState(() {
                              _selectedDateUser = pickedDate;
                            });
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

  _expandedUserOnboardingStatsWidget() {
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
                //Circular Icon button
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_outlined, size: 24,),
                  onPressed: () {
                    setState(() {
                      isUserOnboardingStatsExpanded =
                      !isUserOnboardingStatsExpanded;
                    });
                  },
                ),
                SizedBox(width: CustomSpacing.two),
                Text(
                  'User onboarding stats',
                  style: CustomTypography.Body1,
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.two),

            // Select Period Datetime Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true, // Make the field read-only
                    controller: TextEditingController(
                        text: _selectedDateUser == null
                            ? ''
                            : DateFormat('MMMM yyyy').format(_selectedDateUser!)),
                    decoration: InputDecoration(
                      labelText: 'Select Period',
                      hintText: 'MM/YYYY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateUser ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 10),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate != null && pickedDate != _selectedDateUser) {
                        setState(() {
                          _selectedDateUser = pickedDate;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Wrap(
                children: [
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                  userOnboardingStatsProgressCards(),
                ],
              ),
            ),
            SizedBox(height: CustomSpacing.four),
            Container(
              margin: EdgeInsets.symmetric(horizontal: CustomSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '130%',
                    style: CustomTypography.H4.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Text(
                    'Increase in conversions compared to last year',
                    style: CustomTypography.Body1,
                  ),
                  SizedBox(height: CustomSpacing.two),
                  Row(
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'This year ',
                                style: CustomTypography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                              TextSpan(
                                text: 'is forecasted to increase in your conversion by 0.5% the end of the current year.',
                                style: CustomTypography.Body1,
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

  Widget userOnboardingStatsProgressCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Admin',
          style: CustomTypography.Body1,
        ),
        SizedBox(height: CustomSpacing.two),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: 0.5,
              ),
            ),
            SizedBox(width: CustomSpacing.two),
            Text(
              '860',
              style: CustomTypography.Subtitle1,
            ),
          ],
        ),
      ],
    );
  }



  List<String> generateOptions() {
    List<String> options = [];
    final currentDate = DateTime.now();
    final formatter = DateFormat('MMMM yyyy');

    for (int i = 0; i < 120; i++) {
      final date = currentDate.subtract(Duration(days: i * 30));
      options.add(formatter.format(date));
    }

    return options;
  }
}


