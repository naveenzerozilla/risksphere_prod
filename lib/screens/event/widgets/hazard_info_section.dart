import 'package:flutter/material.dart';

class HazardInfoSection extends StatelessWidget {
  final String hazardName;
  final String selectedDate;
  final String lastUpdated;
  final Function(String?) onDateChanged;
  final List<String> availableDates;

  HazardInfoSection({
    required this.hazardName,
    required this.selectedDate,
    required this.lastUpdated,
    required this.onDateChanged,
    required this.availableDates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Event Name: $hazardName ",
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: "•  Last Updated: $lastUpdated",
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
