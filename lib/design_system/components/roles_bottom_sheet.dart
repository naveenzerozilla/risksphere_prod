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

class RolesBottomSheet extends StatefulWidget {
  final List<Roles> options; // <--- USE THIS ONLY
  final List<Categories> selectedRoles;

  final Function(Categories) addChip;
  final Function(Categories) removeChip;
  final Function() removeAllChips;

  final SignUpOptions selectedOption;
  final Function(SignUpOptions) onOptionChanged;

  final bool showCorporateSwitch;

  const RolesBottomSheet({
    super.key,
    required this.options,
    required this.selectedRoles,
    required this.addChip,
    required this.removeChip,
    required this.removeAllChips,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.showCorporateSwitch,
  });

  @override
  State<RolesBottomSheet> createState() => _RolesBottomSheetState();
}

class _RolesBottomSheetState extends State<RolesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    /// 🌟 ONLY USING widget.options
    final allOptions = widget.options;

    return SafeArea(
      child: Column(
        children: [
          _header(typography),
          Expanded(
            child: ListView.builder(
              itemCount: allOptions.length,
              itemBuilder: (_, index) {
                final role = allOptions[index];
                // final optionKey = role.id ?? role.role ?? role.name;
                //
                // final bool isSelected = widget.selectedRoles.any((r) =>
                // r.id == optionKey ||
                //     r.role == optionKey ||
                //     r.name == optionKey);
                // final bool isSelected =
                //     widget.selectedRoles.any((r) => r.id == role.id);
                final optionKey = role.id ?? role.role ?? role.name ?? "";

                final bool isSelected = widget.selectedRoles.any((r) =>
                r.id == optionKey ||
                    r.role == optionKey ||
                    r.name == optionKey,
                );

                return ListTile(
                  title: Text(role.name ?? ""),

                  leading: widget.selectedOption == SignUpOptions.individual
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      if (value == true) {
                        widget.addChip(Categories.fromJson(role.toJson()));
                      } else {
                        final toRemove = widget.selectedRoles.firstWhere(
                              (r) =>
                          r.id == optionKey ||
                              r.role == optionKey ||
                              r.name == optionKey,
                          orElse: () => Categories(
                            id: "",
                            name: "",
                            role: "",
                            isForIndividual: false,
                            isApplicableForTrial: false,
                            isMultipleRoleEnabled: false,
                          ),
                        );

                        if (toRemove.id!.isNotEmpty) {
                          widget.removeChip(toRemove);
                        }
                      }
                      setState(() {});
                    },
                  )
                      : Radio<String>(
                    value: optionKey,   // <-- SAFE
                    groupValue: widget.selectedRoles.isNotEmpty
                        ? (widget.selectedRoles.first.id ??
                        widget.selectedRoles.first.role ??
                        widget.selectedRoles.first.name)
                        : null,
                    onChanged: (value) {
                      widget.removeAllChips();
                      widget.addChip(Categories.fromJson(role.toJson()));
                      setState(() {});
                    },
                  ),



                  // leading: widget.selectedOption == SignUpOptions.individual
                  //     ? Checkbox(
                  //         value: isSelected,
                  //         onChanged: (value) {
                  //           setState(() {
                  //             if (value == true) {
                  //               widget.addChip(
                  //                   Categories.fromJson(role.toJson()));
                  //             } else {
                  //               widget.removeChip(
                  //                 widget.selectedRoles
                  //                     .firstWhere((r) => r.id == role.id),
                  //               );
                  //             }
                  //           });
                  //         })
                  //     : Radio<String>(
                  //         value: role.id!,
                  //         groupValue: widget.selectedRoles.isNotEmpty
                  //             ? widget.selectedRoles.first.id
                  //             : null,
                  //         onChanged: (value) {
                  //           setState(() {
                  //             widget.removeAllChips();
                  //             widget
                  //                 .addChip(Categories.fromJson(role.toJson()));
                  //           });
                  //         },
                  //       ),
                );
              },
            ),
          ),
          if (widget.showCorporateSwitch) _switchButton(typography),
          _submitButton(typography),
        ],
      ),
    );
  }

  /// HEADER
  Widget _header(CustomTypography typography) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Select Account Roles",
            style: typography.H7.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// SWITCH BUTTON
  Widget _switchButton(CustomTypography typography) {
    return Column(
      children: [
        Divider(),
        TextButton(
          onPressed: () {
            widget.onOptionChanged(
              widget.selectedOption == SignUpOptions.individual
                  ? SignUpOptions.corporate
                  : SignUpOptions.individual,
            );
            widget.removeAllChips();
            Navigator.pop(context);
          },
          child: Text(
            widget.selectedOption == SignUpOptions.individual
                ? "SWITCH TO CORPORATE"
                : "SWITCH TO INDIVIDUAL",
            style: typography.Subtitle1,
          ),
        ),
        Divider(),
      ],
    );
  }

  /// SUBMIT BUTTON
  Widget _submitButton(CustomTypography typography) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: Text(
          "SUBMIT",
          style: typography.ButtonLarge.copyWith(color: Colors.black),
        ),
        backgroundColor: AppColors.primaryMain,
      ),
    );
  }
}

// class RolesBottomSheet extends StatefulWidget {
//   // final List<String> options;
//   final List<Roles> options;
//   final List<Categories> selectedRoles;
//   final Function(Categories) addChip;
//   final Function(Categories) removeChip;
//   final Function() removeAllChips;
//   final SignUpOptions selectedOption;
//   final Function(SignUpOptions) onOptionChanged;
//   final bool showCorporateSwitch;
//   final bool isUserProfile;
//
//   const RolesBottomSheet({
//     super.key,
//     required this.options,
//     required this.selectedRoles,
//     required this.addChip,
//     required this.removeChip,
//     required this.selectedOption,
//     required this.onOptionChanged,
//     required this.removeAllChips,
//     required this.showCorporateSwitch,
//     this.isUserProfile = false,
//   });
//
//   @override
//   RolesBottomSheetState createState() => RolesBottomSheetState();
// }
//
// class RolesBottomSheetState extends State<RolesBottomSheet> {
//   Set<String> _selectedOptions = Set<String>();
//
//   late final List<Map<String, dynamic>> filteredOptionsIndividual;
//   late final List<Map<String, dynamic>> filteredOptionsCorporate;
//
//   @override
//   void initState() {
//     super.initState();
//
//     final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
//
//     if (widget.isUserProfile) {
//       filteredOptionsIndividual = [];
//       filteredOptionsCorporate = [];
//     } else {
//       final allIndividual = (authNotifier.companyTypeList ?? [])
//           .where((companyType) => companyType.isApplicableForTrial == true)
//           .expand((companyType) =>
//               (companyType.roles ?? []).map((role) => role.toJson()))
//           .toList();
//
//       final Map<dynamic, Map<String, dynamic>> uniqueIndividual = {};
//       for (var item in allIndividual) {
//         final key = item['id'] ?? item['name'];
//         uniqueIndividual[key] = item;
//       }
//       filteredOptionsIndividual = uniqueIndividual.values.toList();
//
//       final allCorporate = (authNotifier.roleList ?? [])
//           .where((role) => role.accountType == 'corporate')
//           .expand((role) => (role.categories ?? []).map((cat) => cat.toJson()))
//           .toList();
//
//       final Map<dynamic, Map<String, dynamic>> uniqueCorporate = {};
//       for (var item in allCorporate) {
//         final key = item['id'] ?? item['name'];
//         uniqueCorporate[key] = item;
//       }
//       filteredOptionsCorporate = uniqueCorporate.values.toList();
//     }
//
//     // 🕒 Run after build completes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _updateSelectedOptions();
//     });
//   }
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //
//   //   final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
//   //
//   //   if (widget.isUserProfile) {
//   //     // For user profile case (if roles are already loaded)
//   //     filteredOptionsIndividual = [];
//   //     filteredOptionsCorporate = [];
//   //   } else {
//   //     // 🔹 INDIVIDUAL ROLES
//   //     final allIndividual = (authNotifier.companyTypeList ?? [])
//   //         .where((companyType) => companyType.isApplicableForTrial == true)
//   //         .expand((companyType) {
//   //       log("Processing companyType: ${companyType.type}, Roles Count: ${companyType.roles?.length ?? 0}");
//   //       return (companyType.roles ?? []).map((role) => role.toJson());
//   //     }).toList();
//   //
//   //     // ✅ Deduplicate based on 'id' or fallback 'name'
//   //     final Map<dynamic, Map<String, dynamic>> uniqueIndividual = {};
//   //     for (var item in allIndividual) {
//   //       final key = item['id'] ?? item['name'];
//   //       uniqueIndividual[key] = item;
//   //     }
//   //     filteredOptionsIndividual = uniqueIndividual.values.toList();
//   //
//   //     log("✅ Unique Individual Roles Count: ${filteredOptionsIndividual.length}");
//   //     log("✅ Individual Roles: ${filteredOptionsIndividual.map((e) => e['name']).toList()}");
//   //
//   //     // 🔹 CORPORATE ROLES
//   //     final allCorporate = (authNotifier.roleList ?? [])
//   //         .where((role) => role.accountType == 'corporate')
//   //         .expand((role) => (role.categories ?? []).map((cat) => cat.toJson()))
//   //         .toList();
//   //
//   //     // ✅ Deduplicate corporate roles
//   //     final Map<dynamic, Map<String, dynamic>> uniqueCorporate = {};
//   //     for (var item in allCorporate) {
//   //       final key = item['id'] ?? item['name'];
//   //       uniqueCorporate[key] = item;
//   //     }
//   //     filteredOptionsCorporate = uniqueCorporate.values.toList();
//   //
//   //     log("✅ Unique Corporate Roles Count: ${filteredOptionsCorporate.length}");
//   //     log("✅ Corporate Roles: ${filteredOptionsCorporate.map((e) => e['name']).toList()}");
//   //   }
//   //
//   //   _updateSelectedOptions();
//   // }
//   void _updateSelectedOptions() {
//     final selectedOptionsList =
//         widget.selectedOption == SignUpOptions.individual
//             ? filteredOptionsIndividual
//             : filteredOptionsCorporate;
//
//     final newSelections = <String>{};
//
//     for (final selected in widget.selectedRoles) {
//       final match = selectedOptionsList.firstWhere(
//         (option) {
//           final optionId = option['id']?.toString();
//           final optionRole = option['role']?.toString();
//           final optionName = option['name']?.toString();
//           return optionId == selected.id ||
//               optionRole == selected.role ||
//               optionName == selected.name;
//         },
//         orElse: () => {},
//       );
//
//       if (match.isNotEmpty) {
//         final id = match['id']?.toString() ??
//             match['role']?.toString() ??
//             match['name']?.toString();
//         newSelections.add(id ?? '');
//       }
//     }
//
//     setState(() {
//       _selectedOptions = newSelections;
//     });
//
//     log("✅ Restored selected IDs: $_selectedOptions");
//   }
//
//   @override
//   void didUpdateWidget(covariant RolesBottomSheet oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedRoles != widget.selectedRoles ||
//         oldWidget.selectedOption != widget.selectedOption) {
//       _updateSelectedOptions();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var typography = CustomTypography(context);
//     List<Map<String, dynamic>> allOptions =
//         widget.selectedOption == SignUpOptions.individual
//             ? filteredOptionsIndividual
//             : filteredOptionsCorporate;
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Text(widget.options.first.name.toString()),
//             Container(
//               margin: const EdgeInsets.only(left: 24, top: 24),
//               child: Text('Select Account Roles',
//                   style: typography.H7.copyWith(
//                     color: Theme.of(context).colorScheme.onBackground,
//                     fontWeight: FontWeight.bold,
//                   )),
//             ),
//             Container(
//               margin: const EdgeInsets.only(right: 24, top: 24),
//               child: IconButton(
//                 icon: Icon(Icons.close),
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ),
//           ],
//         ),
//         Expanded(
//           child: ListView(
//             children: [
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: allOptions.length,
//                 itemBuilder: (context, index) {
//                   final option = allOptions[index];
//                   final accountType = option['name'];
//                   final id = option['id'] ?? option['role'] ?? option['name'];
//
//                   // Enable checkbox if any selectedRole.name matches option['name']
//                   final bool isSelected = widget.selectedRoles
//                       .any((role) => role.name == option['name']);
//
//                   return ListTile(
//                     title: Text(accountType),
//                     leading: widget.selectedOption == SignUpOptions.individual
//                         ? Checkbox(
//                       value: isSelected,
//                       onChanged: (bool? selected) {
//                         setState(() {
//                           if (selected!) {
//                             widget.addChip(Categories.fromJson(option));
//                           } else {
//                             // Remove all chips that match this option
//                             widget.selectedRoles
//                                 .where((role) => role.name == option['name'])
//                                 .toList()
//                                 .forEach((role) => widget.removeChip(role));
//                           }
//                         });
//                       },
//                     )
//                         : Radio<String>(
//                       value: id,
//                       groupValue: widget.selectedRoles.isNotEmpty
//                           ? widget.selectedRoles.first.name
//                           : null,
//                       onChanged: (value) {
//                         setState(() {
//                           if (widget.selectedRoles.isNotEmpty) {
//                             final previousRole =
//                                 widget.selectedRoles.first;
//                             widget.removeChip(previousRole);
//                           }
//                           if (value != null) {
//                             widget.addChip(Categories.fromJson(option));
//                           }
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//
//               if (Platform.isAndroid) ...[
//                 widget.showCorporateSwitch ? const Divider() : SizedBox(),
//                 widget.showCorporateSwitch
//                     ? Container(
//                         margin: EdgeInsets.symmetric(horizontal: 24),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             TextButton(
//                               onPressed: () {
//                                 widget.onOptionChanged(widget.selectedOption ==
//                                         SignUpOptions.individual
//                                     ? SignUpOptions.corporate
//                                     : SignUpOptions.individual);
//                                 widget.removeAllChips(); // Clear all chips
//                                 Navigator.pop(context);
//                                 /*showModalBottomSheet(
//                           context: context,
//                           isScrollControlled: true,
//                           useSafeArea: true,
//                           builder: (BuildContext context) {
//                             return OptionsBottomSheet(
//                               options: roles,
//                               selectedRoles: [], // Pass an empty list to reset the chips
//                               addChip: widget.addChip,
//                               removeChip: widget.removeChip,
//                               removeAllChips: widget.removeAllChips,
//                               selectedOption: widget.selectedOption == SignUpOptions.individual
//                                   ? SignUpOptions.corporate
//                                   : SignUpOptions.individual,
//                               onOptionChanged: widget.onOptionChanged,
//                             );
//                           },
//                         );*/
//                               },
//                               child: Text(
//                                 widget.selectedOption ==
//                                         SignUpOptions.individual
//                                     ? 'SWITCH TO CORPORATE'
//                                     : 'SWITCH TO INDIVIDUAL',
//                                 style: typography
//                                     .Subtitle1, // Adjust text color if needed
//                               ),
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "${widget.selectedOption != SignUpOptions.individual ? 'Individual' : 'Corporate'} account roles",
//                                   style: typography.Subtitle1,
//                                 ),
//                                 SvgPicture.asset(
//                                   'assets/images/down_icon.svg',
//                                 )
//                               ],
//                             ),
//                             SizedBox(height: CustomSpacing.two),
//                           ],
//                         ),
//                       )
//                     : SizedBox(),
//                 widget.showCorporateSwitch ? const Divider() : SizedBox(),
//                 widget.showCorporateSwitch
//                     ? ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount:
//                             widget.selectedOption == SignUpOptions.individual
//                                 ? filteredOptionsCorporate.length
//                                 : filteredOptionsIndividual.length,
//                         itemBuilder: (context, index) {
//                           final option =
//                               widget.selectedOption == SignUpOptions.individual
//                                   ? filteredOptionsCorporate[index]
//                                   : filteredOptionsIndividual[index];
//                           final accountType = option['name'];
//                           // final id = option['role'];
//                           final id =
//                               option['id'] ?? option['role'] ?? option['name'];
//
//                           return ListTile(
//                             title: Text(accountType),
//                             leading: widget.selectedOption ==
//                                     SignUpOptions.individual
//                                 ? Radio<String>(
//                                     value: id,
//                                     groupValue: null,
//                                     onChanged: null,
//                                   )
//                                 : Checkbox(
//                                     value: false,
//                                     onChanged: null,
//                                   ),
//                           );
//                         },
//                       )
//                     : SizedBox(),
//               ],
//             ],
//           ),
//         ),
//         SizedBox(
//           width: MediaQuery.of(context).size.width / 1.1,
//           height: 50,
//           child: FloatingActionButton.extended(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             label: Text(
//               'SUBMIT',
//               style: typography.ButtonLarge.copyWith(color: Colors.black),
//             ),
//             backgroundColor: AppColors.primaryMain,
//             foregroundColor: Theme.of(context).colorScheme.onSurface,
//           ),
//         ),
//         SizedBox(height: 20)
//       ],
//     );
//   }
// }
