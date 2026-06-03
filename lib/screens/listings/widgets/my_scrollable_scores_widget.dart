import 'package:flutter/material.dart';
import 'package:RiskSphere/screens/listings/widgets/vertical_bar_indicator.dart';

import '../../../design_system/primitives/custom_typography.dart';

class MyScrollableScoresWidget extends StatelessWidget {
  final int geocodingScore;
  final dynamic riskScore;
  final dynamic dataCompleteness;
  final bool? hazardProcess;

  MyScrollableScoresWidget({
    required this.geocodingScore,
    required this.riskScore,
    required this.dataCompleteness,
    this.hazardProcess,
  });

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true, // Makes the scrollbar always visible
      child: Column(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildScoreCard(
                    context, 'Geocoding Score', geocodingScore, true),
                _buildScoreCard(context, 'Hazard Score',
                    int.parse(riskScore.toString()), true),
                _buildScoreCard(
                    context,
                    'Data Completeness',

                    dataCompleteness,
                    true),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  int scoreToColorIndex(dynamic value) {
    if (value == null) return 1;

    final double score = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 1.0;

    final int colorIndex = score.ceil();

    return colorIndex.clamp(1, 5);
  }

  Widget _buildScoreCard(
      BuildContext context, String title, dynamic score, bool? hazardProcess) {
    List<Color> scoreColors = [
      Colors.grey[300]!,
      Colors.red[900]!,
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.green[300]!,
      Colors.green[600]!,
    ];

    final int colorIndex = scoreToColorIndex(score);
    var typography = CustomTypography(context);
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.all(8),
      width: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: typography.InputLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hazardProcess == true ||
                  title == 'Geocoding Score' ||
                  title == 'Data Completeness') ...[
                VerticalBarIndicator(score: score),
                SizedBox(width: 4),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: scoreColors[colorIndex],
                  child: Center(
                    child: Text(
                      (score == 0 ? '1' : score.toString()),
                      style: typography.Body1.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(child: Text("Processing"))
              ]
            ],
          ),
        ],
      ),
    );
  }
}
