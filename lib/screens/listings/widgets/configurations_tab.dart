import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../providers/configuration_provider.dart';
import '../../../service/language_service.dart';
import '../../../service/shared_preference_service.dart';

class ConfigurationTab extends StatefulWidget {
  final String? accountId;
  final String? subaccountId;
  final String? updateallflag;
  final String? level;
  final String? accountName;
  final String? subAccountName;

  const ConfigurationTab({
    Key? key,
    this.accountId,
    this.subaccountId,
    this.updateallflag,
    this.level,
    this.accountName,
    this.subAccountName,
  }) : super(key: key);

  @override
  _ConfigurationTabState createState() => _ConfigurationTabState();
}

class _ConfigurationTabState extends State<ConfigurationTab> {
  List<String> selectedServices = [];
  List<int> selectedStars = [];
  List<dynamic> vendorList = [];
  String isMaintenance = "";
  bool isPgAdmin = false;
  bool isAdmin = false;
  bool isSuperAdmin = false;
  bool isIndivudual = false;
  final TextEditingController _accountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    loadConfiguration();
    // ✅ Set correct initial text
    if (widget.subAccountName != null &&
        widget.subAccountName!.trim().isNotEmpty) {
      _accountController.text = widget.subAccountName!;
    } else {
      _accountController.text = widget.accountName ?? "";
    }
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _setClaims(),
    ]);
  }

  loadConfiguration() {
    final provider = Provider.of<ConfigurationProvider>(context, listen: false);

    Future.wait([
      provider.getConfiguration(
        accountId: widget.accountId,
        subAccountId: widget.subaccountId,
        updateallflag: widget.updateallflag,
      ),
      provider.getVendors()
    ]).then((value) {
      var config = provider.configurations['result'] ?? {};
      // var services = config['services'] ?? {};
      var ratings = config['geocoding_rating_enabled'] ?? {};

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            vendorList = provider.vendors['result'] ?? [];
            // selectedServices = services.entries
            //     .where(
            //         (e) => (e.value as Map<String, dynamic>)['enabled'] == true)
            //     .map<String>((e) => capitalize(e.key))
            //     .toList();
            //
            // print("Selected Services: $selectedServices");

            selectedStars = ratings.entries
                .where((e) => e.value['enabled'] == true)
                .map<int>((e) => int.parse(e.key))
                .toList();
            print("Selected Stars: $selectedStars");
          });
        });
      }
    });
  }

  Future<void> _setClaims() async {
    isPgAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_PG_ADMIN) ??
        false;
    isAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_ADMIN) ??
        false;
    isSuperAdmin = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.IS_SUPER_ADMIN) ??
        false;
    isIndivudual = await SharedPreferenceService.getClaimForSubfeature(
            SharedPreferenceService.Is_Indivudual) ??
        false;
    setState(() {});
  }

  String capitalize(String s) {
    return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return Consumer<ConfigurationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        var config = provider.configurations['result'] ?? {};
        var mainId = config['id'] ?? '';
        var level = config['level'] ?? '';
        var services = config['services'] ?? {};
        var ratings = config['geocoding_rating_enabled'] ?? {};
        var subscriptions = config['subscribe'] ?? {};

        // Update selectedServices when configuration changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedServices.isEmpty && services.isNotEmpty) {
            setState(() {
              selectedServices = services.entries
                  .where((e) =>
                      (e.value as Map<String, dynamic>)['enabled'] == true)
                  .map<String>((e) => capitalize(e.key))
                  .toList();
            });
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedStars.isEmpty && ratings.isNotEmpty) {
            setState(() {
              selectedStars = ratings.entries
                  .where((e) =>
                      e.value['enabled'] == true ||
                      ['3', '4', '5'].contains(e.key))
                  .map<int>((e) {
                    try {
                      return int.parse(e.key);
                    } catch (e) {
                      print('Error parsing key to int: ${e.toString()}');
                      return -1; // Use a default/fallback value if parsing fails
                    }
                  })
                  .where(
                      (star) => star != -1) // Filter out invalid (-1) results
                  .toList();

              print("Selected Stars: $selectedStars");
            });
          }
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RefreshIndicator(
            onRefresh: () async {
              await loadConfiguration(); // Ensure it's an async function
            },
            child: Builder(builder: (context) {
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    widget.updateallflag != "false"
                        ? accountNameInput(
                            controller: _accountController,
                            isLoading: provider.isLoading,
                            onSubmit: () async {
                              final name = _accountController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please write the name'),
                                  ),
                                );
                                return;
                              }

                              if (widget.subAccountName != null &&
                                  widget.subAccountName!.isNotEmpty) {
                                await showConfirmApplyDialog(
                                  context: context,
                                  onConfirm: () async {
                                    await provider
                                        .updateSubAccountNameConfigurations(
                                      context,
                                      name,
                                    );
                                  },
                                );
                                // await provider.updateSubAccountNameConfigurations(
                                //   context,
                                //   name,
                                // );
                              } else if (widget.accountName != null &&
                                  widget.accountName!.isNotEmpty) {
                                await provider.updateAccountNameConfigurations(
                                  context,
                                  name,
                                );
                              }
                            },
                          )
                        : const SizedBox.shrink(),

                    SizedBox(height: CustomSpacing.four),
                    Text(
                      LanguageService.getTranslated(context, "select_services"),
                      style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: CustomSpacing.four),

                    // Dynamic Service Checkboxes
                    for (var key in services.keys)
                      _buildServiceCheckbox(
                        capitalize(key),
                        services[key]['description'],
                        // services[key]['enabled'],
                        services[key]['enabled'] == true ||
                            services[key]['enabled'] == 'true',
                        typography,
                        mainId,
                        level,
                      ),

                    SizedBox(height: CustomSpacing.six),
                    Text(
                      LanguageService.getTranslated(
                          context, "set_geocode_ratings"),
                      style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: CustomSpacing.four),

                    // Dynamic Star Checkboxes
                    for (var key in ratings.keys)
                      _buildStarCheckbox(
                        key,
                        ratings[key]['description'],
                        typography,
                        !ratings[key]['enabled'],
                        mainId,
                        level,
                      ),

                    // SizedBox(height: CustomSpacing.four),
                    // Text(
                    //   'Get hazard event notifications by subscribing to live catastrophic event monitoring',
                    //   style: typography.Body1.copyWith(
                    //     fontWeight: FontWeight.w600,
                    //     fontSize: 18,
                    //   ),
                    // ),
                    // SizedBox(height: CustomSpacing.two),
                    //
                    // // Dynamic Subscription Cards
                    // // Dynamic Subscription Cards
                    // ...subscriptions.keys.map((key) {
                    //   final parts = key.split('_');
                    //   if (parts.length != 2) {
                    //     debugPrint('Invalid subscription key format: $key');
                    //     return SizedBox.shrink();
                    //   }
                    //
                    //   final vendorId = parts[0];
                    //   final hazardName = parts[1];
                    //
                    //   // Find the vendor by vendor_id
                    //   final vendor = vendorList.firstWhere(
                    //     (vendor) => vendor['vendor_id'] == vendorId,
                    //     orElse: () {
                    //       debugPrint('Vendor not found for ID: $vendorId');
                    //       return null;
                    //     },
                    //   );
                    //
                    //   if (vendor == null) return SizedBox.shrink();
                    //
                    //   // Find the hazard in the vendor's hazard_commercials by hazard_name
                    //   final hazardCommercials =
                    //       vendor['hazard_commercials'] as List?;
                    //   final hazard = hazardCommercials?.firstWhere(
                    //     (commercial) => commercial['hazard_name'] == hazardName,
                    //     orElse: () {
                    //       debugPrint(
                    //           'Hazard not found for name: $hazardName in Vendor ID: $vendorId');
                    //       return null;
                    //     },
                    //   );
                    //
                    //   if (hazard == null) return SizedBox.shrink();
                    //
                    //   // Extract subscription and hazard details
                    //   final subscription = subscriptions[key];
                    //   final vendorName = vendor['vendor_name_label'] ?? '';
                    //   final vendorImage = vendor['display_image_url'] ??
                    //       'assets/images/default_vendor.png';
                    //   final hazardLabel =
                    //       hazard['hazard_name_label'] ?? 'Unknown Hazard';
                    //   final description = subscription['description'] ?? '';
                    //
                    //   return Column(
                    //     crossAxisAlignment: CrossAxisAlignment.stretch,
                    //     children: [
                    //       _buildSubscriptionCard(
                    //         key,
                    //         vendorImage,
                    //         '$hazardLabel ($vendorName)',
                    //         description.isNotEmpty ? description : vendorName,
                    //         '$vendorName',
                    //         subscription['is_subscribed'] == true ||
                    //             subscription['is_subscribed'] == 'true',
                    //         mainId,
                    //         level,
                    //         typography,
                    //       ),
                    //       SizedBox(height: CustomSpacing.one),
                    //     ],
                    //   );
                    // }).toList(),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> showConfirmApplyDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm applying changes to all sub-accounts',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'These changes will be applied across all sub-account tables globally. Do you want to proceed?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                onConfirm(); // 🔥 CALL API
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getVendorName(String vendorId) {
    var vendor = vendorList.firstWhere(
      (vendor) => vendor['vendor_id'] == vendorId,
      orElse: () {
        debugPrint('Vendor not found for ID: $vendorId');
        return {'vendor_name_label': ''};
      },
    );

    debugPrint(
        'Vendor found for ID: $vendorId - ${vendor['vendor_name_label']}');
    return vendor['vendor_name_label'] ?? '';
  }

  String _getVendorDisplayName(String vendorId) {
    var vendor = vendorList.firstWhere(
      (vendor) => vendor['vendor_id'] == vendorId,
      orElse: () {
        debugPrint('Display Name not found for Vendor ID: $vendorId');
        return {'display_name': ''};
      },
    );

    debugPrint(
        'Display name found for ID: $vendorId - ${vendor['display_name']}');
    return vendor['display_name'] ?? '';
  }

  String _getVendorImage(String vendorId) {
    var vendor = vendorList.firstWhere(
      (vendor) => vendor['vendor_id'] == vendorId,
      orElse: () {
        debugPrint('Image not found for Vendor ID: $vendorId');
        return {'display_image_url': 'assets/images/default_vendor.png'};
      },
    );

    debugPrint(
        'Image found for Vendor ID: $vendorId - ${vendor['display_image_url']}');
    return vendor['display_image_url'] ?? 'assets/images/default_vendor.png';
  }

  Widget _buildServiceCheckbox(
    String title,
    String description,
    bool isEnabled,
    CustomTypography typography,
    String mainId,
    String level,
  ) {
    final provider = Provider.of<ConfigurationProvider>(context, listen: false);
    // ✅ Match API format (underscores)
    bool isGeocoding = title.toLowerCase() == 'geocoding';
    bool hazardScore = title.toLowerCase() == 'hazard_risk_score';
    bool additionParam = title.toLowerCase() == 'additional parameters';
    bool isSelected = selectedServices.contains(title);

    bool enableCheckbox =
        hazardScore; // ← CHANGED: was "hazardScore || canEdit"

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isEnabled || isGeocoding || additionParam
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(isEnabled.toString()),
          Checkbox(
            value: additionParam ? false : isEnabled,
            onChanged: enableCheckbox
                ? (bool? value) {
                    print('Toggling $title to $value');

                    var key = generateServiceKey(
                        title.toLowerCase().replaceAll(' ', '_'));

                    if (widget.updateallflag == "false") {
                      provider
                          .updateConfiguration(
                        context,
                        mainId,
                        key,
                        "sub_account",
                        value!,
                        false,
                        accountId: widget.accountId,
                        subAccountId: widget.subaccountId,
                        checklevel: widget.level,
                      )
                          .then((_) {
                        loadConfiguration();
                      }).catchError((error) {
                        print("Failed to update configuration: $error");
                      });
                    } else {
                      _showSaveDialog(
                        title,
                        description,
                        typography,
                        value!,
                        mainId,
                        level,
                      );
                    }
                  }
                : null,
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.disabled)) {
                // Disabled but checked (isEnabled = true) → blue grey
                if (states.contains(WidgetState.selected)) {
                  return Colors.blueGrey; // ← disabled + checked
                }
                return Colors.grey.shade400; // ← disabled + unchecked
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors
                    .primaryMain; // ← enabled + checked (hazard risk score)
              }
              return Colors.transparent; // ← unchecked
            }),
          ),
          // Checkbox(
          //   value: additionParam ? false : isSelected,
          //   onChanged:
          //       enableCheckbox // ← simplified: only true for hazardScore (or admin)
          //           ? (bool? value) {
          //               print('Toggling $title to $value');
          //
          //               var key = generateServiceKey(
          //                   title.toLowerCase().replaceAll(' ', '_'));
          //
          //               if (widget.updateallflag == "false") {
          //                 provider
          //                     .updateConfiguration(
          //                   context,
          //                   mainId,
          //                   key,
          //                   "sub_account",
          //                   value!,
          //                   false,
          //                   accountId: widget.accountId,
          //                   subAccountId: widget.subaccountId,
          //                   checklevel: widget.level,
          //                 )
          //                     .then((_) {
          //                   loadConfiguration();
          //                 }).catchError((error) {
          //                   print("Failed to update configuration: $error");
          //                 });
          //               } else {
          //                 _showSaveDialog(
          //                   title,
          //                   description,
          //                   typography,
          //                   value!,
          //                   mainId,
          //                   level,
          //                 );
          //               }
          //             }
          //           : null,
          //   // ← null = disabled for all others
          //   activeColor: hazardScore ? AppColors.green50 : Colors.blue,
          //   // ← red for hazard, blue for others
          //   fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          //     // All disabled checkboxes → grey (Geocoding & Additional Parameters)
          //     if (states.contains(WidgetState.disabled)) {
          //       return Colors.grey.shade400;
          //     }
          //     // Hazard risk score → blue when checked
          //     if (states.contains(WidgetState.selected)) {
          //       return AppColors
          //           .primaryMain; // ← checked color (blue for hazard, can be changed if needed)
          //     }
          //     // Hazard risk score unchecked
          //     return Colors.transparent;
          //   }),
          //   // fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          //   //   if (states.contains(WidgetState.selected)) {
          //   //     return hazardScore
          //   //         ? AppColors.red50
          //   //         : Colors.grey; // ← checked color
          //   //   }
          //   //   if (states.contains(WidgetState.disabled)) {
          //   //     return Colors.grey; // ← disabled color
          //   //   }
          //   //   return Colors.red; // ← unchecked color
          //   // }),
          // ),
          // Checkbox(
          //   value: additionParam ? false : isSelected,
          //   onChanged: (isGeocoding || !additionParam || enableCheckbox)
          //       ? null
          //       : (bool? value) {
          //           print('Toggling $title to $value');
          //
          //           var key = generateServiceKey(
          //               title.toLowerCase().replaceAll(' ', '_'));
          //
          //           if (widget.updateallflag == "false") {
          //             provider
          //                 .updateConfiguration(
          //               context,
          //               mainId,
          //               key,
          //               "sub_account",
          //               value!,
          //               false,
          //               accountId: widget.accountId,
          //               subAccountId: widget.subaccountId,
          //               checklevel: widget.level,
          //             )
          //                 .then((_) {
          //               loadConfiguration();
          //             }).catchError((error) {
          //               print("Failed to update configuration: $error");
          //             });
          //           } else {
          //             _showSaveDialog(
          //               title,
          //               description,
          //               typography,
          //               value!,
          //               mainId,
          //               level,
          //             );
          //           }
          //         },
          //   activeColor: AppColors.red50,
          // ),

          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.replaceAll('_', ' '),
                  style: typography.Body1.copyWith(
                    fontWeight:
                        isGeocoding ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: typography.Caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

//   Widget _buildServiceCheckbox(String title, String description, bool isEnabled,
//       CustomTypography typography, String mainId, String level) {
//     bool isGeocoding = title.toLowerCase() == 'geocoding';
//     bool additionParam = title.toLowerCase() == 'additional_parameters';
//     bool isSelected = selectedServices.contains(title);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       decoration: BoxDecoration(
//         color: isEnabled || isGeocoding || additionParam
//             ? Theme.of(context).colorScheme.surfaceContainerHigh
//             : Theme.of(context).colorScheme.surfaceContainerLowest,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Checkbox(
//             value: additionParam
//                 ? false // Always false for additional_parameters
//                 : selectedServices.contains(title),
//             onChanged: (isGeocoding || additionParam)
//                 ? null // Disable checkbox for Geocoding & Additional Parameters
//                 : (bool? value) {
//                     print('Toggling $title to $value');
//
//                     // Show dialog to save changes
//                     _showSaveDialog(
//                         title, description, typography, value!, mainId, level);
//                   },
//             activeColor: AppColors.primaryMain,
//           ),
// //           Checkbox(
// //             value: title.toString() =="additional_parameters"?false: selectedServices.contains(title),
// //             onChanged: isGeocoding || title == "Additional_parameters"
// //                 ? null // Disable checkbox for Geocoding
// //                 : (bool? value) {
// //                     print('Toggling up $title to $value');
// //
// //                     // Show dialog to save changes
// //                     _showSaveDialog(
// //                         title, description, typography, value!, mainId, level);
// //                   },
// //             activeColor: AppColors.primaryMain,
// //           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title.replaceAll('_', ' '),
//                   style: typography.Body1.copyWith(
//                     fontWeight:
//                         isGeocoding ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: typography.Caption,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  void _toggleService(String title, bool value) {
    print('Toggling $title to $value');
    setState(() {
      if (value) {
        if (!selectedServices.contains(title)) {
          selectedServices.add(title); // Only add if not already in the list
        }
      } else {
        selectedServices.remove(title); // Remove if toggled off
      }
      print('Selected Services: $selectedServices');
    });
  }

  void _showSaveDialog(String title, String description,
      CustomTypography typography, bool value, String mainId, String level) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final provider =
            Provider.of<ConfigurationProvider>(context, listen: false);
        bool isLoadingYes = false;
        bool isLoadingNo = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(
                      'Do you want to apply this change globally?',
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              actions: [
                // "No" Button
                TextButton(
                  onPressed: () async {
                    setState(() => isLoadingNo = true);

                    var key = generateServiceKey(
                        title.toLowerCase().replaceAll(' ', '_'));
                    await provider.updateConfiguration(
                      context,
                      mainId,
                      key,
                      level,
                      value,
                      "false",
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                    );

                    setState(() => isLoadingNo = false);

                    if (!provider.isLoading) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        final provider = Provider.of<ConfigurationProvider>(
                            context,
                            listen: false);
                        await provider.getConfiguration(
                          accountId: widget.accountId,
                          subAccountId: widget.subaccountId,
                          updateallflag: widget.updateallflag,
                        );
                        loadConfiguration();
                      }
                    }
                  },
                  // onPressed: () async {
                  //   setState(() => isLoadingNo = true);
                  //
                  //   await Future.delayed(
                  //       Duration(seconds: 2)); // Simulate API call delay
                  //
                  //   setState(() => isLoadingNo = false);
                  //   Navigator.pop(context); // Close the dialog
                  // },
                  style: TextButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryMain, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoadingNo
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryMain,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'No',
                          style: typography.Body1.copyWith(
                              color: AppColors.primaryMain),
                        ),
                ),
                SizedBox(width: 5),

                // "Yes" Button
                TextButton(
                  onPressed: () async {
                    setState(() => isLoadingYes = true);

                    var key = generateServiceKey(
                        title.toLowerCase().replaceAll(' ', '_'));
                    await provider.updateConfiguration(
                      context,
                      mainId,
                      key,
                      level,
                      value,
                      "true",
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                    );

                    setState(() => isLoadingYes = false);

                    if (!provider.isLoading) {
                      Navigator.pop(context);
                      final provider = Provider.of<ConfigurationProvider>(
                          context,
                          listen: false);
                      provider.getConfiguration(
                        accountId: widget.accountId,
                        subAccountId: widget.subaccountId,
                        updateallflag: widget.updateallflag,
                      );
                      loadConfiguration();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    side: BorderSide(color: AppColors.primaryMain, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: isLoadingYes
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Yes',
                          style: typography.Body1.copyWith(color: Colors.black),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     final provider =
    //         Provider.of<ConfigurationProvider>(context, listen: false);
    //     bool isLoading = false;
    //     bool isLoading1 = false;
    //
    //     return StatefulBuilder(
    //       builder: (context, setState) {
    //         return AlertDialog(
    //           title: Row(
    //             children: [
    //               Container(
    //                 width: MediaQuery.of(context).size.width / 2,
    //                 child: Text(
    //                   'Do you want to apply this change globally?',
    //                   maxLines: 2,
    //                 ),
    //               ),
    //               IconButton(
    //                 onPressed: () {
    //                   Navigator.pop(context);
    //                 },
    //                 icon: Icon(Icons.close),
    //               ),
    //             ],
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: () async {
    //                 setState(() => isLoading = true);
    //
    //                 var key = generateServiceKey(
    //                     title.toLowerCase().replaceAll(' ', '_'));
    //                 await provider.updateConfiguration(
    //                   context,
    //                   mainId,
    //                   key,
    //                   level,
    //                   value,
    //                   "true",
    //                   accountId: widget.accountId,
    //                   subAccountId: widget.subaccountId,
    //                 );
    //
    //                 setState(() => isLoading = false);
    //
    //                 if (!provider.isLoading) {
    //                   Navigator.pop(context);
    //                   setState(() {}); // Reload the page
    //                   final provider = Provider.of<ConfigurationProvider>(
    //                       context,
    //                       listen: false);
    //                   provider.getConfiguration(
    //                     accountId: widget.accountId,
    //                     subAccountId: widget.subaccountId,
    //                   );
    //                   // provider.getVendors();
    //                   loadConfiguration();
    //                 }
    //               },
    //               style: TextButton.styleFrom(
    //                 side: BorderSide(color: AppColors.primaryMain, width: 1.5),
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.circular(8),
    //                 ),
    //               ),
    //               child: isLoading1
    //                   ? SizedBox(
    //                       height: 24,
    //                       width: 24,
    //                       child: CircularProgressIndicator(
    //                         color: AppColors.primaryMain,
    //                         strokeWidth: 3,
    //                       ),
    //                     )
    //                   : Text(
    //                       'No1',
    //                       style: typography.Body1.copyWith(
    //                           color: AppColors.primaryMain),
    //                     ),
    //             ),
    //             TextButton(
    //               onPressed: () async {
    //                 setState(() => isLoading = true);
    //
    //                 var key = generateServiceKey(
    //                     title.toLowerCase().replaceAll(' ', '_'));
    //                 await provider.updateConfiguration(
    //                   context,
    //                   mainId,
    //                   key,
    //                   level,
    //                   value,
    //                   "true",
    //                   accountId: widget.accountId,
    //                   subAccountId: widget.subaccountId,
    //                 );
    //
    //                 setState(() => isLoading = false);
    //
    //                 if (!provider.isLoading) {
    //                   Navigator.pop(context);
    //                   setState(() {}); // Reload the page
    //                   final provider = Provider.of<ConfigurationProvider>(
    //                       context,
    //                       listen: false);
    //                   provider.getConfiguration(
    //                     accountId: widget.accountId,
    //                     subAccountId: widget.subaccountId,
    //                   );
    //                   // provider.getVendors();
    //                   loadConfiguration();
    //                 }
    //               },
    //               style: TextButton.styleFrom(
    //                 backgroundColor: AppColors.primaryMain,
    //                 side: BorderSide(color: AppColors.primaryMain, width: 2),
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.circular(8),
    //                 ),
    //                 padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    //               ),
    //               child: isLoading
    //                   ? SizedBox(
    //                       height: 24,
    //                       width: 24,
    //                       child: CircularProgressIndicator(
    //                         color: Colors.white,
    //                         strokeWidth: 3,
    //                       ),
    //                     )
    //                   : Text(
    //                       'Yes',
    //                       style: typography.Body1.copyWith(color: Colors.black),
    //                     ),
    //             ),
    //           ],
    //         );
    //       },
    //     );
    //   },
    // );
  }

  Future<bool> _showSaveDialogForStar(
    int star,
    String description,
    CustomTypography typography,
    bool value,
    String mainId,
    String level,
  ) async {
    final provider = Provider.of<ConfigurationProvider>(context, listen: false);

    bool isLoadingNo = false; // Keep loaders outside StatefulBuilder
    bool isLoadingYes = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing while loading
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          'Do you want to apply this change globally?',
                          maxLines: 3,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (!isLoadingYes && !isLoadingNo) {
                            Navigator.pop(context, false);
                          }
                        },
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  actions: [
                    // "No" Button
                    TextButton(
                      onPressed: isLoadingNo
                          ? null
                          : () async {
                              setState(() => isLoadingNo = true);

                              await provider.updateConfiguration(
                                context,
                                mainId,
                                generateRatingKey(star.toString()),
                                level,
                                value,
                                "false",
                                accountId: widget.accountId,
                                subAccountId: widget.subaccountId,
                              );

                              setState(() => isLoadingNo = false);
                              if (!provider.isLoading) {
                                await loadConfiguration();
                                Navigator.pop(context, false);
                              }
                            },
                      style: TextButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.primaryMain, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoadingNo
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryMain,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'No',
                              style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain),
                            ),
                    ),

                    SizedBox(width: 10),

                    // "Yes" Button
                    TextButton(
                      onPressed: isLoadingYes
                          ? null
                          : () async {
                              setState(() => isLoadingYes = true);

                              await provider.updateConfiguration(
                                context,
                                mainId,
                                generateRatingKey(star.toString()),
                                level,
                                value,
                                "true",
                                accountId: widget.accountId,
                                subAccountId: widget.subaccountId,
                              );

                              setState(() => isLoadingYes = false);
                              if (!provider.isLoading) {
                                Navigator.pop(context, true);
                              }
                            },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoadingYes
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Yes',
                              style: typography.Body1.copyWith(
                                  color: Colors.white),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  // Future<bool> _showSaveDialogForStar(
  //   int star,
  //   String description,
  //   CustomTypography typography,
  //   bool value,
  //   String mainId,
  //   String level,
  // ) async {
  //   final provider = Provider.of<ConfigurationProvider>(context, listen: false);
  //
  //   return await showDialog<bool>(
  //         context: context,
  //         // barrierDismissible: false,
  //         builder: (context) {
  //           return
  //             StatefulBuilder(
  //               builder: (context, setState) {
  //                 bool isLoadingNo = false; // Separate loading states
  //                 bool isLoadingYes = false;
  //
  //                 return AlertDialog(
  //                   title: Row(
  //                     children: [
  //                       SizedBox(
  //                         width: MediaQuery.of(context).size.width / 2,
  //                         child: Text(
  //                           'Do you want to apply this change globally?',
  //                           maxLines: 2,
  //                         ),
  //                       ),
  //                       IconButton(
  //                         onPressed: () {
  //                           Navigator.pop(context);
  //                         },
  //                         icon: Icon(Icons.close),
  //                       ),
  //                     ],
  //                   ),
  //                   actions: [
  //                     // "No" Button
  //                     TextButton(
  //                       onPressed: isLoadingNo
  //                           ? null
  //                           : () async {
  //                         setState(() => isLoadingNo = true);
  //
  //                         await provider.updateConfiguration(
  //                           context,
  //                           mainId,
  //                           generateRatingKey(star.toString()),
  //                           level,
  //                           value,
  //                           "false",
  //                           accountId: widget.accountId,
  //                           subAccountId: widget.subaccountId,
  //                         );
  //
  //                         setState(() => isLoadingNo = false);
  //                         if (!provider.isLoading) Navigator.pop(context, false);
  //                       },
  //                       style: TextButton.styleFrom(
  //                         side: BorderSide(color: AppColors.primaryMain, width: 1.5),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                       ),
  //                       child: isLoadingNo
  //                           ? SizedBox(
  //                         height: 24,
  //                         width: 24,
  //                         child: CircularProgressIndicator(
  //                           color: AppColors.primaryMain,
  //                           strokeWidth: 3,
  //                         ),
  //                       )
  //                           : Text(
  //                         'No',
  //                         style: typography.Body1.copyWith(
  //                             color: AppColors.primaryMain),
  //                       ),
  //                     ),
  //
  //                     SizedBox(width: 10),
  //
  //                     // "Yes" Button
  //                     TextButton(
  //                       onPressed: isLoadingYes
  //                           ? null
  //                           : () async {
  //                         setState(() => isLoadingYes = true);
  //
  //                         await provider.updateConfiguration(
  //                           context,
  //                           mainId,
  //                           generateRatingKey(star.toString()),
  //                           level,
  //                           value,
  //                           "true",
  //                           accountId: widget.accountId,
  //                           subAccountId: widget.subaccountId,
  //                         );
  //
  //                         setState(() => isLoadingYes = false);
  //                         if (!provider.isLoading) Navigator.pop(context, true);
  //                       },
  //                       style: TextButton.styleFrom(
  //                         backgroundColor: AppColors.primaryMain,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                       ),
  //                       child: isLoadingYes
  //                           ? SizedBox(
  //                         width: 20,
  //                         height: 20,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           color: Colors.white,
  //                         ),
  //                       )
  //                           : Text(
  //                         'Save',
  //                         style: typography.Body1.copyWith(color: Colors.white),
  //                       ),
  //                     ),
  //                   ],
  //                 );
  //               },
  //             );
  //
  //           //   StatefulBuilder(
  //           //   builder: (context, setState) {
  //           //     bool isLoading = false; // Loader for "Yes" button
  //           //     bool isLoading1 = false;
  //           //
  //           //     return AlertDialog(
  //           //       title: Row(
  //           //         children: [
  //           //           Container(
  //           //             width: MediaQuery.of(context).size.width / 2,
  //           //             child: Text(
  //           //               'Do you want to apply this change globally?',
  //           //               maxLines: 2,
  //           //             ),
  //           //           ),
  //           //           IconButton(
  //           //             onPressed: () {
  //           //               Navigator.pop(context);
  //           //             },
  //           //             icon: Icon(Icons.close),
  //           //           ),
  //           //         ],
  //           //       ),
  //           //       actions: [
  //           //         TextButton(
  //           //           onPressed: isLoading1
  //           //               ? null
  //           //               : () async {
  //           //                   setState(() {
  //           //                     isLoading1 = true;
  //           //                   });
  //           //
  //           //                   // String key = 'subscribe.$vendorId.is_subscribed';
  //           //
  //           //                   await provider.updateConfiguration(
  //           //                     context,
  //           //                     mainId,
  //           //                     generateRatingKey(star.toString()),
  //           //                     level,
  //           //                     value,
  //           //                     "false",
  //           //                     accountId: widget.accountId,
  //           //                     subAccountId: widget.subaccountId,
  //           //                   );
  //           //
  //           //                   setState(() {
  //           //                     isLoading1 = false;
  //           //                   });
  //           //
  //           //                   if (!provider.isLoading) Navigator.pop(context);
  //           //                 },
  //           //           style: TextButton.styleFrom(
  //           //             side: BorderSide(
  //           //                 color: AppColors.primaryMain, width: 1.5),
  //           //             shape: RoundedRectangleBorder(
  //           //               borderRadius: BorderRadius.circular(8),
  //           //             ),
  //           //           ),
  //           //           child: isLoading1
  //           //               ? SizedBox(
  //           //                   height: 24,
  //           //                   width: 24,
  //           //                   child: CircularProgressIndicator(
  //           //                     color: AppColors.primaryMain,
  //           //                     strokeWidth: 3,
  //           //                   ),
  //           //                 )
  //           //               : Text(
  //           //                   'No1',
  //           //                   style: typography.Body1.copyWith(
  //           //                       color: AppColors.primaryMain),
  //           //                 ),
  //           //         ),
  //           //         SizedBox(width: 10),
  //           //         TextButton(
  //           //           onPressed: isLoading
  //           //               ? null
  //           //               : () async {
  //           //                   setState(() => isLoading = true);
  //           //
  //           //                   await provider.updateConfiguration(
  //           //                     context,
  //           //                     mainId,
  //           //                     generateRatingKey(star.toString()),
  //           //                     level,
  //           //                     value,
  //           //                     "true",
  //           //                     accountId: widget.accountId,
  //           //                     subAccountId: widget.subaccountId,
  //           //                   );
  //           //
  //           //                   setState(() => isLoading = false);
  //           //
  //           //                   if (!provider.isLoading)
  //           //                     Navigator.pop(context, true);
  //           //                 },
  //           //           child: SizedBox(
  //           //             width: 80, // Consistent button width
  //           //             height: 24,
  //           //             child: Center(
  //           //               child: isLoading
  //           //                   ? SizedBox(
  //           //                       width: 20,
  //           //                       height: 20,
  //           //                       child:
  //           //                           CircularProgressIndicator(strokeWidth: 2),
  //           //                     )
  //           //                   : Text(
  //           //                       'Save',
  //           //                       style: typography.Body1.copyWith(
  //           //                           color: AppColors.primaryMain),
  //           //                     ),
  //           //             ),
  //           //           ),
  //           //         ),
  //           //       ],
  //           //     );
  //           //   },
  //           // );
  //         },
  //       ) ??
  //       false; // Default to false if dialog is dismissed
  // }

  void _updateSubscription(
      String vendorId, bool isSubscribed, String mainId, String level) {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final provider =
            Provider.of<ConfigurationProvider>(context, listen: false);
        bool isLoading = false;
        bool isLoading1 = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(
                      'Do you want to apply this change globally?',
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading1
                      ? null
                      : () async {
                          setState(() {
                            isLoading1 = true;
                          });

                          String key = 'subscribe.$vendorId.is_subscribed';

                          await provider.updateConfiguration(
                            context,
                            mainId,
                            key,
                            level,
                            !isSubscribed,
                            "false",
                          );

                          setState(() {
                            isLoading1 = false;
                          });

                          if (!provider.isLoading) {
                            Navigator.pop(context);
                          }

                          await loadConfiguration();
                        },
                  style: TextButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryMain, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading1
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryMain,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'No',
                          style: typography.Body1.copyWith(
                            color: AppColors.primaryMain,
                          ),
                        ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          try {
                            String key = 'subscribe.$vendorId.is_subscribed';

                            await provider.updateConfiguration(
                              context,
                              mainId,
                              key,
                              level,
                              !isSubscribed,
                              "true",
                              accountId: widget.accountId,
                              subAccountId: widget.subaccountId,
                            );

                            await loadConfiguration();
                          } finally {
                            setState(() => isLoading = false);
                          }

                          // Delay pop to ensure UI updates
                          Future.delayed(Duration(milliseconds: 200), () {
                            if (mounted) Navigator.pop(context);
                          });
                        },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.primaryMain, width: 2),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 24,
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryMain,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'Yes',
                              style: typography.Body1.copyWith(
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     final provider =
    //         Provider.of<ConfigurationProvider>(context, listen: false);
    //     bool isLoading = false;
    //     bool isLoading1 = false;
    //
    //     return StatefulBuilder(
    //       builder: (context, setState) {
    //         return AlertDialog(
    //           title: Row(
    //             children: [
    //               Container(
    //                 width: MediaQuery.of(context).size.width / 2,
    //                 child: Text(
    //                   'Do you want to apply this change globally?',
    //                   maxLines: 2,
    //                 ),
    //               ),
    //               IconButton(
    //                   onPressed: isLoading
    //                       ? null
    //                       : () async {
    //                           setState(() => isLoading = true);
    //
    //                           try {
    //                             String key =
    //                                 'subscribe.$vendorId.is_subscribed';
    //
    //                             await provider.updateConfiguration(
    //                               context,
    //                               mainId,
    //                               key,
    //                               level,
    //                               !isSubscribed,
    //                               "false",
    //                               accountId: widget.accountId,
    //                               subAccountId: widget.subaccountId,
    //                             );
    //
    //                             await loadConfiguration(); // Ensure this completes
    //                           } finally {
    //                             setState(() => isLoading = false);
    //                             Navigator.pop(
    //                                 context); // Close dialog in finally block
    //                           }
    //                         },
    //                   icon: Icon(Icons.close))
    //             ],
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: isLoading1
    //                   ? null
    //                   : () async {
    //                       setState(() {
    //                         isLoading1 = true;
    //                       });
    //
    //                       String key = 'subscribe.$vendorId.is_subscribed';
    //
    //                       await provider.updateConfiguration(
    //                         context,
    //                         mainId,
    //                         key,
    //                         level,
    //                         !isSubscribed,
    //                         "false",
    //                       );
    //                       setState(() {
    //                         isLoading1 = false;
    //                       });
    //                       if (!provider.isLoading) Navigator.pop(context);
    //                       await loadConfiguration();
    //                     },
    //               style: TextButton.styleFrom(
    //                 side: BorderSide(color: AppColors.primaryMain, width: 1.5),
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.circular(8),
    //                 ),
    //               ),
    //               child: isLoading1
    //                   ? SizedBox(
    //                       height: 24,
    //                       width: 24,
    //                       child: CircularProgressIndicator(
    //                         color: AppColors.primaryMain,
    //                         strokeWidth: 3,
    //                       ),
    //                     )
    //                   : Text(
    //                       'No',
    //                       style: typography.Body1.copyWith(
    //                           color: AppColors.primaryMain),
    //                     ),
    //             ),
    //             SizedBox(width: 10),
    //             TextButton(
    //               onPressed: isLoading
    //                   ? null
    //                   : () async {
    //                 setState(() => isLoading = true);
    //
    //                 try {
    //                   String key = 'subscribe.$vendorId.is_subscribed';
    //
    //                   await provider.updateConfiguration(
    //                     context,
    //                     mainId,
    //                     key,
    //                     level,
    //                     !isSubscribed,
    //                     "true",
    //                     accountId: widget.accountId,
    //                     subAccountId: widget.subaccountId,
    //                   );
    //
    //                   await loadConfiguration(); // Ensure this completes
    //                 } finally {
    //                   setState(() => isLoading = false);
    //                 }
    //
    //                 // Delay popping the dialog to ensure UI updates
    //                 if (mounted) {
    //                   Navigator.pop(context);
    //                 }
    //               },
    //               style: TextButton.styleFrom(
    //                 backgroundColor: AppColors.primaryMain,
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.circular(8),
    //                   side: BorderSide(color: AppColors.primaryMain, width: 2),
    //                 ),
    //                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //               ),
    //               child: SizedBox(
    //                 width: 80,
    //                 height: 24,
    //                 child: Center(
    //                   child: isLoading
    //                       ? SizedBox(
    //                     height: 24,
    //                     width: 24,
    //                     child: CircularProgressIndicator(
    //                       color: AppColors.primaryMain,
    //                       strokeWidth: 3,
    //                     ),
    //                   )
    //                       : Text(
    //                     'Yes',
    //                     style: typography.Body1.copyWith(
    //                       color: Colors.black,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //
    //
    //
    //           ],
    //         );
    //       },
    //     );
    //   },
    // );
  }

  // void _updateSubscription(
  //     String vendorId, bool isSubscribed, String mainId, String level) {
  //   var typography = CustomTypography(context);
  //   bool isLoading = false; // Moved outside StatefulBuilder to persist state
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       final provider =
  //           Provider.of<ConfigurationProvider>(context, listen: false);
  //
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: Text('Update Subscription'),
  //             content: Text(
  //               isSubscribed
  //                   ? 'Do you want to unsubscribe from this vendor?'
  //                   : 'Do you want to subscribe to this vendor?',
  //               style: typography.Body1,
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: isLoading ? null : () => Navigator.pop(context),
  //                 child: Text(
  //                   'Cancel',
  //                   style:
  //                       typography.Body1.copyWith(color: AppColors.primaryMain),
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: isLoading
  //                     ? null
  //                     : () async {
  //                         setState(() => isLoading = true);
  //
  //                         String key = 'subscribe.$vendorId.is_subscribed';
  //
  //                         await provider.updateConfiguration(
  //                           context,
  //                           mainId,
  //                           key,
  //                           level,
  //                           !isSubscribed,
  //                           accountId: widget.accountId,
  //                           subAccountId: widget.subaccountId,
  //                         );
  //
  //                         setState(() => isLoading = false);
  //
  //                         Navigator.pop(context); // Close dialog
  //                         loadConfiguration();
  //                       },
  //                 child: SizedBox(
  //                   width: 80, // Ensures consistent button size
  //                   height: 24,
  //                   child: Center(
  //                     child: isLoading
  //                         ? SizedBox(
  //                             width: 20,
  //                             height: 20,
  //                             child: CircularProgressIndicator(strokeWidth: 2),
  //                           )
  //                         : Text(
  //                             'Save',
  //                             style: typography.Body1.copyWith(
  //                                 color: AppColors.primaryMain),
  //                           ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildStarCheckbox(
    String title,
    String description,
    CustomTypography typography,
    bool isDisabled,
    String mainId,
    String level,
  ) {
    bool isStarDisabled = ['3', '4', '5'].contains(title);
    bool isChecked = selectedStars.contains(int.parse(title));

    // Define if the checkbox should be enabled
    bool canEdit = isPgAdmin || isAdmin || isSuperAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isChecked
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (isStarDisabled || !canEdit)
                ? null // Disable checkbox if not an admin
                : (bool? value) async {
                    if (value == null) return;

                    final provider = Provider.of<ConfigurationProvider>(context,
                        listen: false);

                    if (widget.updateallflag != "false") {
                      // Show confirmation dialog before proceeding
                      bool shouldSave = await _showSaveDialogForStar(
                        int.parse(title),
                        description,
                        typography,
                        value,
                        mainId,
                        level,
                      );

                      if (shouldSave) {
                        // Fetch updated configuration after the dialog
                        await provider.getConfiguration(
                          accountId: widget.accountId,
                          subAccountId: widget.subaccountId,
                          updateallflag: widget.updateallflag,
                        );
                        await provider.getVendors();

                        if (mounted) {
                          loadConfiguration();
                        }
                      }
                    } else {
                      // Directly update without confirmation
                      await provider
                          .updateConfiguration(
                        context,
                        accountId: widget.accountId,
                        mainId,
                        generateRatingKey(title),
                        "sub_account",
                        value,
                        subAccountId: widget.subaccountId,
                        false,
                        checklevel: widget.level,
                      )
                          .then((_) {
                        provider.getVendors();
                        loadConfiguration(); // Call only after update is successful
                      }).catchError((error) {
                        print("Failed to update configuration: $error");
                      });
                    }
                    // // Show confirmation dialog before proceeding
                    // bool shouldSave = await _showSaveDialogForStar(
                    //   int.parse(title),
                    //   description,
                    //   typography,
                    //   value,
                    //   mainId,
                    //   level,
                    // );

                    // if (shouldSave) {
                    //   // Fetch updated configuration after the dialog
                    //   await provider.getConfiguration(
                    //     accountId: widget.accountId,
                    //     subAccountId: widget.subaccountId,
                    //   );
                    //   await provider.getVendors();
                    //
                    //   if (mounted) {
                    //     loadConfiguration();
                    //   }
                    // }
                  },
            activeColor: AppColors.primaryMain,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title Star',
                  style: typography.Body1.copyWith(
                    fontWeight:
                        isStarDisabled ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: typography.Caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStarCheckbox(
  //     String title,
  //     String description,
  //     CustomTypography typography,
  //     bool isDisabled,
  //     String mainId,
  //     String level) {
  //   bool isStarDisabled = ['3', '4', '5'].contains(title);
  //   bool isChecked = selectedStars.contains(int.parse(title));
  //
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 8),
  //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  //     decoration: BoxDecoration(
  //       color: isChecked
  //           ? Theme.of(context).colorScheme.surfaceContainerHigh
  //           : Theme.of(context).colorScheme.surfaceContainerLowest,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Checkbox(
  //           value: isChecked,
  //           onChanged: isStarDisabled
  //               ? null
  //               : (bool? value) async {
  //                   if (value == null) return;
  //
  //                   final provider = Provider.of<ConfigurationProvider>(context,
  //                       listen: false);
  //
  //                   // Show confirmation dialog before proceeding
  //                   bool shouldSave = await _showSaveDialogForStar(
  //                     int.parse(title),
  //                     description,
  //                     typography,
  //                     value,
  //                     mainId,
  //                     level,
  //                   );
  //
  //                   if (shouldSave) {
  //                     // Fetch updated configuration after the dialog
  //                     await provider.getConfiguration(
  //                       accountId: widget.accountId,
  //                       subAccountId: widget.subaccountId,
  //                     );
  //                     await provider.getVendors();
  //
  //                     if (mounted) {
  //                       loadConfiguration();
  //                     }
  //                   }
  //                 },
  //           activeColor: AppColors.primaryMain,
  //         ),
  //         SizedBox(width: 16),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 '$title Star',
  //                 style: typography.Body1.copyWith(
  //                   fontWeight:
  //                       isStarDisabled ? FontWeight.bold : FontWeight.normal,
  //                 ),
  //               ),
  //               SizedBox(height: 4),
  //               Text(
  //                 description,
  //                 style: typography.Caption,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSubscriptionCard(
    String id,
    String iconPath,
    String title,
    String description,
    String name,
    bool isSubscribed,
    String mainId,
    String level,
    CustomTypography typography,
  ) {
    bool canEdit = isPgAdmin || isAdmin || isSuperAdmin;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CachedNetworkImage(
                  imageUrl: iconPath,
                  width: 40,
                  height: 40,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(title.toString() ==
                                  "Hurricane (Kinetic Analysis Corporation)"
                              ? "Hurricane Event Monitoring Subscription"
                              : "Earthquake Event Monitoring Subscription"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title.toString() ==
                                      "Hurricane (Kinetic Analysis Corporation)"
                                  ? "Get real-time hurricane alerts and automated tracking."
                                  : "The Earthquake Event Monitoring Subscription keeps you updated with timely alerts on seismic activity."),
                              SizedBox(height: 8),
                              Text("Key Information:"),
                              SizedBox(height: 10),
                              _buildBulletPoint(
                                  "Activation: Monitoring begins 24 hours after subscribing."),
                              _buildBulletPoint(title.toString() ==
                                      "Hurricane (Kinetic Analysis Corporation)"
                                  ? "Automatic Tracking: New locations added start monitoring within 24 hours."
                                  : "Automatic Location Tracking: New locations monitoring starts after 24 hours."),
                              _buildBulletPoint(
                                  "Event Alerts: Alerts every 6 hours on potential impacts."),
                              SizedBox(height: 8),
                              Text("Subscribe now."),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Icon(Icons.info, size: 20),
                ),
              ],
            ),
            SizedBox(height: CustomSpacing.three),
            Text(
              title,
              style: typography.Body1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: CustomSpacing.one),
            Text(
              description,
              style: typography.Caption,
            ),
            SizedBox(height: CustomSpacing.two),

            // Show "Subscribed" label if user is not an admin
            if (!canEdit)
              Text(
                'Subscribed',
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryMain,
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  _updateSubscription(id, isSubscribed, mainId, level);
                  final provider = Provider.of<ConfigurationProvider>(context,
                      listen: false);
                  provider.getConfiguration(
                    accountId: widget.accountId,
                    subAccountId: widget.subaccountId,
                    updateallflag: widget.updateallflag,
                  );
                  provider.getVendors();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSubscribed ? Colors.amber : AppColors.primaryMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isSubscribed ? 'Unsubscribe' : 'Subscribe ',
                  style: typography.Body1.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),

            // Show Data Provider name if available
            if (name.isNotEmpty)
              Text(
                'Data Provider: $name',
                style: typography.Caption,
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSubscriptionCard(
  //   String id,
  //   String iconPath,
  //   String title,
  //   String description,
  //   String name,
  //   bool isSubscribed,
  //   String mainId,
  //   String level,
  //   CustomTypography typography,
  // ) {
  //   return Card(
  //     color: Theme.of(context).colorScheme.surfaceContainerHigh,
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Image.network(
  //             iconPath,
  //             width: 40,
  //             height: 40,
  //           ),
  //           SizedBox(height: CustomSpacing.three),
  //           Text(
  //             title,
  //             style: typography.Body1.copyWith(
  //               fontWeight: FontWeight.w600,
  //               fontSize: 18,
  //             ),
  //           ),
  //           SizedBox(height: CustomSpacing.one),
  //           Text(
  //             description,
  //             style: typography.Caption,
  //           ),
  //           SizedBox(height: CustomSpacing.two),
  //           ElevatedButton(
  //             onPressed: () {
  //               _updateSubscription(id, isSubscribed, mainId, level);
  //               final provider =
  //                   Provider.of<ConfigurationProvider>(context, listen: false);
  //               provider.getConfiguration(
  //                 accountId: widget.accountId,
  //                 subAccountId: widget.subaccountId,
  //               );
  //               provider.getVendors();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor:
  //                   isSubscribed ? Colors.amber : AppColors.primaryMain,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //             ),
  //             child: Text(
  //               isSubscribed ? 'Unsubscribe' : 'Subscribe Now',
  //               style: typography.Body1.copyWith(
  //                 color: Colors.black,
  //               ),
  //             ),
  //           ),
  //           name.isEmpty
  //               ? SizedBox.shrink()
  //               : Text(
  //                   'Data Provider: $name',
  //                   style: typography.Caption,
  //                 ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String generateServiceKey(String serviceName) {
    return 'services.$serviceName.enabled';
  }

  String generateRatingKey(String ratingId) {
    return 'geocoding_rating_enabled.$ratingId.enabled';
  }

  String generateSubscriptionKey(String vendorId) {
    return 'subscribe.$vendorId.is_subscribed';
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

Widget accountNameInput({
  required TextEditingController controller,
  required bool isLoading,
  required VoidCallback onSubmit,
}) {
  final TextEditingController _safeController = TextEditingController(
      text: controller.text == "null" ? "" : controller.text ?? '');

  return Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _safeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Please write the account name',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        /// Submit Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DB9F6),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    ),
  );
}
