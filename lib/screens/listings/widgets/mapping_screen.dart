import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../service/language_service.dart';
import '../../../providers/upload_sov_provider.dart';
import 'location_data.dart';

class MappingScreen extends StatefulWidget {
  final String tempId;
  final String accountId;
  final String accountName;

  const MappingScreen({super.key, required this.tempId, this.accountId = '', this.accountName = ''});

  @override
  _MappingScreenState createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _dropdownItems = [];

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    // Fetch data from API
    await Provider.of<UploadSovProvider>(context, listen: false).fetchSovHeaders(context, widget.tempId);
    _initializeFields();
  }

  void _initializeFields() {
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    if (provider.sovUploadModel != null && provider.sovUploadModel!.result != null) {
      _fields = provider.sovUploadModel!.result!.map((result) {
        return {
          'target': result.targetField,
          'spreadsheet': result.matchedField?.name ?? '',
          'initialSpreadsheet': result.matchedField?.name ?? '',
          'status': result.mappingStatus?.label ?? 'Unmapped',
          'initialStatus': result.mappingStatus?.label ?? 'Unmapped',
          'isChecked': result.isChecked,
          'isUserEdited': result.isUserEdited,
          'matchPercent': result.matchedField?.percentage ?? 0,
        };
      }).toList();

      // Create a set to track unique values
      Set<String> uniqueDropdownValues = {};

      _dropdownItems = provider.sovUploadModel!.result!.expand((result) {
        return result.matches!.map((match) {
          return {
            'value': match.name,
            'label': match.name,
            'matchPercent': match.percentage ?? 0,
          };
        }).where((item) {
          // Only include items with unique values
          return uniqueDropdownValues.add(item['value'] as String);
        }).toList();
      }).toList();

      _dropdownItems.sort((a, b) => (b['matchPercent'] as int).compareTo(a['matchPercent'] as int)); // Sort by matchPercent in descending order

      setState(() {});
    }
  }

  void _showMappingDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LanguageService.getTranslated(context, "app_map_field_title"),
          ),
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              underline: Container(),
              value: _fields[index]['spreadsheet'] != '' ? _fields[index]['spreadsheet'] : null,
              onChanged: (String? newValue) {
                setState(() {
                  _fields[index]['spreadsheet'] = newValue!;
                  _fields[index]['status'] = 'Manual Mapped';
                  _fields[index]['isUserEdited'] = true; // Mark as user edited
                });
                Navigator.of(context).pop();
              },
              items: _dropdownItems.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    '${item['label']} (${item['matchPercent']}% ${LanguageService.getTranslated(context, "app_match")})',
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showActionMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text(
                LanguageService.getTranslated(context, "app_edit_mapping"),
              ),
              onTap: () {
                Navigator.pop(context);
                _showMappingDialog(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh),
              title: Text(
                LanguageService.getTranslated(context, "app_revert_mapping"),
              ),
              onTap: () {
                setState(() {
                  if (_fields[index]['isUserEdited']) {
                    _fields[index]['spreadsheet'] = _fields[index]['initialSpreadsheet'];
                    _fields[index]['status'] = _fields[index]['initialStatus'];
                    _fields[index]['isChecked'] = false;
                    _fields[index]['isUserEdited'] = false; // Reset user edited flag
                  }
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterFields() {
    return _fields.where((field) {
      if (_selectedFilter == 'Auto Mapped' && field['status'] != 'Auto Mapped') return false;
      if (_selectedFilter == 'Manual Mapped' && field['status'] != 'Manual Mapped') return false;
      if (_selectedFilter == 'Unmapped' && field['status'] != 'Unmapped') return false;
      if (_searchQuery.isNotEmpty && !field['target'].toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  void _handleNext() {
    bool hasUnmappedFields = _fields.any((field) => field['status'] == 'Unmapped');
    if (hasUnmappedFields) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getTranslated(context, "app_unmapped_fields_warning")),
        ),
      );
    } else {
      final provider = Provider.of<UploadSovProvider>(context, listen: false);
      if(widget.accountId != '' && widget.accountName != '') {
        provider.submitSovHeadersSubAccounts(context, widget.tempId, provider.sovUploadModel?.url ?? "", _fields, widget.accountId, widget.accountName);
      } else {
        provider.submitSovHeadersAccounts(context, widget.tempId, provider.sovUploadModel?.url ?? "", _fields);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_sov_upload_title"),
        ),
      ),
      body: Consumer<UploadSovProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (provider.sovUploadModel == null || provider.sovUploadModel!.result == null) {
            return Center(
              child: Text(
                LanguageService.getTranslated(context, "app_no_data_available"),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    LanguageService.getTranslated(context, "app_jp_morgan_sov"),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      LanguageService.getTranslated(context, "app_select_columns_to_import"),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: LanguageService.getTranslated(context, "app_search_target_name"),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  children: [
                    FilterChip(
                      label: Text(
                        LanguageService.getTranslated(context, "app_all"),
                      ),
                      selected: _selectedFilter == 'All',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(
                        LanguageService.getTranslated(context, "app_auto_mapped"),
                      ),
                      selected: _selectedFilter == 'Auto Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'Auto Mapped';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(
                        LanguageService.getTranslated(context, "app_manual_mapped"),
                      ),
                      selected: _selectedFilter == 'Manual Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'Manual Mapped';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(
                        LanguageService.getTranslated(context, "app_unmapped"),
                      ),
                      selected: _selectedFilter == 'Unmapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'Unmapped';
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _filterFields().map((field) {
                        int index = _fields.indexOf(field);
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Checkbox(
                              value: field['isChecked'],
                              onChanged: (bool? value) {
                                setState(() {
                                  field['isChecked'] = value!;
                                });
                              },
                            ),
                            title: Text(
                              field['target'],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${LanguageService.getTranslated(context, "app_mapped_to")}: ${field['spreadsheet']}',
                                ),
                                Chip(
                                  label: Text(
                                    LanguageService.getTranslated(context, field['status']),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.more_vert),
                                  onPressed: () => _showActionMenu(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          LanguageService.getTranslated(context, "app_back"),
                        ),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: _handleNext,
                        child: Text(
                          LanguageService.getTranslated(context, "app_next"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
