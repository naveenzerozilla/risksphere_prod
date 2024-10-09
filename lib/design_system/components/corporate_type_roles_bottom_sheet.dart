import 'package:flutter/material.dart';
import 'package:green/models/company_type_model.dart';

import '../../service/language_service.dart';
import '../primitives/custom_typography.dart';

class CorporateTypeRolesBottomSheet extends StatefulWidget {
  final List<Roles> roles;
  final List<Roles> selectedRoles;
  final Function(Roles) addChip;
  final Function(Roles) removeChip;
  final Function() removeAllChips;
  final bool isEnabled;

  const CorporateTypeRolesBottomSheet({
    Key? key,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.removeAllChips,
    required this.roles,
    this.isEnabled = false,
  }) : super(key: key);

  @override
  State<CorporateTypeRolesBottomSheet> createState() => _CorporateTypeRolesBottomSheetState();
}

class _CorporateTypeRolesBottomSheetState extends State<CorporateTypeRolesBottomSheet> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    if (widget.selectedRoles.isNotEmpty) {
      _selectedOption = widget.selectedRoles[0].role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 24, top: 24),
                child: Text(
                  LanguageService.getTranslated(
                    context,
                    'usermanagement_app_employee_create_account_select_role_title',
                  ),
                  style: typography.H7.copyWith(
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
            child: widget.roles.isEmpty
                ? Center(
              child: Text(
                LanguageService.getTranslated(
                  context,
                  "usermanagement_app_employee_create_account_select_role_company_type",
                ),
                style: typography.Body1,
              ),
            )
                : ListView.builder(
              itemCount: widget.roles.length,
              itemBuilder: (context, index) {
                final role = widget.roles[index];
                final roleName = role.name ?? "";
                final roleId = role.role ?? "";

                // Check if the current role is admin
                final isAdmin = role.role == "admin";

                return ListTile(
                  title: Text(roleName),
                  leading: Radio<String>(
                    value: roleId,
                    groupValue: _selectedOption,
                    onChanged: !isAdmin && !widget.isEnabled
                        ? null
                        : (value) {
                      setState(() {
                        _selectedOption = value;
                        widget.removeAllChips();
                        widget.addChip(role);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              LanguageService.getTranslated(
                context,
                'usermanagement_app_employee_create_account_select_role_submit',
              ),
              style: typography.Body1.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
