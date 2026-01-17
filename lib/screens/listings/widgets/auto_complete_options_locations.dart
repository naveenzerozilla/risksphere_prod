import 'dart:math';
import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/my_location_list_model.dart';

class AutocompleteOptionsLocation extends StatefulWidget {
  final List<MyLocation> options;
  final ValueChanged<MyLocation> onSelected;
  final bool isLoading;

  const AutocompleteOptionsLocation({
    required this.options,
    required this.onSelected,
    required this.isLoading,
  });

  @override
  State<AutocompleteOptionsLocation> createState() =>
      _AutocompleteOptionsLocationState();
}

class _AutocompleteOptionsLocationState
    extends State<AutocompleteOptionsLocation> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize ScrollController
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    if (widget.isLoading) {
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
          border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHigh),
        ),
        height: min(52.0 * widget.options.length,
            MediaQuery.of(context).size.height / 2),
        width: MediaQuery.of(context).size.width - 32,
        child: Scrollbar(
          controller: _scrollController,
          // Attach the ScrollController
          thumbVisibility: true,
          // Always show the scroll bar
          thickness: 3.0,
          // Adjust the thickness of the scroll bar

          radius: Radius.circular(8),
          // Rounded edges for the scroll bar
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.options.length,
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              final option = widget.options[index];
              return GestureDetector(
                onTap: () => widget.onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(option.address ?? 'Unknown Address',
                      style: typography.Subtitle1),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
