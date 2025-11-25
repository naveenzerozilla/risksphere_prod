import 'package:RiskSphere/models/user_profile_model.dart';
import 'package:flutter/material.dart';

import '../../models/initial_data_model.dart';
import '../../service/language_service.dart';
import '../primitives/app_colors.dart';
import '../primitives/custom_typography.dart';

class CustomFlexibleRolesBottomSheet extends StatefulWidget {
  final List<AcceptedRole> options;
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
  State<CustomFlexibleRolesBottomSheet> createState() =>
      _CustomFlexibleRolesBottomSheetState();
}

class _CustomFlexibleRolesBottomSheetState
    extends State<CustomFlexibleRolesBottomSheet> {
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
    var typography = CustomTypography(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, top: 24),
              child: Text(
                LanguageService.getTranslated(context,
                    'usermanagement_app_employee_create_account_select_role_title'),
                style: typography.H7.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 24, top: 24),
              child: IconButton(
                icon: const Icon(Icons.close),
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
              final accountType = option.name;
              final id = option.id;
              final isSelectable = option.isSelectable ?? true;
              final bool isSelected = _selectedOptions
                  .where((role) => role.name == accountType)
                  .isNotEmpty;

              return ListTile(
                title: Text(accountType ?? ''),
                leading: widget.useCheckboxes
                    ? Checkbox(
                        value: isSelected,
                        onChanged: isSelectable
                            ? (bool? selected) {
                                setState(() {
                                  if (selected!) {
                                    // Convert AcceptedRole to Categories or find corresponding Categories
                                    final category =
                                        _findCorrespondingCategory(option);
                                    if (category != null) {
                                      _selectedOptions.add(category);
                                    }
                                  } else {
                                    _selectedOptions.removeWhere(
                                        (role) => role.name == accountType);
                                  }
                                });
                              }
                            : null,
                      )
                    : Radio<bool>(
                        value: true,
                        groupValue: isSelected,
                        onChanged: isSelectable
                            ? (value) {
                                setState(() {
                                  _selectedOptions.clear();
                                  // Convert AcceptedRole to Categories or find corresponding Categories
                                  final category =
                                      _findCorrespondingCategory(option);
                                  if (category != null) {
                                    _selectedOptions.add(category);
                                  }
                                });
                              }
                            : null,
                      ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 30),
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            height: 50,
            child: FloatingActionButton.extended(
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
              label: Text(
                'SUBMIT',
                style: typography.ButtonLarge.copyWith(color: Colors.black),
              ),
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // SizedBox(height: 20),
        ),
      ],
    );
  }

  Categories? _findCorrespondingCategory(AcceptedRole role) {
    return Categories(
        id: role.id,
        name: role.name,
        isApplicableForTrial: true,
        isForIndividual: true,
        isMultipleRoleEnabled: true,
        role: ''

        // Add other necessary properties
        );
  }
}
