
import 'package:RiskSphere/utils/global_imports.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../models/my_location_list_model.dart';
import '../../../providers/my_location_list_provider.dart';

class LocationTable extends StatefulWidget {
  final String? accountID;
  final String? subAccountID;
  final String? initialProcessId;
  final String? initialSubProcessId;
  final String? sovId;

  const LocationTable({
    super.key,
    this.accountID,
    this.subAccountID,
    this.initialProcessId,
    this.initialSubProcessId,
    this.sovId,
  });

  @override
  State<LocationTable> createState() => _LocationTableState();
}

class _LocationTableState extends State<LocationTable> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> showRiskScoreNotifier = ValueNotifier(true);

  Map<String, bool> columnVisibility = {};
  List<dynamic> hazardColumns = [];

  bool showRiskScore = true;

  MyLocationListProvider?
      provider; // ✅ declare variable only, don’t initialize here

  int currentPage = 0;
  int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = context.read<MyLocationListProvider>();

// 🟢 First API call for page 1
      provider!
          .fetchLocationList(
        context,
        "",
        1,
        rowsPerPage,
        widget.accountID,
        widget.subAccountID,
        widget.initialProcessId,
        widget.initialSubProcessId,
        widget.sovId,
      )
          .then((_) {
        if (provider!.myLocationList.isNotEmpty) {
          final firstLocation = provider!.myLocationList.first;
          if (firstLocation.hazard != null) {
            setState(() {
              hazardColumns = firstLocation.hazard!.keys.toList();
            });
          }
        }
      });
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
            !provider!.isNextPageLoading &&
            provider!.page < provider!.totalPages) {
          provider!.page += 1;

          provider!.fetchLocationList(
            context,
            "",
            provider!.page,
            rowsPerPage,
            widget.accountID,
            widget.subAccountID,
            widget.initialProcessId,
            widget.initialSubProcessId,
            widget.sovId,
          );
        }
      });
    });
  }

  List<MyLocation> get pagedLocations {
    int start = currentPage * rowsPerPage;
    int end = start + rowsPerPage;
    end = end > provider!.myLocationList.length
        ? provider!.myLocationList.length
        : end;
    return provider!.myLocationList.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyLocationListProvider>();
    if (provider.isLoading) {
// 🟩 Show loader only on first load
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

// if (hazardColumns.isEmpty) {
//   return const Center(child: CircularProgressIndicator());
// }

    final int visibleHazardsCount = hazardColumns
        .where((hazard) => columnVisibility[hazard] ?? true)
        .length;
    final double fixedColumnsWidth = MediaQuery.of(context).size.width * 0.9;
    final double hazardColumnsWidth = visibleHazardsCount * 150;
    final double dynamicMinWidth =
        fixedColumnsWidth + (hazardColumnsWidth > 0 ? hazardColumnsWidth : 300);

    final Map<String, int> hazardOrder = {
      'Hurricane': 1,
      'Earthquake': 2,
      'Wildfire': 3,
      'CoastalFlood': 4,
      'RiverineFlood': 5,
      'Avalanche': 6,
      'ColdWave': 7,
      'Drought': 8,
      'Hail': 9,
      'HeatWave': 10,
      'IceStorm': 11,
      'Landslide': 12,
      'Lightning': 13,
      'StrongWind': 14,
      'Tornado': 15,
      'Tsunami': 16,
      'VolcanicActivity': 17,
      'WinterWeather': 18,
    };

    final sortedHazardColumns = hazardColumns!
        .where((hazard) => hazard != 'Overall')
        .toList()
      ..sort(
          (a, b) => (hazardOrder[a] ?? 999).compareTo(hazardOrder[b] ?? 999));

    return Column(
      children: [
// Text("${provider.myLocationList.length} Locations"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LocationScoreChart()),
                    );
                  },
                  child: Text("See Risk Score",
                      style: CustomTypography(context).Body1)),
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
        Container(
          height: MediaQuery.of(context).size.height / 1.8,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // ✅ The DataTable goes first
                Expanded(
                  child: DataTable2(
                    scrollController: _scrollController,
                    isHorizontalScrollBarVisible: true,
                    isVerticalScrollBarVisible: true,
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                    ),
                    columnSpacing: 0,
                    fixedTopRows: 1,
                    fixedLeftColumns: 1,
                    minWidth: dynamicMinWidth,
                    horizontalMargin: 12,
                    bottomMargin: 20,
                    dividerThickness: 1,
                    dataRowHeight: !showRiskScore ? 160 : null,
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
                              icon: const Icon(Icons.more_vert),
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
                                      leading: const Icon(Icons.visibility),
                                      title: Text("Show All Hazards",
                                          style:
                                              CustomTypography(context).Body2),
                                      onTap: () {
                                        setState(() {
                                          hazardColumns!.forEach((hazard) {
                                            columnVisibility[hazard] = true;
                                          });
                                        });
                                      },
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: "hide",
                                    child: ListTile(
                                      leading: const Icon(Icons.visibility_off),
                                      title: Text("Hide All Hazards",
                                          style:
                                              CustomTypography(context).Body2),
                                      onTap: () {
                                        setState(() {
                                          hazardColumns!.forEach((hazard) {
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
                        label: Text('Hazard Score',
                            style: CustomTypography(context).InputLabel),
                      ),
                      ...sortedHazardColumns.map((hazard) {
                        return DataColumn2(
                          size: ColumnSize.L,
                          label: Text(
                            hazard,
                            style:
                                CustomTypography(context).InputLabel.copyWith(
                                      color: columnVisibility[hazard] == false
                                          ? Colors.grey
                                          : null,
                                    ),
                          ),
                        );
                      }).toList(),
                    ],
                    rows: provider.myLocationList.map((location) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              location.geocodedAddress ?? '',
                              style: CustomTypography(context).Body2,
                              overflow: TextOverflow.ellipsis,
                              maxLines: showRiskScore ? 4 : 7,
                            ),
                          ),
                          DataCell(_renderRiskScore(int.tryParse(
                                  location.geocodingScore?.toString() ?? '') ??
                              0)),
                          DataCell(_renderRiskScore(int.tryParse(
                                  location.overallScore?.toString() ?? '') ??
                              0)),
                          ...sortedHazardColumns.map((hazard) => DataCell(
                                Container(
                                  alignment: Alignment.center,
                                  child: location.hazard?.containsKey(hazard) ??
                                          false
                                      ? (showRiskScore
                                          ? _renderRiskScore(int.tryParse(
                                              location.hazard?[hazard]?.rating
                                                      ?.toString() ??
                                                  ''))
                                          : _renderFormattedHazardData(
                                              location.hazard?[hazard],
                                              int.tryParse(location
                                                      .hazard?[hazard]?.rating
                                                      ?.toString() ??
                                                  '')))
                                      : Text(
                                          "-",
                                          style: CustomTypography(context)
                                              .Body2
                                              .copyWith(color: Colors.grey),
                                        ),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // ✅ Loader below the table
                if (provider.isNextPageLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 8),
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        )

        // Container(
        //   height: MediaQuery.of(context).size.height / 2,
        //   width: double.infinity,
        //   margin: const EdgeInsets.symmetric(horizontal: 16),
        //   decoration: BoxDecoration(
        //     color: Theme.of(context).colorScheme.surface,
        //     borderRadius: BorderRadius.circular(12),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black12,
        //         blurRadius: 8,
        //         spreadRadius: 2,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //     child: ClipRRect(
        //       borderRadius: BorderRadius.circular(12),
        //       child: Stack(
        //         children: [
        //           DataTable2(
        //             scrollController: _scrollController,
        //             isHorizontalScrollBarVisible: true,
        //             isVerticalScrollBarVisible: true,
        //             headingRowColor: WidgetStateProperty.all(
        //                 Theme.of(context).colorScheme.surfaceContainerLowest),
        //             columnSpacing: 0,
        //             fixedTopRows: 1,
        //             fixedLeftColumns: 1,
        //             minWidth: dynamicMinWidth,
        //             horizontalMargin: 12,
        //             bottomMargin: 20,
        //             dividerThickness: 1,
        //             dataRowHeight: !showRiskScore ? 160 : null,
        //             // Enables dynamic height
        //             border: TableBorder.all(
        //               color: Theme.of(context).colorScheme.surface,
        //               width: 1,
        //               style: BorderStyle.solid,
        //               borderRadius: BorderRadius.circular(12),
        //             ),
        //             columns: [
        //               DataColumn2(
        //                 fixedWidth: MediaQuery.of(context).size.width * 0.3,
        //                 label: Row(
        //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //                   children: [
        //                     Text('Location',
        //                         style: CustomTypography(context).InputLabel),
        //                     PopupMenuButton<String>(
        //                       icon: const Icon(Icons.more_vert),
        //                       onSelected: (String hazard) {
        //                         setState(() {
        //                           columnVisibility[hazard] =
        //                           !(columnVisibility[hazard] ?? true);
        //                         });
        //                       },
        //                       itemBuilder: (BuildContext context) {
        //                         return [
        //                           PopupMenuItem<String>(
        //                             value: "show",
        //                             child: ListTile(
        //                               leading: const Icon(Icons.visibility),
        //                               title: Text("Show All Hazards",
        //                                   style: CustomTypography(context).Body2),
        //                               onTap: () {
        //                                 setState(() {
        //                                   hazardColumns!.forEach((hazard) {
        //                                     columnVisibility[hazard] = true;
        //                                   });
        //                                 });
        //                               },
        //                             ),
        //                           ),
        //                           PopupMenuItem<String>(
        //                             value: "hide",
        //                             child: ListTile(
        //                               leading: const Icon(Icons.visibility_off),
        //                               title: Text("Hide All Hazards",
        //                                   style: CustomTypography(context).Body2),
        //                               onTap: () {
        //                                 setState(() {
        //                                   hazardColumns!.forEach((hazard) {
        //                                     columnVisibility[hazard] = false;
        //                                   });
        //                                 });
        //                               },
        //                             ),
        //                           ),
        //                         ];
        //                       },
        //                     ),
        //                   ],
        //                 ),
        //                 size: ColumnSize.L,
        //               ),
        //               DataColumn2(
        //                 fixedWidth: MediaQuery.of(context).size.width * 0.3,
        //                 size: ColumnSize.L,
        //                 label: Text('Geocoding Score',
        //                     style: CustomTypography(context).InputLabel),
        //               ),
        //               DataColumn2(
        //                 fixedWidth: MediaQuery.of(context).size.width * 0.3,
        //                 size: ColumnSize.L,
        //                 label: Text('Hazard Score',
        //                     style: CustomTypography(context).InputLabel),
        //               ),
        //               ...sortedHazardColumns.map((hazard) {
        //                 return DataColumn2(
        //                   size: ColumnSize.L,
        //                   label: Text(
        //                     hazard,
        //                     style: CustomTypography(context).InputLabel.copyWith(
        //                         color: columnVisibility[hazard] == false
        //                             ? Colors.grey
        //                             : null),
        //                   ),
        //                 );
        //               }).toList(),
        //             ],
        //             rows: provider.myLocationList.map((location) {
        //               return DataRow(
        //                 cells: [
        //                   DataCell(
        //                     Text(
        //                       location.geocodedAddress ?? '',
        //                       style: CustomTypography(context).Body2,
        //                       overflow: TextOverflow.ellipsis,
        //                       maxLines: showRiskScore ? 4 : 7,
        //                     ),
        //                   ),
        //                   DataCell(_renderRiskScore(int.tryParse(
        //                       location.geocodingScore?.toString() ?? '') ??
        //                       0)),
        //                   DataCell(_renderRiskScore(
        //                       int.tryParse(location.overallScore?.toString() ?? '') ??
        //                           0)),
        //                   ...sortedHazardColumns.map((hazard) => DataCell(
        //                     Container(
        //                       width: double.infinity,
        //                       height: double.infinity,
        //                       alignment: Alignment.center,
        //                       child: location.hazard?.containsKey(hazard) ?? false
        //                           ? (showRiskScore
        //                           ? _renderRiskScore(int.tryParse(location
        //                           .hazard?[hazard]?.rating
        //                           ?.toString() ??
        //                           ''))
        //                           : _renderFormattedHazardData(
        //                           location.hazard?[hazard],
        //                           int.tryParse(location
        //                               .hazard?[hazard]?.rating
        //                               ?.toString() ??
        //                               '')))
        //                           : Text(
        //                         "-",
        //                         style: CustomTypography(context)
        //                             .Body2
        //                             .copyWith(color: Colors.grey),
        //                       ),
        //                     ),
        //                   )),
        //
        //                 ],
        //               );
        //             }).toList(),
        //           ),
        //           if (provider.isNextPageLoading)
        //             Positioned(
        //               left: 0,
        //               right: 0,
        //               bottom: 22,
        //               child: Container(
        //                 height: 48,
        //                 alignment: Alignment.center,
        //                 child: const CircularProgressIndicator(),
        //               ),
        //             ),
        //         ],
        //       ),
        //     ),
        // ),
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
    if (rating == 5) return Color(0xFF2E7D32);
    if (rating == 4) return Color(0xFF81C784);
    if (rating == 3) return Color(0xFFFFEE58);
    if (rating == 2) return Color(0xFFE57373);
    if (rating == 1) return Color(0xFFF44336);
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
        vendorName: hazardDetails.vendorName.toString() == "MM FRI"
            ? "MM FRI **"
            : "MM FRI", //"MM FRI",
        score: score,
      ));
    }

// **Earthquake**
    if (hazardDetails.others!.containsKey("GlobalEarthquakeModel")) {
      var mainValue = hazardDetails.others!["GlobalEarthquakeModel"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "PGA (%g)",
        value: _formatNumber(mainValue),
        vendorName: hazardDetails.vendorName.toString() == "GEM"
            ? "GEM **"
            : "GEM", //"GEM",
        score: score,
      ));
    }

// **Hurricane**
    if (hazardDetails.others!.containsKey("Kineticast")) {
      var mainValue = hazardDetails.others!["Kineticast"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Wind Speed (mph)",
        value: _formatNumber(mainValue),
        vendorName: hazardDetails.vendorName.toString() == "KinetiCast"
            ? "KinetiCast **"
            : "Kineticast",
        score: score,
      ));
    }
// **Wildfire**
    if (hazardDetails.others!.containsKey("Modis")) {
      var mainValue = hazardDetails.others!["Modis"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Temp(K) / FRP",
        value: _formatNumber(mainValue),
        vendorName: hazardDetails.vendorName.toString() == "MODIS"
            ? "MODIS **"
            : "MODIS", //"MODIS",
        score: score,
      ));
    }

// **Riverine Flood**
    if (hazardDetails.others!.containsKey("JRCOD")) {
      var mainValue = hazardDetails.others!["JRCOD"]!.value;
      vendorDataWidgets.add(_buildVendorDataWidget(
        key: "Flood Depth (ft)",
        value: _formatNumber(mainValue, decimalPlaces: 1),
        vendorName: hazardDetails.vendorName.toString() == "EU JRC"
            ? "EU JRC **"
            : "EU JRC", //"EU JRC",
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
        vendorName: hazardDetails.vendorName.toString() == "USGS"
            ? "USGS **"
            : "USGS", //"USGS",
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
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 4.0),
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
                .Caption1
                .copyWith(color: _getTextColorForRating(context, score)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LocationScoreChart extends StatelessWidget {
  const LocationScoreChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Location Score",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              color: Colors.black,
              child: Expanded(
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  legend: Legend(
                    isVisible: true,
// overflowMode: LegendItemOverflowMode.wrap,
// position: LegendPosition.left,
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                  series: <DoughnutSeries<ChartData, String>>[
// New Outermost ring
                    DoughnutSeries<ChartData, String>(
                      dataSource: [
                        ChartData('A', 40, const Color(0xFF4A148C)),
// Example: Custom outermost
                        ChartData('B', 40, const Color(0xFF1976D2)),
                        ChartData('', 40, Colors.transparent),
                        ChartData('', 25, Colors.transparent),
                        ChartData('', 25, Colors.transparent),
// Transparent segment/ Transparent segment
                      ],
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      pointColorMapper: (ChartData data, _) => data.color,
                      dataLabelMapper: (ChartData data, _) => data.label,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      radius: '100%',
                      innerRadius: '85%',
                    ),
// Outer ring
                    DoughnutSeries<ChartData, String>(
                      dataSource: [
                        ChartData('01', 10, const Color(0xFFB71C1C)),
// R. High
                        ChartData('M', 10, const Color(0xFF90A4AE)),
// Missing Perils
                        ChartData('02', 10, const Color(0xFFE57373)),
// R. Moderate
                        ChartData('03', 10, const Color(0xFFFFEB3B)),
// R. Low
                        ChartData('04', 20, const Color(0xFF81C784)),
// V. Low
                      ],
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      pointColorMapper: (ChartData data, _) => data.color,
                      dataLabelMapper: (ChartData data, _) => data.label,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      radius: '90%',
                      innerRadius: '50%',
                    ),

// Inner circle (Complete)
                    DoughnutSeries<ChartData, String>(
                      explode: true,
                      dataSource: [
                        ChartData('05', 10, const Color(0xFF2E7D32)),
// Complete
                      ],
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      pointColorMapper: (ChartData data, _) => data.color,
                      dataLabelMapper: (ChartData data, _) => data.label,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      radius: '60%',
                      innerRadius: '0%',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
