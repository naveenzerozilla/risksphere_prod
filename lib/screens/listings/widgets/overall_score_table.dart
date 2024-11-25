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

  @override
  void initState() {
    super.initState();

    // Initialize hazard columns and set visibility to false initially
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
    return Container(
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

          headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerLowest),
          columnSpacing: 16,
          fixedTopRows: 1,
          fixedLeftColumns: 1,
          minWidth: 1500,
          horizontalMargin: 12,
          bottomMargin: 20,
          dividerThickness: 1,

          border: TableBorder.all(color: Theme.of(context).colorScheme.surface, width: 1, style: BorderStyle.solid, borderRadius: BorderRadius.circular(12)),
          columns: [
            DataColumn2(
              fixedWidth: MediaQuery.of(context).size.width * 0.3,
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Location', style: CustomTypography(context).InputLabel),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (String hazard) {
                      setState(() {
                        columnVisibility[hazard] = !(columnVisibility[hazard] ?? true);
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: "show",
                          child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text("Show All Hazards", style: CustomTypography(context).Body2),
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
                            title: Text("Hide All Hazards", style: CustomTypography(context).Body2),
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
                label: Text('Overall Score', style: CustomTypography(context).InputLabel)),
            DataColumn2(

                fixedWidth: MediaQuery.of(context).size.width * 0.3,
              size: ColumnSize.L,
                label: Text('Geocoding Score', style: CustomTypography(context).InputLabel)),
            ...hazardColumns
                .where((hazard) => columnVisibility[hazard] ?? true)
                .map((hazard) => DataColumn2(

              size: ColumnSize.L,
              label: Text(hazard, style: CustomTypography(context).InputLabel),
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
                DataCell(Text(location.overallScore == null?"0":location.overallScore.toString(), style: CustomTypography(context).Body2)),
                DataCell(Text(location.finalAddress?.score?.toString() ?? 'N/A', style: CustomTypography(context).Body2)),
                ...hazardColumns
                    .where((hazard) => columnVisibility[hazard] ?? true)
                    .map((hazard) => DataCell(
                  Text(
                    location.hazard?[hazard]?.rating.toString() ?? 'N/A',
                    style: CustomTypography(context).Body2,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
