import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
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
  bool showRiskScore = true; // Toggle to control display mode

  @override
  void initState() {
    super.initState();

    // Initialize hazard columns and set visibility to true initially
    if (widget.locations.isNotEmpty) {
      hazardColumns = widget.locations.first.hazard?.keys.toList() ?? [];
      for (var hazard in hazardColumns) {
        columnVisibility[hazard] = true;
      }
    } else {
      hazardColumns = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the number of visible hazard columns
    final int visibleHazardsCount =
        hazardColumns.where((hazard) => columnVisibility[hazard] ?? true).length;

    // Fixed widths for Location, Overall Score, and Geocoding Score columns
    final double fixedColumnsWidth = MediaQuery.of(context).size.width * 0.9;

    // Total width of hazard columns
    final double hazardColumnsWidth = visibleHazardsCount * 150;

    // Calculate the dynamic minWidth, ensuring a minimum fallback width
    final double dynamicMinWidth = fixedColumnsWidth +
        (hazardColumnsWidth > 0 ? hazardColumnsWidth : 300);

    return Column(
      children: [
        // Toggle Switch for "See Risk Score"
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
                      label: Text('Overall Score',
                          style: CustomTypography(context).InputLabel)),
                  DataColumn2(
                      fixedWidth: MediaQuery.of(context).size.width * 0.3,
                      size: ColumnSize.L,
                      label: Text('Geocoding Score',
                          style: CustomTypography(context).InputLabel)),
                  ...hazardColumns
                      .where((hazard) => columnVisibility[hazard] ?? true)
                      .map((hazard) => DataColumn2(
                    size: ColumnSize.L,
                    label: Text(hazard,
                        style: CustomTypography(context).InputLabel),
                  )),
                ],
                rows: widget.locations.map((location) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          location.finalAddress?.address ?? '',
                          style: CustomTypography(context).Body2,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: _getColorForRating(
                              context, location.overallScore),
                          alignment: Alignment.center,
                          child: Text(
                            (location.overallScore == null ||
                                location.overallScore == 0)
                                ? 'N/A'
                                : location.overallScore.toString() ?? '',
                            style: CustomTypography(context).Body2.copyWith(
                              color: _getTextColorForRating(
                                  context, location.overallScore),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: _getColorForRating(
                              context, location.finalAddress?.score),
                          alignment: Alignment.center,
                          child: Text(
                            (location.finalAddress?.score == null ||
                                location.finalAddress?.score == 0)
                                ? 'N/A'
                                : location.finalAddress?.score?.toString() ??
                                '',
                            style: CustomTypography(context).Body2.copyWith(
                              color: _getTextColorForRating(
                                  context, location.finalAddress?.score),
                            ),
                          ),
                        ),
                      ),
                      ...hazardColumns
                          .where((hazard) => columnVisibility[hazard] ?? true)
                          .map((hazard) => DataCell(
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          child: showRiskScore
                              ? _renderRiskScore(widget.locations.first.hazard?[hazard])
                              : _renderFormattedHazardData(widget.locations.first.hazard?[hazard]),
                        ),
                      )),







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

  Widget _renderRiskScore(HazardDetails? hazardDetails) {
    if (hazardDetails == null || hazardDetails.rating == null) {
      return Text(
        "N/A",
        style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: _getColorForRating(context, hazardDetails.rating),
      child: Text(
        hazardDetails.rating.toString(),
        style: CustomTypography(context)
            .Body2
            .copyWith(color: _getTextColorForRating(context, hazardDetails.rating)),
      ),
    );
  }



  Widget _renderFormattedHazardData(HazardDetails? hazardDetails) {
    if (hazardDetails == null) {
      return Text(
        "N/A",
        style: CustomTypography(context).Body2.copyWith(color: Colors.grey),
      );
    }

    final List<Widget> vendorDataWidgets = [];

    // Primary vendor data
    if (hazardDetails.vendorName != null) {
      vendorDataWidgets.add(
        _buildVendorDataWidget(
          key: hazardDetails.value?.toString() ?? "N/A",
          value: hazardDetails.vendorName!,
          rating: hazardDetails.rating,
        ),
      );
    }

    // Other vendor data
    if (hazardDetails.others != null) {
      hazardDetails.others!.forEach((vendorName, vendorDetails) {
        vendorDataWidgets.add(
          _buildVendorDataWidget(
            key: vendorDetails.value?.toString() ?? "N/A",
            value: vendorName,
            rating: vendorDetails.rating,
          ),
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vendorDataWidgets,
    );
  }

  Widget _buildVendorDataWidget({
    required String key,
    required String value,
    int? rating,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$key",
            style: CustomTypography(context).Body2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: CustomTypography(context)
                    .Caption
                    .copyWith(color: Colors.grey),
              ),
              if (rating != null)
                Text(
                  "Rating: $rating",
                  style: CustomTypography(context)
                      .Caption
                      .copyWith(color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }





  Color _getColorForRating(BuildContext context, int? rating) {
    if (rating == null) return Colors.grey;
    if (rating == 0) return Colors.grey;
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
}
