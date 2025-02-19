import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../design_system/primitives/utilities/custom_spacing.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../providers/configuration_provider.dart';

class ConfigurationTab extends StatefulWidget {
  final String? accountId;
  final String? subaccountId;

  const ConfigurationTab({
    Key? key,
    this.accountId,
    this.subaccountId,
  }) : super(key: key);

  @override
  _ConfigurationTabState createState() => _ConfigurationTabState();
}

class _ConfigurationTabState extends State<ConfigurationTab> {
  List<String> selectedServices = [];
  List<int> selectedStars = [];
  List<dynamic> vendorList = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ConfigurationProvider>(context, listen: false);

    Future.wait([
      provider.getConfiguration(
        accountId: widget.accountId,
        subAccountId: widget.subaccountId,
      ),
      provider.getVendors()
    ]).then((value) {
      var config = provider.configurations['result'] ?? {};
      var services = config['services'] ?? {};
      var ratings = config['geocoding_rating_enabled'] ?? {};
      if (mounted) {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          setState(() {
            vendorList = provider.vendors['result'] ?? [];
            selectedServices = services.entries
                .where(
                    (e) => (e.value as Map<String, dynamic>)['enabled'] == true)
                .map<String>((e) => capitalize(e.key))
                .toList();

            print("Selected Services: $selectedServices");

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
        WidgetsBinding.instance!.addPostFrameCallback((_) {
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

        WidgetsBinding.instance!.addPostFrameCallback((_) {
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: CustomSpacing.four),
                Text(
                  'Select the services you need',
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
                    services[key]['enabled'],
                    typography,
                    mainId,
                    level,
                  ),

                SizedBox(height: CustomSpacing.six),
                Text(
                  'Set the geocode ratings for which the hazard risk score should be calculated',
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

                SizedBox(height: CustomSpacing.four),
                Text(
                  'Get hazard event notifications by subscribing to live catastrophic event monitoring',
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: CustomSpacing.two),

                // Dynamic Subscription Cards
                // Dynamic Subscription Cards
                ...subscriptions.keys.map((key) {
                  final parts = key.split('_');
                  if (parts.length != 2) {
                    debugPrint('Invalid subscription key format: $key');
                    return SizedBox.shrink();
                  }

                  final vendorId = parts[0];
                  final hazardName = parts[1];

                  // Find the vendor by vendor_id
                  final vendor = vendorList.firstWhere(
                    (vendor) => vendor['vendor_id'] == vendorId,
                    orElse: () {
                      debugPrint('Vendor not found for ID: $vendorId');
                      return null;
                    },
                  );

                  if (vendor == null) return SizedBox.shrink();

                  // Find the hazard in the vendor's hazard_commercials by hazard_name
                  final hazardCommercials =
                      vendor['hazard_commercials'] as List?;
                  final hazard = hazardCommercials?.firstWhere(
                    (commercial) => commercial['hazard_name'] == hazardName,
                    orElse: () {
                      debugPrint(
                          'Hazard not found for name: $hazardName in Vendor ID: $vendorId');
                      return null;
                    },
                  );

                  if (hazard == null) return SizedBox.shrink();

                  // Extract subscription and hazard details
                  final subscription = subscriptions[key];
                  final vendorName = vendor['vendor_name_label'] ?? '';
                  final vendorImage = vendor['display_image_url'] ??
                      'assets/images/default_vendor.png';
                  final hazardLabel =
                      hazard['hazard_name_label'] ?? 'Unknown Hazard';
                  final description = subscription['description'] ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSubscriptionCard(
                        key,
                        vendorImage,
                        '$hazardLabel ($vendorName)',
                        description.isNotEmpty ? description : vendorName,
                        '$vendorName',
                        subscription['is_subscribed'] == true ||
                            subscription['is_subscribed'] == 'true',
                        mainId,
                        level,
                        typography,
                      ),
                      SizedBox(height: CustomSpacing.one),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
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

  Widget _buildServiceCheckbox(String title, String description, bool isEnabled,
      CustomTypography typography, String mainId, String level) {
    bool isGeocoding = title.toLowerCase() == 'geocoding';
    bool isSelected = selectedServices.contains(title) || isGeocoding;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isEnabled || isGeocoding
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: isGeocoding || title == "Additional_parameters"
                ? null // Disable checkbox for Geocoding
                : (bool? value) {
                    print('Toggling up $title to $value');

                    // Show dialog to save changes
                    _showSaveDialog(
                        title, description, typography, value!, mainId, level);
                  },
            activeColor: AppColors.primaryMain,
          ),
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
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Save Configuration'),
              content: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Text(
                      'Do you want to save this configuration for $title?',
                      style: typography.Body1,
                    ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!isLoading) Navigator.pop(context);
                  },
                  child: Text('Cancel',
                      style: typography.Body1.copyWith(
                          color: AppColors.primaryMain)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => isLoading = true);

                    var key = generateServiceKey(
                        title.toLowerCase().replaceAll(' ', '_'));
                    await provider.updateConfiguration(
                      context,
                      mainId,
                      key, // Ensure key is used here correctly
                      level,
                      value,
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                    );

                    setState(() => isLoading = false);

                    if (!provider.isLoading) {
                      Navigator.pop(context); // Close the dialog
                      setState(() {}); // Reload the page by calling setState
                      final provider = Provider.of<ConfigurationProvider>(
                          context,
                          listen: false);

                      provider.getConfiguration(
                        accountId: widget.accountId,
                        subAccountId: widget.subaccountId,
                      );
                      provider.getVendors();
                    }
                  },
                  child: Text('Save',
                      style: typography.Body1.copyWith(
                          color: AppColors.primaryMain)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSaveDialogForStar(int star, String description,
      CustomTypography typography, bool value, String mainId, String level) {
    var typography = CustomTypography(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final provider =
            Provider.of<ConfigurationProvider>(context, listen: false);
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Save Configuration'),
              content: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Text(
                      'Do you want to save this configuration for $star-star rating?',
                      style: typography.Body1,
                    ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!isLoading) Navigator.pop(context);
                  },
                  child: Text('Cancel',
                      style: typography.Body1.copyWith(
                          color: AppColors.primaryMain)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => isLoading = true);

                    await provider.updateConfiguration(
                      context,
                      mainId,
                      generateRatingKey(star.toString()),
                      level,
                      value,
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                    );

                    setState(() => isLoading = false);
                    if (!provider.isLoading) Navigator.pop(context);
                  },
                  child: Text('Save',
                      style: typography.Body1.copyWith(
                          color: AppColors.primaryMain)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Subscription'),
              content: Text(
                isSubscribed
                    ? 'Do you want to unsubscribe from this vendor?'
                    : 'Do you want to subscribe to this vendor?',
                style: typography.Body1,
              ),
              actions: [
                TextButton(
                  onPressed: provider.isLoading
                      ? null
                      : () {
                          if (!provider.isLoading) Navigator.pop(context);
                        },
                  child: Text(
                    'Cancel',
                    style:
                        typography.Body1.copyWith(color: AppColors.primaryMain),
                  ),
                ),
                TextButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          String key = 'subscribe.$vendorId.is_subscribed';

                          await provider.updateConfiguration(
                            context,
                            mainId,
                            key,
                            level,
                            !isSubscribed,
                            accountId: widget.accountId,
                            subAccountId: widget.subaccountId,
                          );

                          setState(() {
                            isLoading = false;
                          });

                          if (!provider.isLoading) Navigator.pop(context);
                        },
                  child: provider.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                height: 38,
                                width: 38,
                                child: CircularProgressIndicator()),
                          ],
                        )
                      : Text(
                          'Save',
                          style: typography.Body1.copyWith(
                              color: AppColors.primaryMain),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStarCheckbox(
      String title,
      String description,
      CustomTypography typography,
      bool isDisabled,
      String mainId,
      String level) {
    bool isStarDisabled = ['3', '4', '5'].contains(title);
    bool isChecked = selectedStars.contains(int.parse(title));

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
            onChanged: isStarDisabled
                ? null
                : (bool? value) {
                    final provider = Provider.of<ConfigurationProvider>(context,
                        listen: false);
                    _showSaveDialogForStar(
                      int.parse(title),
                      description,
                      typography,
                      value!,
                      mainId,
                      level,
                    );
                    provider.getConfiguration(
                      accountId: widget.accountId,
                      subAccountId: widget.subaccountId,
                    );
                    provider.getVendors();
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
            Image.network(
              iconPath,
              width: 40,
              height: 40,
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
            ElevatedButton(
              onPressed: () {
                _updateSubscription(id, isSubscribed, mainId, level);
                final provider =
                    Provider.of<ConfigurationProvider>(context, listen: false);
                provider.getConfiguration(
                  accountId: widget.accountId,
                  subAccountId: widget.subaccountId,
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
                isSubscribed ? 'Unsubscribe' : 'Subscribe Now',
                style: typography.Body1.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            name.isEmpty
                ? SizedBox.shrink()
                : Text(
                    'Data Provider: $name',
                    style: typography.Caption,
                  ),
          ],
        ),
      ),
    );
  }

  String generateServiceKey(String serviceName) {
    return 'services.$serviceName.enabled';
  }

  String generateRatingKey(String ratingId) {
    return 'geocoding_rating_enabled.$ratingId.enabled';
  }

  String generateSubscriptionKey(String vendorId) {
    return 'subscribe.$vendorId.is_subscribed';
  }
}
