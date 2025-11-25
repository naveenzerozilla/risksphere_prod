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
                    (dataCompleteness == null ||
                            int.tryParse(dataCompleteness.toString()) == null)
                        ? 1
                        : int.parse(dataCompleteness.toString()),
                    true),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
      BuildContext context, String title, int score, bool? hazardProcess) {
    List<Color> scoreColors = [
      Colors.grey[300]!,
      Colors.red[900]!,
      Colors.red[300]!,
      Colors.yellow[300]!,
      Colors.green[300]!,
      Colors.green[600]!,
    ];

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
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (hazardProcess == true ||
                title == 'Geocoding' ||
                title == 'Data Completeness') ...[
              VerticalBarIndicator(score: score),
              SizedBox(width: 4),
              CircleAvatar(
                radius: 10,
                backgroundColor: scoreColors[score].withOpacity(0.6),
                child: Center(
                  child: Text(

                    score == 0 ? '1' : score.toString(),
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
          ]),
        ],
      ),
    );
  }
}
