import 'dart:math';
import 'package:flutter/material.dart';
import 'package:green/models/sov_list_model.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/account_list_model.dart';

class AutocompleteOptionsSovs extends StatelessWidget {
  final List<SovAccount> options;
  final ValueChanged<SovAccount> onSelected;
  final bool isLoading;

  const AutocompleteOptionsSovs({
    required this.options,
    required this.onSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    /*
    Uncomment to show loader
    if (isLoading) {
      return Container(
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
      );
    }*/
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
                child: Text('${option.name??""}', style: typography.Subtitle1),
              ),
            );
          },
        ),
      ),
    );
  }
}
