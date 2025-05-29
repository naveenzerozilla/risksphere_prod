import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';

class LocationHeadersScreen extends StatelessWidget {
  final Map<String, dynamic> location;

  LocationHeadersScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);

    // Handle null or empty values gracefully
    final formattedAddress = location['formatted_address'] ?? 'No address available';
    final fields = location.entries
        .where((entry) =>
    entry.key != 'formatted_address' && // Exclude formatted_address (already shown in the header)
        entry.key != 'duplicates' &&       // Exclude duplicates
        entry.key != 'is_duplicate' &&     // Exclude is_duplicate
        entry.key != 'line_no' &&          // Exclude line_no
        entry.key != 'id' &&
        entry.key != 'type' &&   // Exclude id
        entry.key != 'isChecked' &&        // Exclude isChecked
        entry.value != null &&             // Exclude null values
        entry.value.toString().trim().isNotEmpty) // Exclude empty or whitespace-only values
        .map((entry) => {
      'key': entry.key
          .replaceAll('_', ' ')        // Replace underscores with spaces
          .split(' ')                  // Split into words
          .map((word) => word[0].toUpperCase() + word.substring(1)) // Capitalize each word
          .join(' '),                  // Join back with spaces
      'value': entry.value.toString()
    })
        .toList();




    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Header Details',
          style: typography.Body1.copyWith(fontWeight: FontWeight.w300),
        ),
      ),
      body: Column(
        children: [
          // Formatted address header
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey[900],
            child: Text(
              formattedAddress,
              style: typography.Body1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          // Fields list
          Expanded(
            child: ListView.builder(
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        field['key'] ?? 'Unknown Key',
                        style: typography.Caption.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        field['value'] ?? 'Unknown Value',
                        style: typography.Body1.copyWith(color: Colors.white),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey[800],
                    ),
                  ],
                );
              },
            ),
          ),
          // Bottom padding for iOS home indicator
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
