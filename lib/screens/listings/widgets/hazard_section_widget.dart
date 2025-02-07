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
      height: 200, // Adjusted height for better visibility
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
                      style: typography.Body2.copyWith(fontWeight: FontWeight.w500),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

    hazard.others?.forEach((vendorName, details) {
      vendorWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVendorRow(
                vendorName,
                _getFormattedValue(vendorName, details.value), // ✅ Add unit dynamically
                typography,
              ),
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

  /// ✅ Function to Append Units Conditionally
  String _getFormattedValue(String vendor, dynamic value) {
    if (value == null) return "N/A";

    // **Conditionally add units based on vendor type**
    if (vendor.contains("KinetiCast") && value is num) {
      return "$value mph"; // ✅ Wind Speed
    }
    if (vendor.contains("GlobalEarthquakeModel") && value is num) {
      return "$value %g"; // ✅ PGA for Earthquake
    }
    if (vendor.contains("MODIS") && value is num) {
      return "$value K"; // ✅ Temperature in Kelvin
    }
    if (vendor.contains("JRCOD") && value is num) {
      return "$value ft"; // ✅ Flood Depth in feet
    }
    if (vendor.contains("MarshMcLennan") && value is num) {
      return "$value"; // No unit needed for risk scores
    }

    return value.toString();
  }

  Widget _buildVendorRow(String vendor, String value, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "$vendor:",
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
