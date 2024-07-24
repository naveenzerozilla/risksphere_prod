import 'package:flutter/material.dart';
import '../../../service/language_service.dart';

class LocationHeadersScreen extends StatelessWidget {
  final Map<String, dynamic> location;

  LocationHeadersScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_location_details"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ...location['fields'].map<Widget>((field) {
              return ListTile(
                title: Text(
                  LanguageService.getTranslated(context, field['key']),
                ),
                subtitle: Text(
                  field['value'],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
