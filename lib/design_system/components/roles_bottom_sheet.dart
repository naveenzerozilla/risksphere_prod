import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../models/initial_data_model.dart';
import '../../providers/auth_provider.dart';
import '../primitives/custom_typography.dart';
import '../primitives/utilities/custom_spacing.dart';
import '../repo/constants.dart';

class RolesBottomSheet extends StatefulWidget {
  final List<String> options;
  final List<Categories> selectedRoles;
  final Function(Categories) addChip;
  final Function(Categories) removeChip;
  final Function() removeAllChips;
  final SignUpOptions selectedOption;
  final Function(SignUpOptions) onOptionChanged;
  final bool showCorporateSwitch;

  const RolesBottomSheet({super.key,
    required this.options,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.removeAllChips,
    required this.showCorporateSwitch,
  });

  @override
  RolesBottomSheetState createState() => RolesBottomSheetState();
}

class RolesBottomSheetState extends State<RolesBottomSheet> {
  Set<String> _selectedOptions = Set<String>();

  late final List<Map<String, dynamic>> filteredOptionsIndividual;
  late final List<Map<String, dynamic>> filteredOptionsCorporate;

  @override
  void initState() {
    super.initState();
    // Extract individual and corporate options from JSON data
    // Accessing AuthNotifier using Provider.of
    // Accessing AuthNotifier using Provider.of
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    // Filtering role list for individual and corporate options
    filteredOptionsIndividual = (authNotifier.roleList ?? [])
        .where((role) => role.accountType == 'individual')
        .expand((role) =>
        (role.categories ?? []).map((category) => category.toJson()))
        .toList();

    filteredOptionsCorporate = (authNotifier.roleList ?? [])
        .where((role) => role.accountType == 'corporate')
        .expand((role) =>
        (role.categories ?? []).map((category) => category.toJson()))
        .toList();

    _updateSelectedOptions();
  }

  void _updateSelectedOptions() {
    setState(() {
      _selectedOptions.clear();
      final selectedOptionsList =
      widget.selectedOption == SignUpOptions.individual
          ? filteredOptionsIndividual
          : filteredOptionsCorporate;
      print("Selected options: $selectedOptionsList");
      _selectedOptions.addAll(
        widget.selectedRoles.map((role) {
          print(role);
          final option = selectedOptionsList.firstWhere(
                (option) => option['name'] == role.name,
            orElse: () => {'name': role.name, 'id': null},
          );
          return option?['role'];
        }).whereType<String>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  style: CustomTypography.Subtitle1.copyWith(
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
                  final id = option['role'];
                  final bool isSelected = _selectedOptions.contains(id);

                  return ListTile(
                    title: Text(accountType),
                    leading: widget.selectedOption == SignUpOptions.individual
                        ? Checkbox(
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected!) {
                            _selectedOptions.add(id);
                            widget.addChip(Categories.fromJson(option));
                          } else {
                            _selectedOptions.remove(id);
                            widget
                                .removeChip(Categories.fromJson(option));
                          }
                        });
                      },
                    )
                        : Radio<String>(
                      value: id,
                      groupValue: _selectedOptions.isNotEmpty
                          ? _selectedOptions.first
                          : null,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedOptions.isNotEmpty) {
                            final previousSelection =
                                _selectedOptions.first;
                            final previousRole = allOptions.firstWhere(
                                    (option) =>
                                option['id'] ==
                                    previousSelection)['role'];
                            widget.removeChip(
                                Categories.fromJson(previousRole));
                          }
                          _selectedOptions.clear();
                          if (value != null) {
                            _selectedOptions.add(value);
                            widget.addChip(Categories.fromJson(option));
                          }
                        });
                      },
                    ),
                  );
                },
              ),
              widget.showCorporateSwitch?const Divider():SizedBox(),
              widget.showCorporateSwitch?Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        widget.onOptionChanged(
                            widget.selectedOption == SignUpOptions.individual
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
                        widget.selectedOption == SignUpOptions.individual
                            ? 'SWITCH TO CORPORATE'
                            : 'SWITCH TO INDIVIDUAL',
                        style: CustomTypography
                            .Subtitle1, // Adjust text color if needed
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${widget.selectedOption != SignUpOptions.individual ? 'Individual' : 'Corporate'} account roles",
                          style: CustomTypography.Subtitle1,
                        ),
                        SvgPicture.asset(
                          'assets/images/down_icon.svg',
                        )
                      ],
                    ),
                    SizedBox(height: CustomSpacing.two),
                  ],
                ),
              ):SizedBox(),
              widget.showCorporateSwitch?const Divider():SizedBox(),
              widget.showCorporateSwitch? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedOption == SignUpOptions.individual
                    ? filteredOptionsCorporate.length
                    : filteredOptionsIndividual.length,
                itemBuilder: (context, index) {
                  final option =
                  widget.selectedOption == SignUpOptions.individual
                      ? filteredOptionsCorporate[index]
                      : filteredOptionsIndividual[index];
                  final accountType = option['name'];
                  final id = option['role'];

                  return ListTile(
                    title: Text(accountType),
                    leading: widget.selectedOption == SignUpOptions.individual
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
              ):SizedBox(),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('SUBMIT', style: CustomTypography.Subtitle1),
        ),
      ],
    );
  }
}