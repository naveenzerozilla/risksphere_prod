import 'package:flutter/material.dart';

import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';

class ImpactFilterSection extends StatelessWidget {
  final List<Map<String, dynamic>> filters;
  final String? selectedFilter;
  final Function(String) onFilterSelected;

  ImpactFilterSection({
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['label'];
          return GestureDetector(
            onTap: () => onFilterSelected(filter['label']),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue // Highlight selected filter
                        : filter['color'],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter['count'].toString(),
                    style: typography.Body1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Text(
                  filter['label'],
                  style: typography.Body2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primaryMain : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
