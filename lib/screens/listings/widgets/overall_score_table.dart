import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:RiskSphare/design_system/primitives/custom_typography.dart';
import '../../../models/my_location_list_model.dart';

class LocationTable extends StatefulWidget {
  final List<MyLocation> locations;

  LocationTable({required this.locations});

  @override
  _LocationTableState createState() => _LocationTableState();
}

class _LocationTableState extends State<LocationTable> {
  late List<String> hazardColumns;
  Map<String, bool> columnVisibility = {};
  bool showRiskScore = true;

  @override
  void initState() {
    super.initState();
    if (widget.locations.isNotEmpty) {
      hazardColumns = widget.locations.first.hazard?.keys.toList() ?? [];

      print(
          "Hazard Columns Found: $hazardColumns"); // Debugging print statement

      for (var hazard in hazardColumns) {
        columnVisibility[hazard] = true;
      }
    } else {
      hazardColumns = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final int visibleHazardsCount = hazardColumns
        .where((hazard) => columnVisibility[hazard] ?? true)
        .length;
    final double fixedColumnsWidth = MediaQuery.of(context).size.width * 0.9;
    final double hazardColumnsWidth = visibleHazardsCount * 150;
    final double dynamicMinWidth =
        fixedColumnsWidth + (hazardColumnsWidth > 0 ? hazardColumnsWidth : 300);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("See Risk Score", style: CustomTypography(context).Body1),
              Switch(
                value: showRiskScore,
                onChanged: (value) {
                  setState(() {
                    showRiskScore = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable2(
                isHorizontalScrollBarVisible: true,
                headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerLowest),
                columnSpacing: 0,
                fixedTopRows: 1,
                fixedLeftColumns: 1,
                minWidth: dynamicMinWidth,
                horizontalMargin: 12,
                bottomMargin: 20,
                dividerThickness: 1,
                dataRowHeight: !showRiskScore ? 160 : null,
                // Enables dynamic height

                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
                  style: BorderStyle.solid,
                  borderRadius: BorderRadius.circular(12),
                ),
                columns: [
                  DataColumn2(
                    fixedWidth: MediaQuery.of(context).size.width * 0.3,
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Location',
                            style: CustomTypography(context).InputLabel),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert),
                          onSelected: (String hazard) {
                            setState(() {
                              columnVisibility[hazard] =
                                  !(columnVisibility[hazard] ?? true);
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: "show",
                                child: ListTile(
                                  leading: Icon(Icons.visibility),
                                  title: Text("Show All Hazards",
                                      style: CustomTypography(context).Body2),
                                  onTap: () {
                                    setState(() {
                                      hazardColumns.forEach((hazard) {
                                        columnVisibility[hazard] = true;
                                      });
                                    });
                                  },
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: "hide",
                                child: ListTile(
                                  leading: Icon(Icons.visibility_off),
                                  title: Text("Hide All Hazards",
                                      style: CustomTypography(context).Body2),
                                  onTap: () {
                                    setState(() {
                                      hazardColumns.forEach((hazard) {
                                        columnVisibility[hazard] = false;
                                      });
                                    });
                                  },
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    size: ColumnSize.L,
                  ),

                  DataColumn2(
                    fixedWidth: MediaQuery.of(context).size.width * 0.3,
                    size: ColumnSize.L,
                    label: Text('Geocoding Score',
                        style: CustomTypography(context).InputLabel),
                  ),
                  DataColumn2(
                    fixedWidth: MediaQuery.of(context).size.width * 0.3,
                    size: ColumnSize.L,
                    label: Text('Hazard score',
                        style: CustomTypography(context).InputLabel),
                  ),

                  ...hazardColumns
                      .where((hazard) =>
                          hazard != 'Overall') // Filter out "Overall"
                      .map((hazard) {
                    print("Rendering Column: $hazard"); // Debugging print
                    return DataColumn2(
                      size: ColumnSize.L,
                      label: Text(hazard,
                          style: CustomTypography(context).InputLabel),
                    );
                  }).toList(),

                  // ...hazardColumns.map((hazard) {
                  //   print("Rendering Column: $hazard"); // Debugging print
                  //   return DataColumn2(
                  //     size: ColumnSize.L,
                  //     label: Text(hazard,
                  //         style: CustomTypography(context).InputLabel),
                  //   );
                  // }).toList(),
                ],
                rows: widget.locations.map((location) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          location.finalAddress?.address ?? '',
                          style: CustomTypography(context).Body2,
                          overflow: TextOverflow.ellipsis,
                          maxLines: showRiskScore ? 3 : 7,
                        ),
                      ),
                      DataCell(
                        _renderRiskScore(
                            location.finalAddress?.score), // ✅ Geocoding Score
                      ),
                      DataCell(
                        _renderRiskScore(
                            location.overallScore), // ✅ Overall Score
                      ),

                      ...hazardColumns
                          .where((hazard) =>
                              hazard != 'Overall') // Filter out "Overall"
                          .map((hazard) => DataCell(
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  child: location.hazard?.containsKey(hazard) ??
                                          false
                                      ? (showRiskScore
                                          ? _renderRiskScore(
                                              location.hazard?[hazard]?.rating)
                                          : _renderFormattedHazardData(
                                              location.hazard?[hazard],
                                              location.hazard?[hazard]?.rating))
                                      : Text("-",
                                          style: CustomTypography(context)
                                              .Body2
                                              .copyWith(color: Colors.grey)),
                                ),
                              ))
                          .toList(),

                      // ...hazardColumns
                      //     .map((hazard) => DataCell(
                      //           Container(
                      //             width: double.infinity,
                      //             height: double.infinity,
                      //             alignment: Alignment.center,
                      //             child: widget.locations.first.hazard
                      //                         ?.containsKey(hazard) ??
                      //                     false
                      //                 ? (showRiskScore
                      //                     ? _renderRiskScore(widget.locations
                      //                         .first.hazard?[hazard]?.rating)
                      //                     : _renderFormattedHazardData(
                      //                         widget.locations.first
                      //                             .hazard?[hazard],
                      //                         widget
                      //                             .locations
                      //                             .first
                      //                             .hazard?[hazard]
                      //                             ?.rating)) // ✅ Fixed
                      //                 : Text("N/A",
                      //                     style: CustomTypography(context)
                      //                         .Body2
                      //                         .copyWith(color: Colors.grey)),
                      //           ),
                      //         ))
                      //     .toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _renderRiskScore(int? score) {
    if (score == null || score == 0) {
      return Center(
        child: Text(
          "-",
          style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: _getColorForRating(context, score),
      child: Text(
        score.toString(),
        style: CustomTypography(context)
            .Body2
            .copyWith(color: _getTextColorForRating(context, score)),
      ),
    );
  }

  Color _getColorForRating(BuildContext context, int? rating) {
    if (rating == null) return Colors.grey;
    if (rating == 5) return Colors.green;
    if (rating == 4) return Colors.lightGreen;
    if (rating == 3) return Colors.yellow;
    if (rating == 2) return Colors.orange;
    if (rating == 1) return Colors.red;
    return Colors.transparent;
  }

  Color _getTextColorForRating(BuildContext context, int? rating) {
    if (rating == null || rating == 0) {
      return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }
    return (rating >= 4) ? Colors.white : Colors.black;
  }

  Widget _renderFormattedHazardData(HazardDetails? hazardDetails, int? score) {
    if (score == null || score == 0) {
      return Text(
        "-",
        style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
      );
    }

    if (hazardDetails == null || hazardDetails.others == null) {
      return Text(
        "-",
        style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
      );
    }

    List<Widget> vendorDataWidgets = [];

    // **Coastal Flood**
    // if (hazardDetails.others!.containsKey("Kineticast")) {
    //   var mainValue = hazardDetails.others!["Kineticast"]!.value;
    //   vendorDataWidgets.add(_buildVendorDataWidget(
    //       key: "Flood depth (ft)",
    //       value: _formatNumber(mainValue),
    //       vendorName: "KinetiCast",
    //       score: score));
    // }
    if (hazardDetails.others!.containsKey("MarshMcLennan")) {
      var mainValue = hazardDetails.others!["MarshMcLennan"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Flood Risk Score",
        value: mainValue.toString(),
        vendorName: "MarshMcLennan",
        score: score,
      ));
    }

    // **Earthquake**
    if (hazardDetails.others!.containsKey("GlobalEarthquakeModel")) {
      var mainValue = hazardDetails.others!["GlobalEarthquakeModel"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "PGA (%g)",
        value: _formatNumber(mainValue),
        vendorName: "Global Earthquake Model",
        score: score,
      ));
    }

    // **Hurricane**
    if (hazardDetails.others!.containsKey("Kineticast")) {
      var mainValue = hazardDetails.others!["Kineticast"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Wind Speed (mph)",
        value: _formatNumber1(mainValue),
        vendorName: "KinetiCast",
        score: score,
      ));
    }

    // **Wildfire**
    if (hazardDetails.others!.containsKey("Modis")) {
      var mainValue = hazardDetails.others!["Modis"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Temp(K) / FRP",
        value: _formatNumber(mainValue),
        vendorName: "MODIS",
        score: score,
      ));
    }

    // **Riverine Flood**
    if (hazardDetails.others!.containsKey("JRCOD")) {
      var mainValue = hazardDetails.others!["JRCOD"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Flood Depth (ft)",
        value: _formatNumber(mainValue, decimalPlaces: 1),
        vendorName: "JRCOD",
        score: score,
      ));
    }
    // if (hazardDetails.others!.containsKey("MarshMcLennan")) {
    //   var mainValue = hazardDetails.others!["MarshMcLennan"]!.value;
    //   vendorDataWidgets.add(_buildVendorDataWidget(
    //     key: "Flood Risk Score2",
    //     value: _formatNumber(mainValue, decimalPlaces: 1),
    //     vendorName: "MarshMcLennan",
    //     score: score,
    //   ));
    // }

    // **USGS Risk Index**
    if (hazardDetails.others!.containsKey("USGS")) {
      var mainValue = hazardDetails.others!["USGS"]!.value.toString();
      String formattedValue = _formatUSGSValue(mainValue);
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Risk Index",
        value: formattedValue,
        vendorName: "USGS",
        score: score,
      ));
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _getColorForRating(context, score),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: vendorDataWidgets,
      ),
    );
  }

  String _formatNumber(dynamic value, {int decimalPlaces = 3}) {
    if (value == null) return "-";
    if (value is num) {
      return value.toStringAsFixed(decimalPlaces);
    }
    return value.toString();
  }

  String _formatNumber1(dynamic value, {int decimalPlaces = 1}) {
    if (value == null) return "-";
    if (value is num) {
      return value.toStringAsFixed(decimalPlaces);
    }
    return value.toString();
  }

  String _formatUSGSValue(String value) {
    if (value == "Not Applicable" || value == "No Rating") {
      return "-";
    }
    var parts = value.split(" ");
    if (parts.length >= 2) {
      return "${parts[0][0]}.${parts[1]}"; // Format as "X.Y"
    }
    return value;
  }

  Widget _buildVendorDataWidget({
    required String key,
    required String value,
    required String vendorName,
    required int score,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$key: ${value == 'nan/nan' ? '-' : value}",
            style: CustomTypography(context).Caption.copyWith(
                fontWeight: FontWeight.w600,
                color: _getTextColorForRating(context, score)),
            textAlign: TextAlign.start,
          ),
          Text(
            vendorName,
            style: CustomTypography(context)
                .Caption
                .copyWith(color: _getTextColorForRating(context, score)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
