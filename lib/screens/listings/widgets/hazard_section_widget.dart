import 'package:collection/collection.dart';
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

  final Map<String, int> hazardOrder = {
    'Hurricane': 1,
    'Earthquake': 2,
    'Wildfire': 3,
    'CoastalFlood': 4,
    'RiverineFlood': 5,
    'Avalanche': 6,
    'ColdWave': 7,
    // 'CommunityResilience': 8,
    'Drought': 8,
    'Hail': 9,
    'HeatWave': 10,
    'IceStorm': 11,
    'Landslide': 12,
    'Lightning': 13,
    'StrongWind': 14,
    // 'Overall': 15,
    // 'SocialVulnerability': 16,
    'Tornado': 15,
    'Tsunami': 16,
    'VolcanicActivity': 17,
    'WinterWeather': 18,
  };

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    return Container(
      height: 200, // Adjusted height for better visibility
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            children: hazards.entries.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No risk score data to show",
                        style: typography.Body2.copyWith(
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]
                : hazards.entries
                    .toList()
                    .where((entry) =>
                        entry.key != "Overall") // 👈 filter out "Overall"
                    .sorted((a, b) {
                    final orderA = hazardOrder[a.key] ?? 999;
                    final orderB = hazardOrder[b.key] ?? 999;
                    return orderA.compareTo(orderB);
                  }).map((entry) {
                    final hazardName = entry.key;
                    final hazard = entry.value;
                    final rating = hazard.rating ?? 0;
                    final intRating = int.tryParse(rating.toString()) ?? -1; // Safely parse it, defaulting to -1 if invalid

                    final color = (intRating >= 0 && intRating < scoreColors.length)
                        ? scoreColors[intRating]
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
                            style: typography.Body2.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rating != 0 ? rating.toString() : 'N/A',
                              style: typography.Body2.copyWith(
                                color: rating == 3
                                    ? Colors.black
                                    : Colors.white,
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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
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

            // hazards.entries.toList().sorted((a, b) {
            //         final orderA =
            //             hazardOrder[a.key] ?? 999; // If not found, put at end
            //         final orderB = hazardOrder[b.key] ?? 999;
            //         return orderA.compareTo(orderB);
            //       }).map((entry) {
            //         final hazardName = entry.key;
            //         final hazard = entry.value;
            //         final rating = hazard.rating ?? 0;
            //         final color = rating >= 0 && rating < scoreColors.length
            //             ? scoreColors[rating]
            //             : Colors.grey;
            //
            //         return ExpansionTile(
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
            //           title: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               Text(
            //                 hazardName,
            //                 style: typography.Body2.copyWith(
            //                     fontWeight: FontWeight.w500),
            //               ),
            //               Container(
            //                 padding: EdgeInsets.symmetric(
            //                     horizontal: 12, vertical: 8),
            //                 decoration: BoxDecoration(
            //                   color: color,
            //                   borderRadius: BorderRadius.circular(8),
            //                 ),
            //                 child: Text(
            //                   rating != 0 ? rating.toString() : 'N/A',
            //                   style: typography.Body2.copyWith(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.w500,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //           trailing: Icon(Icons.arrow_drop_down,
            //               color: Theme.of(context).colorScheme.onSurface),
            //           children: [
            //             Container(
            //               padding: const EdgeInsets.all(12.0),
            //               decoration: BoxDecoration(
            //                 color: Theme.of(context)
            //                     .colorScheme
            //                     .surfaceContainerHighest,
            //                 borderRadius: BorderRadius.circular(12),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.black12,
            //                     blurRadius: 4,
            //                     offset: Offset(0, 2),
            //                   ),
            //                 ],
            //               ),
            //               child: SingleChildScrollView(
            //                 child: _buildVendorDetails(hazard, typography),
            //               ),
            //             ),
            //           ],
            //         );
            //       }).toList(),
          ),

          // Column(
          //   children: hazards.entries.isEmpty
          //       ? [
          //           Padding(
          //             padding: const EdgeInsets.all(16.0),
          //             child: Text(
          //               "No risk score data to show",
          //               style: typography.Body2.copyWith(
          //                   fontWeight: FontWeight.w500),
          //             ),
          //           ),
          //         ]
          //       : hazards.entries.map((entry) {
          //           final hazardName = entry.key;
          //           final hazard = entry.value;
          //           final rating = hazard.rating ?? 0;
          //           final color = rating >= 0 && rating < scoreColors.length
          //               ? scoreColors[rating]
          //               : Colors.grey;
          //
          //           return ExpansionTile(
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(12),
          //             ),
          //             tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
          //             title: Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 Text(
          //                   hazardName,
          //                   style: typography.Body2.copyWith(
          //                       fontWeight: FontWeight.w500),
          //                 ),
          //                 Container(
          //                   padding: EdgeInsets.symmetric(
          //                       horizontal: 12, vertical: 8),
          //                   decoration: BoxDecoration(
          //                     color: color,
          //                     borderRadius: BorderRadius.circular(8),
          //                   ),
          //                   child: Text(
          //                     rating != 0 ? rating.toString() : 'N/A',
          //                     style: typography.Body2.copyWith(
          //                       color: Colors.white,
          //                       fontWeight: FontWeight.w500,
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             trailing: Icon(Icons.arrow_drop_down,
          //                 color: Theme.of(context).colorScheme.onSurface),
          //             children: [
          //               Container(
          //                 padding: const EdgeInsets.all(12.0),
          //                 decoration: BoxDecoration(
          //                   color: Theme.of(context)
          //                       .colorScheme
          //                       .surfaceContainerHighest,
          //                   borderRadius: BorderRadius.circular(12),
          //                   boxShadow: [
          //                     BoxShadow(
          //                       color: Colors.black12,
          //                       blurRadius: 4,
          //                       offset: Offset(0, 2),
          //                     ),
          //                   ],
          //                 ),
          //                 child: SingleChildScrollView(
          //                   child: _buildVendorDetails(hazard, typography),
          //                 ),
          //               ),
          //             ],
          //           );
          //         }).toList(),
          // ),
        ),
      ),
    );
  }

  Widget _buildVendorDetails(
      HazardDetails hazard, CustomTypography typography) {
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
                '${_getFormattedValue(vendorName, details.value)}',
                // ✅ Add unit dynamically
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
    // if (value == "nan/nan") return "N/A";

    // **Conditionally add units based on vendor type**
    if (vendor.contains("Kineticast") && value is num) {
      return "Wind Speed ${value.toStringAsFixed(3)} mph"; // ✅ Wind Speed
    }
    if (vendor.contains("GlobalEarthquakeModel") && value is num) {
      return "PGA: ${value.toStringAsFixed(3)}g"; // ✅ PGA for Earthquake
    }
    if (vendor.contains("Modis")) {
      return value == "nan/nan"
          ? "Temp(K) / FRP(MW) : -"
          : " Temp(K) / FRP(MW) :  $value"; // ✅ Temperature in Kelvin
    }
    if (vendor.contains("JRCOD") && value is num) {
      return "$value ft"; // ✅ Flood Depth in feet
    }
    if (vendor.contains("MarshMcLennan") && value is num) {
      return "Flood Score : $value"; // No unit needed for risk scores
    }
    if (vendor.contains("USGS") && value is num) {
      return "Flood Score : $value"; // No unit needed for risk scores
    }

    return value.toString();
  }

  Widget _buildVendorRow(
      String vendor, String value, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            value == "Not Applicable" || value == "No Rating"
                ? "Risk Impact : -"
                : value == "Relatively Moderate"
                    ? "Risk Impact : R.Moderate"
                    : value == "Very High"
                        ? "Risk Impact : V.High"
                        : value == "Very Low"
                            ? "Risk Impact : V.Low"
                            : value == "Relatively Low"
                                ? "Risk Impact : R.Low"
                                : value == "Relatively High"
                                    ? "Risk Impact : R.High"
                                    : value,
            style: typography.Body2.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            "Reported by " +
                (vendor == "MarshMcLennan"
                    ? "MM FRI"
                    : vendor == "Kineticast"
                        ? "Kinetic Cast"
                        : vendor == "Modis"
                            ? "MODIS"
                            : vendor == "GlobalEarthquakeModel"
                                ? "GEM"
                                : vendor),
            style: typography.Caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
