import '../../utils/global_imports.dart';

class ProcessSummaryPage extends StatefulWidget {
  final Map<String, dynamic>? summaryData;
  final String? sovId;

  ProcessSummaryPage({Key? key, required this.summaryData, this.sovId})
      : super(key: key);

  @override
  _ProcessSummaryPageState createState() => _ProcessSummaryPageState();
}

class _ProcessSummaryPageState extends State<ProcessSummaryPage>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool hasAnyPlan = false;
  bool _showNotificationDot = true;
  TabController? _tabController;
  bool _isTabLoading = false;

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
                SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                          padding: EdgeInsets.only(left: 18),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                          )),
                    ),
                    SizedBox(width: 10),
                    Text("Location Insights",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600))
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.fromLTRB(11, 5, 11, 5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicator: const BoxDecoration(),
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.zero,
                    onTap: (_) => setState(() {}),
                    tabs: List.generate(1, (index) {
                      final bool isSelected = _tabController!.index == index;

                      return Tab(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryMain
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: AppColors.primaryMain,
                                      width: 1,
                                    ),
                            ),
                            child: Text(
                              LanguageService.getTranslated(
                                  context, "data_summary"),

                              // index == 0
                              //     ? LanguageService.getTranslated(context, "data_summary")
                              //     : LanguageService.getTranslated(context, "recommendations"),
                              maxLines: 1,
                              // ✅ prevent wrapping
                              overflow: TextOverflow.ellipsis,
                              // ✅ prevent hiding
                              style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16, // ✅ responsive size
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.primaryMain,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _dataSummary(
                          context,
                          widget.summaryData!,
                        ),
                      ),
                      // MissingParameterScreen(sovId: widget.sovId!),
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

  Widget _dataSummary(BuildContext context, Map<String, dynamic> apiData,
      {bool isSubProcess = false}) {
    final result = apiData['geo_rating_summary'];
    print('Result section: $result');

    if (result == null) {
      print('No geo_rating_summary found.');
      return const Text(
        "No rating summary available",
        style: TextStyle(color: Colors.white70),
      );
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
        print('No subprocess data, using direct scores.');
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

    return _buildGeoRatingSummary(context, result,
        hazardVendorSummary: apiData['hazard_rating_summary'] ?? {});
  }

  Widget _buildGeoRatingSummary(
      BuildContext context, Map<String, dynamic> ratings,
      {required Map<String, dynamic> hazardVendorSummary}) {
    final typography = CustomTypography(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant, width: 1.0)),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRatingCard(context, "1 Star Locations",
                        ratings['1'] ?? 0, typography),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildRatingCard(context, "2 Star Locations",
                        ratings['2'] ?? 0, typography),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildRatingCard(context, "3 Star Locations",
                        ratings['3'] ?? 0, typography),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildRatingCard(context, "4 Star Locations",
                        ratings['4'] ?? 0, typography),
                  ),
                ],
              ),

              SizedBox(height: 8),

              _buildRatingCard(
                  context, "5 Star Locations", ratings['5'] ?? 0, typography),

              SizedBox(height: 10),

              // ⭐ Correct hazard vendor summary block
              Container(
                height: MediaQuery.of(context).size.height / 2.8,
                child: _buildHazardVendorSummary(
                    context, hazardVendorSummary, typography),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            LanguageService.getTranslated(context, "hazard_rating_summary"),
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
                                  LanguageService.getTranslated(
                                      context, "hazard_rating_summary"),
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
