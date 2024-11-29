import 'dart:math';
import 'package:flutter/material.dart';
import 'package:green/models/sub_account_list_model.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/account_list_model.dart';

class AutocompleteOptionsSubAccount extends StatelessWidget {
  final List<SubAccounts> options;
  final ValueChanged<SubAccounts> onSelected;
  final bool isLoading;

  const AutocompleteOptionsSubAccount({
    required this.options,
    required this.onSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    if (isLoading) {
      return /*Container(
        height: 100.0,
        width: MediaQuery.of(context).size.width - 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      )*/SizedBox();
    }
    return Material(
      child: Container(
        height: min(52.0 * options.length, MediaQuery.of(context).size.height / 2),
        width: MediaQuery.of(context).size.width - 32,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: options.length,
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            final option = options.elementAt(index);
            return GestureDetector(
              onTap: () => onSelected(option),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('${option.name}', style: typography.Subtitle1),
              ),
            );
          },
        ),
      ),
    );
  }
}
