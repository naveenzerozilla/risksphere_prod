import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/utilities/custom_spacing.dart';
import 'package:marquee/marquee.dart';
import 'package:intl/intl.dart';

class MaintenanceUI extends StatelessWidget {
  final String? isMaintenance;
  final String? startDate;
  final String? endDate;

  const MaintenanceUI({
    super.key,
    required this.isMaintenance,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the endDate and format it
    String formattedEndDate = 'N/A';
    if (endDate != null) {
      try {
        final dateTime = DateTime.parse(endDate!);
        formattedEndDate =
            DateFormat('dd MMM yyyy HH:mm').format(dateTime.toLocal());
      } catch (e) {
        formattedEndDate = 'Invalid date';
      }
    }

    final String ongoing =
        "Ongoing maintenance. Expected to finish by $formattedEndDate. Please check back later.";

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 11),
          height: 30,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Marquee(
            text: ongoing,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              fontSize: 14,
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 50,
            velocity: 50,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10,
            accelerationDuration: const Duration(seconds: 1),
            decelerationDuration: const Duration(seconds: 1),
          ),
        ),
        SizedBox(height: CustomSpacing.four),
      ],
    );
  }
}
