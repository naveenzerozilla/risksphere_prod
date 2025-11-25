import '../../utils/global_imports.dart';

class ProcessSummaryPage extends StatefulWidget {
  final Map<String, dynamic>? summaryData;

  ProcessSummaryPage({Key? key, required this.summaryData}) : super(key: key);

  @override
  _ProcessSummaryPageState createState() => _ProcessSummaryPageState();
}

class _ProcessSummaryPageState extends State<ProcessSummaryPage>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool hasAnyPlan = false;
  bool _showNotificationDot = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    final hazardVendorData = widget.summaryData?['hazard_rating_summary'] ?? {};

    if (widget.summaryData == null || widget.summaryData!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geo Rating Summary')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (buildContext, themeProvider, child) {
        return SafeArea(
          child: Scaffold(
            backgroundColor:
                themeProvider.getTheme.colorScheme.surfaceContainerLowest,
            appBar: CustomAppBar(
              hasAnyPlan: hasAnyPlan,
              isExpanded: _isExpanded,
              showNotificationDot: _showNotificationDot,
              onExpandPressed: (isExpanded) {
                setState(() {
                  _isExpanded = isExpanded;
                });
              },
              onSearchPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            drawer: CustomDrawer(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Tab buttons section
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primaryMain,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    labelStyle: typography.Body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Data Summary'),
                      Tab(text: 'Recommendation'),
                    ],
                  ),
                ),

                // 🔹 Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 🧩 Tab 1: Data Summary
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child:_dataSummary(

                        ),
                      ),

                      // 🧩 Tab 2: Recommendation tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recommendations",
                              style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Make sure these two helper methods are static or top-level functions

  Widget _dataSummary(){
    return Container();
  }

  Widget _buildDynamicGeoRatingSummary(
      BuildContext context, Map<String, dynamic> apiData,
      {bool isSubProcess = false}) {
    // Map<String, int> aggregatedScores = {
    //   "5": 0,
    //   "4": 0,
    //   "3": 0,
    //   "2": 0,
    //   "1": 0,
    // };

    final result = apiData['geo_rating_summary'];
    print('Result section: $result');

    if (result == null) {
      print('No "result" key found in apiData.');
      return _buildGeoRatingSummary(context, result);
    }

    if (isSubProcess) {
      final subprocesses = result['subprocesses'];
      print('Subprocesses: $subprocesses');

      if (subprocesses != null && subprocesses.isNotEmpty) {
        subprocesses.forEach((key, process) {
          final subScore = process['result']?['total_score_counts'];
          if (subScore != null) {
            subScore.forEach((rating, count) {
              result[rating] = (result[rating] ?? 0) + (count as int);
            });
          }
        });
      } else {
        // Fallback to use direct result scores if no subprocesses are present
        print('No subprocess data, using direct scores from result.');
        final Map<String, dynamic> directScores =
            result['total_score_counts'] ?? {};
        directScores.forEach((rating, count) {
          result[rating] = (result[rating] ?? 0) + (count as int);
        });
      }
    } else {
      final Map<String, dynamic> topLevelScore =
          result['summary']?['score'] ?? {};
      topLevelScore.forEach((rating, count) {
        result[rating] = (count ?? 0).toInt();
      });
    }

    print('Final aggregated scores: $result');
    return _buildGeoRatingSummary(context, result);
  }

  Widget _buildGeoRatingSummary(
      BuildContext context, Map<String, dynamic> ratings) {
    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid Layout for Star Ratings
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row for 5 Star and 4 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(context, "1 Star Locations",
                          ratings['1'] ?? 0, typography)),
                  SizedBox(width: 8), // Spacing between the two cards
                  Expanded(
                      child: _buildRatingCard(context, "2 Star Locations",
                          ratings['2'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8), // Spacing between rows

              // Row for 3 Star and 2 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(context, "3 Star Locations",
                          ratings['3'] ?? 0, typography)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _buildRatingCard(context, "4 Star Locations",
                          ratings['4'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8),

              // Single expanded row for 1 Star Locations
              _buildRatingCard(
                  context, "5 Star Locations", ratings['5'] ?? 0, typography),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, String title, int count,
      CustomTypography typography) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.4,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.Body2,
          ),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: typography.Body1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardVendorSummary(BuildContext context,
      Map<dynamic, dynamic> hazardVendorData, CustomTypography typography) {
    // if (hazardVendorData.isEmpty) {
    //   return SizedBox.shrink();
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Hazard Rating Summary",
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          // Ensure scrolling behavior is properly handled
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: hazardVendorData.keys.map((hazard) {
                final vendors =
                    hazardVendorData[hazard] as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          hazard,
                          style: typography.Body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (vendors.isNotEmpty)
                        ...vendors.keys.map((vendor) {
                          final scores =
                              vendors[vendor] as Map<String, dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Text(
                                  "Source: $vendor",
                                  style: typography.Body2.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: _buildHazardDetailRow(
                                  "Locations with Score",
                                  scores.entries
                                      .where((entry) => entry.key != "None")
                                      .map((entry) {
                                        final value = entry.value;
                                        if (value is int) {
                                          return value;
                                        } else if (value
                                            is Map<String, dynamic>) {
                                          return value.values.fold(
                                              0,
                                              (prev, next) =>
                                                  prev + (next as int));
                                        } else {
                                          return 0;
                                        }
                                      })
                                      .fold(0, (prev, next) => prev + next)
                                      .toString(),
                                  typography,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: _buildHazardDetailRow(
                                  "Locations without Score",
                                  scores['None']?.toString() ?? "0",
                                  typography,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Divider(),
                              ),
                              ExpansionTile(
                                tilePadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                trailing: Icon(
                                  Icons.add_circle_outline,
                                  color: Theme.of(context).disabledColor,
                                ),
                                initiallyExpanded: false,
                                title: Text(
                                  "Hazard Risk Score Wise Locations",
                                  style: typography.Body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: _buildHazardRiskScores(
                                        context, scores, typography),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHazardRiskScores(
      BuildContext context, Map<String, dynamic> scores, typography) {
    final riskScores = [
      {"label": "Severe impact", "key": "1", "color": Colors.red, "star": "★"},
      {"label": "High impact", "key": "2", "color": Colors.orange, "star": "★"},
      {
        "label": "Medium impact",
        "key": "3",
        "color": Colors.yellow,
        "star": "★"
      },
      {
        "label": "Low impact",
        "key": "4",
        "color": Colors.lightGreen,
        "star": "★"
      },
      {"label": "No impact", "key": "5", "color": Colors.green, "star": "★"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: riskScores.map((score) {
        final count = scores[score['key']]?.toString() ?? "0";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${score['key']}   ",
                      style: typography.Body2,
                    ),
                    TextSpan(
                      text: "${score['star']!}",
                      style: typography.Body2.copyWith(
                        color: score['color'] as Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: score['key'] == 1
                          ? " (${score['label']})"
                          : " (${score['label']})",
                      style: typography.Body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                count,
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.primaryMain,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHazardDetailRow(
      String label, String value, CustomTypography typography) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: typography.Body2),
        Text(
          value,
          style: typography.Body1.copyWith(
            color: AppColors.primaryMain,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
