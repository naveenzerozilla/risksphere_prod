import 'package:flutter/material.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';

class LocationHeadersScreen extends StatelessWidget {
  final Map<String, dynamic> location;

  LocationHeadersScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    // Get formatted address for the header
    final formattedAddress = location['fields']
        .firstWhere((field) => field['key'] == 'formatted_address',
        orElse: () => {'value': ''})['value'];

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
              itemCount: location['fields'].length,
              itemBuilder: (context, index) {
                final field = location['fields'][index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        field['key'],
                        style: typography.Caption,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        field['value'],
                        style: typography.Body1,
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