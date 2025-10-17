import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartScrollViewPage extends StatelessWidget {
  const ChartScrollViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // First Chart (Pie)
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Weighted Distribution (TPV)",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: 60,
                            title: '60%',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.black),
                          ),
                          PieChartSectionData(
                            color: Colors.yellow,
                            value: 22,
                            title: '22%',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.black),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: 18,
                            title: '18%',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Percentage : 60%   TVP: \$27M   Location: 2",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Second Chart (Bar)
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Critical Missing Parameters",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _buildBarItem("Hurricane", 166, Colors.red),
                  _buildBarItem("Earthquake", 124, Colors.orange),
                  _buildBarItem("WildFire", 121, Colors.yellow),
                  _buildBarItem("Coastal Flood", 55, Colors.lightBlue),
                  _buildBarItem("RiverineFlood", 20, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarItem(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 166, // normalize based on max
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
