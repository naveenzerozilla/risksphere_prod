import 'package:flutter/material.dart';
import '../../../utils/global_imports.dart';

class OverviewCardHorizontal extends StatelessWidget {
  final String title;
  final String amount;
  final String icon;
  final Widget bottomWidget;

  const OverviewCardHorizontal({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);
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
            padding: EdgeInsets.only(
                top: CustomSpacing.two,
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
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onBackground,
                              BlendMode.srcIn),
                        ),
                      ),
                    ),
                    SizedBox(height: CustomSpacing.four),
                    Text(
                      title,
                      style: typography.Body1,
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      amount,
                      style: typography.H4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.black,
            thickness: 2,
          ),
          SizedBox(height: CustomSpacing.one),
          Container(
              padding: EdgeInsets.only(
                  bottom: CustomSpacing.two,
                  left: CustomSpacing.four,
                  right: CustomSpacing.four),
              child: Center(child: bottomWidget)),
        ],
      ),
    );
  }
}
