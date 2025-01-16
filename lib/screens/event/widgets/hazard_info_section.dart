import 'package:flutter/material.dart';

class HazardInfoSection extends StatelessWidget {
  final String hazardName;
  final String selectedDate;
  final Function(String?) onDateChanged;
  final List<String> availableDates;

  HazardInfoSection({
    required this.hazardName,
    required this.selectedDate,
    required this.onDateChanged,
    required this.availableDates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hazardName,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Text(
                "Data Source Date:",
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButton<String>(
                  padding: EdgeInsets.zero,
                  value: selectedDate,
                  dropdownColor: Colors.grey.shade900,
                  underline: SizedBox.shrink(),
                  onChanged: onDateChanged,
                  items: availableDates.map((String date) {
                    return DropdownMenuItem<String>(
                      value: date,
                      child: Text(
                        date,
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
