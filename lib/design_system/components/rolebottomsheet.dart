import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../models/initial_data_model.dart';
import '../../providers/auth_provider.dart';
import '../primitives/app_colors.dart';
import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';
import '../repo/constants.dart';

class RolesBottomSheet1 extends StatefulWidget {
  final List<String> options;
  final List<Categories> selectedRoles;
  final Function(Categories) addChip;
  final Function(Categories) removeChip;
  final Function() removeAllChips;
  final SignUpOptions selectedOption;
  final Function(SignUpOptions) onOptionChanged;
  final bool showCorporateSwitch;
  final bool isUserProfile;

  const RolesBottomSheet1({
    super.key,
    required this.options,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.removeAllChips,
    required this.showCorporateSwitch,
    this.isUserProfile = false,
  });

  @override
  RolesBottomSheet1State createState() => RolesBottomSheet1State();
}

class RolesBottomSheet1State extends State<RolesBottomSheet1> {
  Set<String> _selectedOptions = Set<String>();

  late final List<Map<String, dynamic>> filteredOptionsIndividual;
  late final List<Map<String, dynamic>> filteredOptionsCorporate;

  @override
  void initState() {
    super.initState();

    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    if (widget.isUserProfile) {
      filteredOptionsIndividual = [];
      filteredOptionsCorporate = [];
    } else {
      final allIndividual = (authNotifier.companyTypeList ?? [])
          .where((companyType) => companyType.isApplicableForTrial == true)
          .expand((companyType) =>
          (companyType.roles ?? []).map((role) => role.toJson()))
          .toList();

      final Map<dynamic, Map<String, dynamic>> uniqueIndividual = {};
      for (var item in allIndividual) {
        final key = item['id'] ?? item['name'];
        uniqueIndividual[key] = item;
      }
      filteredOptionsIndividual = uniqueIndividual.values.toList();

      final allCorporate = (authNotifier.roleList ?? [])
          .where((role) => role.accountType == 'corporate')
          .expand((role) => (role.categories ?? []).map((cat) => cat.toJson()))
          .toList();

      final Map<dynamic, Map<String, dynamic>> uniqueCorporate = {};
      for (var item in allCorporate) {
        final key = item['id'] ?? item['name'];
        uniqueCorporate[key] = item;
      }
      filteredOptionsCorporate = uniqueCorporate.values.toList();
    }

    // 🕒 Run after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedOptions();
    });
  }

  void _updateSelectedOptions() {
    final selectedOptionsList =
    widget.selectedOption == SignUpOptions.individual
        ? filteredOptionsIndividual
        : filteredOptionsCorporate;

    final newSelections = <String>{};

    for (final selected in widget.selectedRoles) {
      final match = selectedOptionsList.firstWhere(
            (option) {
          final optionId = option['id']?.toString();
          final optionRole = option['role']?.toString();
          final optionName = option['name']?.toString();
          return optionId == selected.id ||
              optionRole == selected.role ||
              optionName == selected.name;
        },
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        final id = match['id']?.toString() ??
            match['role']?.toString() ??
            match['name']?.toString();
        newSelections.add(id ?? '');
      }
    }

    setState(() {
      _selectedOptions = newSelections;
    });

    log("✅ Restored selected IDs: $_selectedOptions");
  }

  @override
  void didUpdateWidget(covariant RolesBottomSheet1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoles != widget.selectedRoles ||
        oldWidget.selectedOption != widget.selectedOption) {
      _updateSelectedOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    List<Map<String, dynamic>> allOptions =
    widget.selectedOption == SignUpOptions.individual
        ? filteredOptionsIndividual
        : filteredOptionsCorporate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, top: 24),
              child: Text('Select Account Roles',
                  style: typography.H7.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  )),
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
          child: ListView(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allOptions.length,
                itemBuilder: (context, index) {
                  final option = allOptions[index];
                  final accountType = option['name'];
                  final id = option['id'] ?? option['role'] ?? option['name'];

                  // Enable checkbox if any selectedRole.name matches option['name']
                  final bool isSelected = widget.selectedRoles
                      .any((role) => role.name == option['name']);

                  return ListTile(
                    title: Text(accountType),
                    leading: widget.selectedOption == SignUpOptions.individual
                        ? Checkbox(
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected!) {
                            widget.addChip(Categories.fromJson(option));
                          } else {
                            // Remove all chips that match this option
                            widget.selectedRoles
                                .where((role) => role.name == option['name'])
                                .toList()
                                .forEach((role) => widget.removeChip(role));
                          }
                        });
                      },
                    )
                        : Radio<String>(
                      value: id,
                      groupValue: widget.selectedRoles.isNotEmpty
                          ? widget.selectedRoles.first.name
                          : null,
                      onChanged: (value) {
                        setState(() {
                          if (widget.selectedRoles.isNotEmpty) {
                            final previousRole =
                                widget.selectedRoles.first;
                            widget.removeChip(previousRole);
                          }
                          if (value != null) {
                            widget.addChip(Categories.fromJson(option));
                          }
                        });
                      },
                    ),
                  );
                },
              ),

              if (Platform.isAndroid) ...[
                widget.showCorporateSwitch ? const Divider() : SizedBox(),
                widget.showCorporateSwitch
                    ? Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          widget.onOptionChanged(widget.selectedOption ==
                              SignUpOptions.individual
                              ? SignUpOptions.corporate
                              : SignUpOptions.individual);
                          widget.removeAllChips(); // Clear all chips
                          Navigator.pop(context);
                          /*showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (BuildContext context) {
                            return OptionsBottomSheet(
                              options: roles,
                              selectedRoles: [], // Pass an empty list to reset the chips
                              addChip: widget.addChip,
                              removeChip: widget.removeChip,
                              removeAllChips: widget.removeAllChips,
                              selectedOption: widget.selectedOption == SignUpOptions.individual
                                  ? SignUpOptions.corporate
                                  : SignUpOptions.individual,
                              onOptionChanged: widget.onOptionChanged,
                            );
                          },
                        );*/
                        },
                        child: Text(
                          widget.selectedOption ==
                              SignUpOptions.individual
                              ? 'SWITCH TO CORPORATE'
                              : 'SWITCH TO INDIVIDUAL',
                          style: typography
                              .Subtitle1, // Adjust text color if needed
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${widget.selectedOption != SignUpOptions.individual ? 'Individual' : 'Corporate'} account roles",
                            style: typography.Subtitle1,
                          ),
                          SvgPicture.asset(
                            'assets/images/down_icon.svg',
                          )
                        ],
                      ),
                      SizedBox(height: CustomSpacing.two),
                    ],
                  ),
                )
                    : SizedBox(),
                widget.showCorporateSwitch ? const Divider() : SizedBox(),
                widget.showCorporateSwitch
                    ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                  widget.selectedOption == SignUpOptions.individual
                      ? filteredOptionsCorporate.length
                      : filteredOptionsIndividual.length,
                  itemBuilder: (context, index) {
                    final option =
                    widget.selectedOption == SignUpOptions.individual
                        ? filteredOptionsCorporate[index]
                        : filteredOptionsIndividual[index];
                    final accountType = option['name'];
                    // final id = option['role'];
                    final id =
                        option['id'] ?? option['role'] ?? option['name'];

                    return ListTile(
                      title: Text(accountType),
                      leading: widget.selectedOption ==
                          SignUpOptions.individual
                          ? Radio<String>(
                        value: id,
                        groupValue: null,
                        onChanged: null,
                      )
                          : Checkbox(
                        value: false,
                        onChanged: null,
                      ),
                    );
                  },
                )
                    : SizedBox(),
              ],
            ],
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / 1.1,
          height: 50,
          child: FloatingActionButton.extended(
            onPressed: () {
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
        SizedBox(height: 20)
      ],
    );
  }
}
