import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../models/initial_data_model.dart';
import '../../service/language_service.dart';
import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';

class CustomFlexibleRolesBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final List<Categories> selectedRoles;
  final Function(Categories) addChip;
  final Function(Categories) removeChip;
  final Function() removeAllChips;
  final bool useCheckboxes; // Whether to use checkboxes or radios for selection
  final bool showCorporateSwitch;

  const CustomFlexibleRolesBottomSheet({
    Key? key,
    required this.options,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.removeAllChips,
    required this.useCheckboxes,
    required this.showCorporateSwitch,
  }) : super(key: key);

  @override
  State<CustomFlexibleRolesBottomSheet> createState() => _CustomFlexibleRolesBottomSheetState();
}

class _CustomFlexibleRolesBottomSheetState extends State<CustomFlexibleRolesBottomSheet> {
  // List to store selected options
  List<Categories> _selectedOptions = [];

  @override
  void initState() {
    super.initState();
    // Initialize _selectedOptions with the initially selected roles
    _selectedOptions.addAll(widget.selectedRoles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, top: 24),
              child: Text(
                LanguageService.getTranslated(context, 'usermanagement_app_employee_create_account_select_role_title'),
                style: CustomTypography.H7.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 24, top: 24),
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.options.length,
            itemBuilder: (context, index) {
              final option = widget.options[index];
              final accountType = option['name'];
              final id = option['role'];
              final isSelectable = option['is_selectable'] ?? true;
              final bool isSelected = _selectedOptions
                  .where((role) => role.name == accountType)
                  .isNotEmpty;

              return ListTile(
                title: Text(accountType),
                leading: widget.useCheckboxes
                    ? Checkbox(
                  value: isSelected,
                  onChanged: isSelectable
                      ? (bool? selected) {
                    setState(() {
                      if (selected!) {
                        _selectedOptions.add(Categories.fromJson(option));
                      } else {
                        _selectedOptions.removeWhere((role) => role.name == accountType);
                      }
                    });
                  }
                      : null,
                )

                    : Radio<String>(
                  value: id,
                  groupValue: isSelected ? id : null,
                  onChanged: isSelectable
                      ? (value) {
                    setState(() {
                      _selectedOptions.clear();
                      _selectedOptions.add(Categories.fromJson(option));
                    });
                  }
                      : null,
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () {
            // Remove all existing chips
            widget.removeAllChips();
            // Add new chips for the selected options
            for (Categories selectedOption in _selectedOptions) {
              widget.addChip(selectedOption);
            }
            // Close the bottom sheet
            Navigator.pop(context);
          },
          child: Text(LanguageService.getTranslated(context, "usermanagement_app_employee_create_account_select_role_submit"), style: CustomTypography.Subtitle1),
        ),

      ],
    );
  }
}

