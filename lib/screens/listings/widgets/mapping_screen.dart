import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:provider/provider.dart';
import '../../../service/language_service.dart';
import '../../../providers/upload_sov_provider.dart';

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

      Set<String> uniqueDropdownValues = {};

      _dropdownItems = provider.sovUploadModel!.result!.expand((result) {
        return result.matches!.map((match) {
          return {
            'value': match.name,
            'label': match.name,
            'matchPercent': match.percentage ?? 0,
          };
        }).where((item) {
          return uniqueDropdownValues.add(item['value'] as String);
        }).toList();
      }).toList();

      _dropdownItems.sort((a, b) => (b['matchPercent'] as int).compareTo(a['matchPercent'] as int));

      setState(() {});
    }
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Unmapped':
        color = Colors.red.withOpacity(0.4);
        break;
      case 'Manual Mapped':
        color = Colors.orange.withOpacity(0.4);
        break;
      case 'Auto Mapped':
        color = Colors.green.withOpacity(0.4);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Text(status, style: TextStyle(color: color == Colors.grey ? Colors.black : Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(LanguageService.getTranslated(context, "app_sov_upload_title"), style: CustomTypography(context).Body1,),
      ),
      body: Consumer<UploadSovProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.sovUploadModel == null || provider.sovUploadModel!.result == null) {
            return Center(child: Text(LanguageService.getTranslated(context, "app_no_data_available")));
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(LanguageService.getTranslated(context, "app_jp_morgan_sov")),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(LanguageService.getTranslated(context, "app_select_columns_to_import")),
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
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  children: [
                    FilterChip(
                      label: Text(LanguageService.getTranslated(context, "app_all")),
                      selected: _selectedFilter == 'All',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(LanguageService.getTranslated(context, "app_auto_mapped")),
                      selected: _selectedFilter == 'Auto Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'Auto Mapped';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(LanguageService.getTranslated(context, "app_manual_mapped")),
                      selected: _selectedFilter == 'Manual Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = 'Manual Mapped';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(LanguageService.getTranslated(context, "app_unmapped")),
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
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Card(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // rotate 90 to right
                                        Transform(transform: Matrix4.rotationZ(1.5708), alignment: Alignment.center, child: Icon(Icons.subdirectory_arrow_right, size: 20,)),
                                        
                                        SizedBox(width: 8),
                                        Text(field['target'], style: CustomTypography(context).Subtitle1),

                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              padding: EdgeInsets.symmetric(horizontal: 10),
                                              menuMaxHeight: 300,
                                              borderRadius: BorderRadius.circular(8),
                                              style: CustomTypography(context).Subtitle1,
                                              underline: SizedBox(),
                                              menuWidth: 250,


                                              value: field['spreadsheet'] != '' ? field['spreadsheet'] : null,
                                              hint: Text("Select mapping", style: CustomTypography(context).Subtitle1,),
                                              items: _dropdownItems.map((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['value'],
                                                  child: Row(
                                                    children: [
                                                      Text('${item['label']}', style: CustomTypography(context).Subtitle2,),
                                                      Spacer(),
                                                      Text('${item['matchPercent']}% Match', style: CustomTypography(context).Caption,),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              selectedItemBuilder: (context) {
                                                return _dropdownItems.map((item) {
                                                  return Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text('${item['label']}', style: CustomTypography(context).Subtitle1,),
                                                  );
                                                }).toList();
                                              },
                                              onChanged: (newValue) {
                                                setState(() {
                                                  field['spreadsheet'] = newValue!;
                                                  field['status'] = 'Manual Mapped';
                                                });
                                              },
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: 10),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              field['status'] = 'Submitted';
                                            });
                                          },

                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle_outline, color: field['status'] == 'Unmapped' ? Colors.grey : AppColors.primaryMain),
                                              SizedBox(width: 5),
                                              Text(
                                                'Submit',
                                                style: TextStyle(color: field['status'] == 'Unmapped' ? Colors.grey : AppColors.primaryMain),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),

                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                                child: _buildStatusChip(field['status']),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Consumer<UploadSovProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return CircularProgressIndicator();
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(

                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMain,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: _handleNext,
                            child: Text("Submit All", style: CustomTypography(context).ButtonLarge.copyWith(color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNext() {
    bool hasUnmappedFields = _fields.any((field) => field['status'] == 'Unmapped');

    if (hasUnmappedFields) {
      // Show a warning if there are unmapped fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getTranslated(context, "app_unmapped_fields_warning")),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      // Proceed with the submission process if all fields are mapped
      final provider = Provider.of<UploadSovProvider>(context, listen: false);
      if (widget.accountId != '' && widget.accountName != '') {
        provider.submitSovHeadersSubAccounts(
          context,
          widget.tempId,
          provider.sovUploadModel?.url ?? "",
          _fields,
          widget.accountId,
          widget.accountName,
        );
      } else {
        provider.submitSovHeadersAccounts(
          context,
          widget.tempId,
          provider.sovUploadModel?.url ?? "",
          _fields,
        );
      }
    }
  }

}
