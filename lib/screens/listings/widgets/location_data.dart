import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:green/constants/enums.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/screens/listings/account_list.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';
import 'location_headers.dart';
import '../../../providers/upload_sov_provider.dart';
import 'package:provider/provider.dart';

class LocationDataScreen extends StatefulWidget {
  final Map<String, dynamic> response;
  final String tempId;
  final List<Map<String, dynamic>> targetHeaders;
  final String accountId;
  final String accountName;

  const LocationDataScreen({
    Key? key,
    required this.response,
    required this.tempId,
    required this.targetHeaders,
    this.accountId = '',
    this.accountName = '',
  }) : super(key: key);

  @override
  _LocationDataScreenState createState() => _LocationDataScreenState();
}

class _LocationDataScreenState extends State<LocationDataScreen> {
  late List<Map<String, dynamic>> locations;
  String _searchQuery = '';
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    Map<String, dynamic> jsonResponse = widget.response;
    List<dynamic> data = jsonResponse['data'];
    locations = data.map((item) {
      return {
        'isChecked': false,
        'fields': item.entries.map((entry) => {'key': entry.key, 'value': entry.value.toString()}).toList(),
      };
    }).toList();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var location in locations) {
        location['isChecked'] = _selectAll;
      }
    });
  }

  void _toggleCheckbox(bool? value, int index) {
    setState(() {
      locations[index]['isChecked'] = value!;
      if (!value) {
        _selectAll = false;
      }
    });
  }

  List<Map<String, dynamic>> _getSelectedLocations() {
    return locations.where((location) => location['isChecked']).toList();
  }

  void _commitSelectedLocations() {
    List<Map<String, dynamic>> selectedLocations = _getSelectedLocations();
    if (selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getTranslated(context, "app_no_locations_selected")),
        ),
      );
      return;
    }
    _submitLocations(selectedLocations, "use_sov_data");
  }

  void _commitAllLocations() {
    _submitLocations(locations, "refresh_all_data");
  }

  void _submitLocations(List<Map<String, dynamic>> locationsToSubmit, String formatType) async {
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    if(widget.accountId.isNotEmpty) {
      await provider.submitLocationsSubAccounts(context, widget.tempId, locationsToSubmit, formatType, widget.targetHeaders, widget.accountId, widget.accountName);
      return;
    } else {
      await provider.submitLocationsAccounts(
          context, widget.tempId, locationsToSubmit, formatType,
          widget.targetHeaders);
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _selectedOption = 'Use SOV Data';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                LanguageService.getTranslated(context, "app_options"),
                style: CustomTypography.H5_Regular,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      LanguageService.getTranslated(context, "app_use_sov_data"),
                      style: CustomTypography.Body1,
                    ),
                    subtitle: Text(
                      LanguageService.getTranslated(context, "app_only_missing_data_processed"),
                      style: CustomTypography.Caption,
                    ),
                    value: "Use SOV Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      LanguageService.getTranslated(context, "app_refresh_all_data"),
                      style: CustomTypography.Body1,
                    ),
                    value: "Refresh All Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButton(
                        type: ButtonType.elevated,
                        onPressed: () {
                          _commitSelectedLocations();
                          Navigator.pop(context);
                        },
                        child: Text(
                          LanguageService.getTranslated(context, "app_commit_selected_locations"),
                          style: CustomTypography.Body1.copyWith(fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButton(
                        type: ButtonType.elevated,
                        onPressed: () {
                          _commitAllLocations();
                          Navigator.pop(context);
                        },
                        child: Text(
                          LanguageService.getTranslated(context, "app_commit_all_locations"),
                          style: CustomTypography.Body1.copyWith(fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButton(
                        type: ButtonType.text,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          LanguageService.getTranslated(context, "app_cancel"),
                          style: CustomTypography.Body1.copyWith(fontWeight: FontWeight.w300),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitLoading = Provider.of<UploadSovProvider>(context).isSubmitLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_upload_preview"),
          style: CustomTypography.H5_Regular,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: LanguageService.getTranslated(context, "app_search_location"),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: _toggleSelectAll,
                    ),
                    Text(
                      LanguageService.getTranslated(context, "app_select_all"),
                      style: CustomTypography.Body1,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      if (_searchQuery.isNotEmpty &&
                          !locations[index]['fields']
                              .any((field) => field['value'].toLowerCase().contains(_searchQuery.toLowerCase()))) {
                        return Container();
                      }
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: locations[index]['isChecked'],
                            onChanged: (bool? value) {
                              _toggleCheckbox(value, index);
                            },
                          ),
                          title: Text(
                            locations[index]['fields']
                                .firstWhere((field) => field['key'] == 'formatted_address', orElse: () => {'value': 'No address available'})['value'],
                            style: CustomTypography.Body1,
                          ),
                          subtitle: Text(
                            locations[index]['fields']
                                .firstWhere((field) => field['key'] == 'Address', orElse: () => {'value': 'No address available'})['value'],
                            style: CustomTypography.Body2,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationHeadersScreen(location: locations[index]),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomButton(
                              type: ButtonType.text,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                LanguageService.getTranslated(context, "app_back"),
                                style: CustomTypography.Body1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomButton(
                              type: ButtonType.elevated,
                              onPressed: _showOptionsDialog,
                              child: Text(
                                LanguageService.getTranslated(context, "app_next"),
                                style: CustomTypography.Body1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSubmitLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
