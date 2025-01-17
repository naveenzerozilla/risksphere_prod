import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../models/my_location_list_model.dart';

class HazardsSection extends StatelessWidget {
  final Map<String, HazardDetails> hazards;
  final List<Color> scoreColors = [
    Colors.grey[300]!,
    Colors.red[900]!,
    Colors.red[300]!,
    Colors.yellow[300]!,
    Colors.green[300]!,
    Colors.green[600]!,
  ];

  HazardsSection({required this.hazards});

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Container(
      height: 200, // Fixed height for the section
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            children: hazards.entries.map((entry) {
              final hazardName = entry.key;
              final hazard = entry.value;
              final rating = hazard.rating ?? 0;
              final color = rating >= 0 && rating < scoreColors.length
                  ? scoreColors[rating]
                  : Colors.grey;

              return ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hazardName,
                      style:
                      typography.Body2.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rating != 0 ? rating.toString() : 'N/A',
                        style: typography.Body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurface),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: _buildVendorDetails(hazard, typography),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorDetails(HazardDetails hazard, CustomTypography typography) {
    final List<Widget> vendorWidgets = [];

    // Add primary vendor details
    if (hazard.vendorName != null) {
      vendorWidgets.add(_buildVendorRow(
        "Reported by",
        hazard.vendorName!,
        typography,
      ));
    }

    // Add other vendor details
    hazard.others?.forEach((vendorName, details) {
      vendorWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVendorRow(
                  "Risk Impact", details.value?.toString() ?? "N/A", typography),
            ],
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vendorWidgets,
    );
  }

  Widget _buildVendorRow(String key, String value, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$key:",
            style: typography.Caption.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: typography.Caption,
          ),
        ],
      ),
    );
  }
}
