import 'dart:math';
import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/my_location_list_model.dart';

class AutocompleteOptionsLocation extends StatelessWidget {
  final List<MyLocation> options;
  final ValueChanged<MyLocation> onSelected;
  final bool isLoading;

  const AutocompleteOptionsLocation({
    required this.options,
    required this.onSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    if (isLoading) {
      return Container(
        height: 100.0,
        width: MediaQuery.of(context).size.width - 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh),
        ),
        height: min(52.0 * options.length, MediaQuery.of(context).size.height / 2),
        width: MediaQuery.of(context).size.width - 32,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: options.length,
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            final option = options[index];
            return GestureDetector(
              onTap: () => onSelected(option),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(option.finalAddress?.address ?? 'Unknown Address',
                    style: typography.Subtitle1),
              ),
            );
          },
        ),
      ),
    );
  }
}
