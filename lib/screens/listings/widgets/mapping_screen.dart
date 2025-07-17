import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:provider/provider.dart';
import '../../../service/language_service.dart';
import '../../../providers/upload_sov_provider.dart';

class MappingScreen extends StatefulWidget {
  final String tempId;
  final String accountId;
  final String accountName;
  final String? subAccountName;
  final String subAccountId;

  const MappingScreen(
      {super.key,
      required this.tempId,
      this.accountId = '',
      this.accountName = '',
      this.subAccountName,
      this.subAccountId = ''});

  @override
  _MappingScreenState createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  Map<String, bool> _pendingReverts = {};
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _initialfields = [];
  List<Map<String, dynamic>> _tempfields = [];
  List<Map<String, dynamic>> _automappedfields = [];
  List<Map<String, dynamic>> _manualappedfields = [];
  List<Map<String, dynamic>> _unmappedfields = [];

  List<Map<String, dynamic>> _dropdownItems = [];

  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchSovHeaders(context, widget.tempId);
    _initializeFields();
  }

  void _initializeFields() {
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    if (provider.sovUploadModel != null &&
        provider.sovUploadModel!.result != null) {
      _fields.clear();
      _unmappedfields.clear();
      _manualappedfields.clear();
      _automappedfields.clear();
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
      _initialfields = provider.sovUploadModel!.result!.map((result) {
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

      _automappedfields =
          _fields.where((test) => test["status"] == 'Auto Mapped').toList();
      _manualappedfields =
          _fields.where((test) => test["status"] == 'Manual Mapped').toList();
      _unmappedfields =
          _fields.where((test) => test["status"] == 'Unmapped').toList();

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

      _dropdownItems.sort((a, b) =>
          (b['matchPercent'] as int).compareTo(a['matchPercent'] as int));

      setState(() {});
    }
  }

  List<Map<String, dynamic>> _filterFields() {
    return _fields.where((field) {
      if (_selectedFilter == 'Auto Mapped' && field['status'] != 'Auto Mapped')
        return false;
      if (_selectedFilter == 'Manual Mapped' &&
          field['status'] != 'Manual Mapped') return false;
      if (_selectedFilter == 'Unmapped' && field['status'] != 'Unmapped')
        return false;
      if (_searchQuery.isNotEmpty &&
          !field['target'].toLowerCase().contains(_searchQuery.toLowerCase()))
        return false;
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
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color == Colors.grey ? Colors.black : Colors.white)),
    );
  }

  void _applyPendingReverts() {
    setState(() {
      for (var field in _fields) {
        if (_pendingReverts.containsKey(field['target']) &&
            _pendingReverts[field['target']] == true) {
          field['spreadsheet'] =
              field['initialSpreadsheet']; // Restore old value
          // field['status'] = 'Unmapped'; // Change status back
        }
      }
      _pendingReverts.clear(); // Clear pending revert list after applying
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_sov_upload_title"),
          style: CustomTypography(context).Body1,
        ),
      ),
      body: Consumer<UploadSovProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (provider.sovUploadModel == null ||
              provider.sovUploadModel!.result == null) {
            return Center(
                child: Text(LanguageService.getTranslated(
                    context, "app_no_data_available")));
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(LanguageService.getTranslated(
                      context, "app_jp_morgan_sov")),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(LanguageService.getTranslated(
                        context, "app_select_columns_to_import")),
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
                          labelText: LanguageService.getTranslated(
                              context, "app_search_target_name"),
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
                      label: Text(LanguageService.getTranslated(
                          context, "app_auto_mapped")),
                      selected: _selectedFilter == 'Auto Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _hasChanges = true;
                          _selectedFilter = 'Auto Mapped';
                          _applyPendingReverts(); // Apply revert when switching filter
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(LanguageService.getTranslated(
                          context, "app_manual_mapped")),
                      selected: _selectedFilter == 'Manual Mapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _hasChanges = true;
                          _tempfields = _tempfields.toSet().toList();
                          _manualappedfields.addAll(_tempfields.where((item) =>
                              !_manualappedfields.any((existing) =>
                                  existing["spreadsheet"] ==
                                  item["spreadsheet"])));

                          for (var i in _tempfields) {
                            _unmappedfields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _automappedfields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _fields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _fields.add(i);
                          }
                          _tempfields.clear();
                          _selectedFilter = 'Manual Mapped';
                          _applyPendingReverts(); // Apply revert when switching filter
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(LanguageService.getTranslated(
                          context, "app_unmapped")),
                      selected: _selectedFilter == 'Unmapped',
                      onSelected: (bool selected) {
                        setState(() {
                          _hasChanges = true;
                          _hasChanges = true;
                          _tempfields = _tempfields.toSet().toList();
                          _manualappedfields.addAll(_tempfields.where((item) =>
                              !_manualappedfields.any((existing) =>
                                  existing["spreadsheet"] ==
                                  item["spreadsheet"])));
                          // _manualappedfields.addAll(_tempfields);
                          for (var i in _tempfields) {
                            _unmappedfields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _automappedfields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _fields.removeWhere((test) =>
                                test["spreadsheet"] == i["spreadsheet"]);
                            _fields.add(i);
                          }
                          _selectedFilter = 'Unmapped';
                          _applyPendingReverts(); // Apply revert when switching filter
                        });
                      },
                    ),
                    _hasChanges
                        ? TextButton(
                            onPressed: _hasChanges
                                ? () {
                                    setState(() {
                                      _selectedFilter = 'All';
                                      _hasChanges = false;
                                    });
                                  }
                                : null, // Disable button if no changes
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue, // Blue text color
                              backgroundColor: Colors.black, // White background
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: Colors.blue), // Blue border
                              ),
                            ),
                            child: Text("View all parameters"),
                          )
                        : Container(),
                  ],
                ),
                SizedBox(height: 20),
                _selectedFilter == 'All'
                    ? Builder(builder: (context) {
                        return Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: _fields
                                  .where((field) =>
                                      _searchQuery.isEmpty ||
                                      field['target']
                                          .toLowerCase()
                                          .contains(_searchQuery.toLowerCase()))
                                  .map((field)
                                      // _fields.map((field)

                                      {
                                return Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Card(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // rotate 90 to right
                                                Transform(
                                                    transform:
                                                        Matrix4.rotationZ(
                                                            1.5708),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons
                                                          .subdirectory_arrow_right,
                                                      size: 20,
                                                    )),

                                                SizedBox(width: 8),
                                                Text(field['target'],
                                                    style: CustomTypography(
                                                            context)
                                                        .Subtitle1),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child:
                                                        DropdownButton<String>(
                                                      isExpanded: true,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10),
                                                      menuMaxHeight: 300,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      style: CustomTypography(
                                                              context)
                                                          .Subtitle1,
                                                      underline: SizedBox(),
                                                      menuWidth: 250,

                                                      // Ensure selected value exists in dropdown items, otherwise set null
                                                      value: provider
                                                                  .sovUploadModel
                                                                  ?.result
                                                                  ?.firstWhereOrNull((res) =>
                                                                      res.targetField ==
                                                                      field[
                                                                          'target'])
                                                                  ?.matches
                                                                  ?.any((match) =>
                                                                      match
                                                                          .name ==
                                                                      field[
                                                                          'spreadsheet']) ??
                                                              false
                                                          ? field['spreadsheet']
                                                          : null,

                                                      hint: Text(
                                                        "Select mapping",
                                                        style: CustomTypography(
                                                                context)
                                                            .Subtitle1,
                                                      ),

                                                      items: provider
                                                              .sovUploadModel
                                                              ?.result
                                                              ?.firstWhereOrNull((res) =>
                                                                  res.targetField ==
                                                                  field[
                                                                      'target'])
                                                              ?.matches
                                                              ?.map((match) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: match.name,
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    match.name ??
                                                                        "Unknown",
                                                                    style: CustomTypography(
                                                                            context)
                                                                        .Subtitle2,
                                                                  ),
                                                                  Spacer(),
                                                                  Text(
                                                                    '${match.percentage ?? 0}% Match',
                                                                    style: CustomTypography(
                                                                            context)
                                                                        .Caption,
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }).toList() ??
                                                          [],
                                                      // Prevent null list
                                                      selectedItemBuilder:
                                                          (context) {
                                                        return provider
                                                                .sovUploadModel
                                                                ?.result
                                                                ?.firstWhereOrNull((res) =>
                                                                    res.targetField ==
                                                                    field[
                                                                        'target'])
                                                                ?.matches
                                                                ?.map((match) {
                                                              return Align(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Text(
                                                                  match.name ??
                                                                      "Unknown",
                                                                  style: CustomTypography(
                                                                          context)
                                                                      .Subtitle1,
                                                                ),
                                                              );
                                                            }).toList() ??
                                                            [];
                                                      },


                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          field['spreadsheet'] =
                                                              newValue!;
                                                          field['status'] =
                                                              'Manual Mapped';
                                                          _tempfields
                                                              .add(field);
                                                        });
                                                        print(
                                                            "Status: ${field['status']}");


                                                        print(
                                                            "Selected Value1: $newValue");
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                TextButton(
                                                  onPressed: field['status'] ==
                                                          'Manual Mapped'
                                                      ? () {
                                                          setState(() {
                                                            // Find the original mapping
                                                            var originalField =
                                                                _initialfields
                                                                    .firstWhereOrNull((test) =>
                                                                        test[
                                                                            "target"] ==
                                                                        field[
                                                                            "target"]);

                                                            if (originalField !=
                                                                null) {
                                                              field["spreadsheet"] =
                                                                  originalField[
                                                                      "spreadsheet"];

                                                              if (originalField[
                                                                      'status'] ==
                                                                  'Auto Mapped') {
                                                                setState(() {
                                                                  field['status'] =
                                                                      'Auto Mapped';
                                                                });
                                                                _automappedfields
                                                                    .add(field);
                                                              } else {
                                                                setState(() {
                                                                  field['status'] =
                                                                      'Unmapped';
                                                                });
                                                                _unmappedfields
                                                                    .add(field);
                                                              }
                                                            } else {
                                                              field["spreadsheet"] =
                                                                  '';
                                                            }

                                                            // Update field lists accordingly
                                                            _tempfields.removeWhere(
                                                                (test) =>
                                                                    test[
                                                                        "spreadsheet"] ==
                                                                    field[
                                                                        "spreadsheet"]);

                                                            _manualappedfields
                                                                .removeWhere((test) =>
                                                                    test[
                                                                        "spreadsheet"] ==
                                                                    field[
                                                                        "spreadsheet"]);

                                                            _pendingReverts[field[
                                                                    'target']] =
                                                                true; // Mark field for revert
                                                          });
                                                        }
                                                      : null,

                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Revert',
                                                        style: TextStyle(
                                                          color: field[
                                                                      'status'] ==
                                                                  'Manual Mapped'
                                                              ? AppColors
                                                                  .primaryMain
                                                              : Colors.grey,
                                                        ),
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
                                        padding: const EdgeInsets.only(
                                            top: 4.0, right: 4.0),
                                        child:
                                            _buildStatusChip(field['status']),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      })
                    : _selectedFilter == 'Auto Mapped'
                        ? Builder(builder: (context) {
                            return Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children:

                                      // _automappedfields.map((field)

                                      _automappedfields
                                          .where((field) =>
                                              _searchQuery.isEmpty ||
                                              field['target']
                                                  .toLowerCase()
                                                  .contains(_searchQuery
                                                      .toLowerCase()))
                                          .map((field) {
                                    return Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        Card(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHigh,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    // rotate 90 to right
                                                    Transform(
                                                        transform:
                                                            Matrix4.rotationZ(
                                                                1.5708),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons
                                                              .subdirectory_arrow_right,
                                                          size: 20,
                                                        )),

                                                    SizedBox(width: 8),
                                                    Text(field['target'],
                                                        style: CustomTypography(
                                                                context)
                                                            .Subtitle1),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  Colors.grey),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: DropdownButton<
                                                            String>(
                                                          isExpanded: true,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          menuMaxHeight: 300,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          style:
                                                              CustomTypography(
                                                                      context)
                                                                  .Subtitle1,
                                                          underline: SizedBox(),
                                                          menuWidth: 250,
                                                          value: provider
                                                                      .sovUploadModel
                                                                      ?.result
                                                                      ?.firstWhereOrNull((res) =>
                                                                          res.targetField ==
                                                                          field[
                                                                              'target'])
                                                                      ?.matches
                                                                      ?.any((match) =>
                                                                          match
                                                                              .name ==
                                                                          field[
                                                                              'spreadsheet']) ??
                                                                  false
                                                              ? field[
                                                                  'spreadsheet']
                                                              : null,
                                                          // Ensure value exists in dropdown

                                                          hint: Text(
                                                            "Select mapping",
                                                            style:
                                                                CustomTypography(
                                                                        context)
                                                                    .Subtitle1,
                                                          ),

                                                          items: provider
                                                                  .sovUploadModel
                                                                  ?.result
                                                                  ?.firstWhereOrNull((res) =>
                                                                      res.targetField ==
                                                                      field[
                                                                          'target'])
                                                                  ?.matches
                                                                  ?.map(
                                                                      (match) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: match
                                                                      .name,
                                                                  child: Row(
                                                                    children: [
                                                                      Text(
                                                                        match.name ??
                                                                            "Unknown",
                                                                        style: CustomTypography(context)
                                                                            .Subtitle2,
                                                                      ),
                                                                      Spacer(),
                                                                      Text(
                                                                        '${match.percentage ?? 0}% Match',
                                                                        style: CustomTypography(context)
                                                                            .Caption,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }).toList() ??
                                                              [],
                                                          // Prevent null list

                                                          selectedItemBuilder:
                                                              (context) {
                                                            return provider
                                                                    .sovUploadModel
                                                                    ?.result
                                                                    ?.firstWhereOrNull((res) =>
                                                                        res.targetField ==
                                                                        field[
                                                                            'target'])
                                                                    ?.matches
                                                                    ?.map(
                                                                        (match) {
                                                                  return Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Text(
                                                                      match.name ??
                                                                          "Unknown",
                                                                      style: CustomTypography(
                                                                              context)
                                                                          .Subtitle1,
                                                                    ),
                                                                  );
                                                                }).toList() ??
                                                                [];
                                                          },

                                                          onChanged:
                                                              (newValue) {
                                                            setState(() {
                                                              field['spreadsheet'] =
                                                                  newValue!;
                                                              field['status'] =
                                                                  'Manual Mapped';
                                                              _tempfields
                                                                  .add(field);
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    TextButton(
                                                      onPressed: field[
                                                                  'status'] ==
                                                              'Manual Mapped'
                                                          ? () {
                                                              setState(() {
                                                                field['status'] =
                                                                    "Auto Mapped";
                                                                var originalField =
                                                                    _initialfields.firstWhereOrNull((test) =>
                                                                        test[
                                                                            "target"] ==
                                                                        field[
                                                                            "target"]);

                                                                if (originalField !=
                                                                    null) {
                                                                  field["spreadsheet"] =
                                                                      originalField[
                                                                          "spreadsheet"];
                                                                }

                                                                _tempfields.removeWhere(
                                                                    (test) =>
                                                                        test[
                                                                            "spreadsheet"] ==
                                                                        field[
                                                                            "spreadsheet"]);
                                                                _pendingReverts[
                                                                        field[
                                                                            'target']] =
                                                                    true;
                                                              });
                                                            }
                                                          : null,
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            'Revert',
                                                            style: TextStyle(
                                                              color: field[
                                                                          'status'] ==
                                                                      'Manual Mapped'
                                                                  ? AppColors
                                                                      .primaryMain
                                                                  : Colors.grey,
                                                            ),
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
                                            padding: const EdgeInsets.only(
                                                top: 4.0, right: 4.0),
                                            child: _buildStatusChip(
                                                field['status']),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          })
                        : _selectedFilter == 'Manual Mapped'
                            ? Builder(builder: (context) {
                                return Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children:


                                          _manualappedfields
                                              .where((field) =>
                                                  _searchQuery.isEmpty ||
                                                  field['target']
                                                      .toLowerCase()
                                                      .contains(_searchQuery
                                                          .toLowerCase()))
                                              .map((field) {
                                        return Stack(
                                          clipBehavior: Clip.hardEdge,
                                          children: [
                                            Card(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHigh,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        // rotate 90 to right
                                                        Transform(
                                                            transform: Matrix4
                                                                .rotationZ(
                                                                    1.5708),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Icon(
                                                              Icons
                                                                  .subdirectory_arrow_right,
                                                              size: 20,
                                                            )),

                                                        SizedBox(width: 8),
                                                        Text(field['target'],
                                                            style:
                                                                CustomTypography(
                                                                        context)
                                                                    .Subtitle1),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10),
                                                              menuMaxHeight:
                                                                  300,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              style: CustomTypography(
                                                                      context)
                                                                  .Subtitle1,
                                                              underline:
                                                                  SizedBox(),
                                                              menuWidth: 250,

                                                              // Ensure selected value exists in dropdown items, otherwise set null
                                                              value: provider
                                                                          .sovUploadModel
                                                                          ?.result
                                                                          ?.firstWhereOrNull((res) =>
                                                                              res.targetField ==
                                                                              field[
                                                                                  'target'])
                                                                          ?.matches
                                                                          ?.any((match) =>
                                                                              match.name ==
                                                                              field[
                                                                                  'spreadsheet']) ??
                                                                      false
                                                                  ? field[
                                                                      'spreadsheet']
                                                                  : null,

                                                              hint: Text(
                                                                "Select mapping",
                                                                style: CustomTypography(
                                                                        context)
                                                                    .Subtitle1,
                                                              ),

                                                              items: provider
                                                                      .sovUploadModel
                                                                      ?.result
                                                                      ?.firstWhereOrNull((res) =>
                                                                          res.targetField ==
                                                                          field[
                                                                              'target'])
                                                                      ?.matches
                                                                      ?.map(
                                                                          (match) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value: match
                                                                          .name,
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            match.name ??
                                                                                "Unknown",
                                                                            style:
                                                                                CustomTypography(context).Subtitle2,
                                                                          ),
                                                                          Spacer(),
                                                                          Text(
                                                                            '${match.percentage ?? 0}% Match',
                                                                            style:
                                                                                CustomTypography(context).Caption,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  }).toList() ??
                                                                  [],
                                                              // Prevent null list

                                                              selectedItemBuilder:
                                                                  (context) {
                                                                return provider
                                                                        .sovUploadModel
                                                                        ?.result
                                                                        ?.firstWhereOrNull((res) =>
                                                                            res.targetField ==
                                                                            field[
                                                                                'target'])
                                                                        ?.matches
                                                                        ?.map(
                                                                            (match) {
                                                                      return Align(
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child:
                                                                            Text(
                                                                          match.name ??
                                                                              "Unknown",
                                                                          style:
                                                                              CustomTypography(context).Subtitle1,
                                                                        ),
                                                                      );
                                                                    }).toList() ??
                                                                    [];
                                                              },

                                                              onChanged:
                                                                  (newValue) {
                                                                setState(() {
                                                                  field['spreadsheet'] =
                                                                      newValue!;
                                                                  field['status'] =
                                                                      'Auto Mapped';
                                                                  _tempfields
                                                                      .add(
                                                                          field);
                                                                });
                                                                print(
                                                                    "Status: ${field['status']}");
                                                                print(
                                                                    "Selected Value: $newValue");
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        TextButton(
                                                          onPressed: field[
                                                                      'status'] ==
                                                                  'Manual Mapped'
                                                              ? () {
                                                                  setState(() {
                                                                    // Find the original mapping
                                                                    var originalField = _initialfields.firstWhereOrNull((test) =>
                                                                        test[
                                                                            "target"] ==
                                                                        field[
                                                                            "target"]);

                                                                    if (originalField !=
                                                                        null) {
                                                                      field["spreadsheet"] =
                                                                          originalField[
                                                                              "spreadsheet"];

                                                                      if (originalField[
                                                                              'status'] ==
                                                                          'Auto Mapped') {
                                                                        setState(
                                                                            () {
                                                                          field['status'] =
                                                                              'Auto Mapped';
                                                                        });
                                                                        _automappedfields
                                                                            .add(field);
                                                                      } else {
                                                                        setState(
                                                                            () {
                                                                          field['status'] =
                                                                              'Unmapped';
                                                                        });
                                                                        _unmappedfields
                                                                            .add(field);
                                                                      }
                                                                    } else {
                                                                      field["spreadsheet"] =
                                                                          '';
                                                                    }

                                                                    // Update field lists accordingly
                                                                    _tempfields.removeWhere((test) =>
                                                                        test[
                                                                            "spreadsheet"] ==
                                                                        field[
                                                                            "spreadsheet"]);

                                                                    _manualappedfields.removeWhere((test) =>
                                                                        test[
                                                                            "spreadsheet"] ==
                                                                        field[
                                                                            "spreadsheet"]);

                                                                    _pendingReverts[
                                                                            field['target']] =
                                                                        true; // Mark field for revert
                                                                  });
                                                                }
                                                              : null,
                                                          // Disable if not manually mapped
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Revert',
                                                                style:
                                                                    TextStyle(
                                                                  color: field[
                                                                              'status'] ==
                                                                          'Manual Mapped'
                                                                      ? AppColors
                                                                          .primaryMain
                                                                      : Colors
                                                                          .grey,
                                                                ),
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
                                                padding: const EdgeInsets.only(
                                                    top: 4.0, right: 4.0),
                                                child: _buildStatusChip(
                                                    field['status']),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              })
                            : Builder(builder: (context) {
                                return Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: _unmappedfields
                                          .where((field) =>
                                              _searchQuery.isEmpty ||
                                              field['target']
                                                  .toLowerCase()
                                                  .contains(_searchQuery
                                                      .toLowerCase()))
                                          .map((field) {
                                        return Stack(
                                          clipBehavior: Clip.hardEdge,
                                          children: [
                                            Card(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHigh,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        // rotate 90 to right
                                                        Transform(
                                                            transform: Matrix4
                                                                .rotationZ(
                                                                    1.5708),
                                                            alignment: Alignment
                                                                .center,
                                                            child: Icon(
                                                              Icons
                                                                  .subdirectory_arrow_right,
                                                              size: 20,
                                                            )),

                                                        SizedBox(width: 8),
                                                        Text(field['target'],
                                                            style:
                                                                CustomTypography(
                                                                        context)
                                                                    .Subtitle1),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10),
                                                              menuMaxHeight:
                                                                  300,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              style: CustomTypography(
                                                                      context)
                                                                  .Subtitle1,
                                                              underline:
                                                                  SizedBox(),
                                                              menuWidth: 250,

                                                              // Ensure selected value exists in dropdown items, otherwise set null
                                                              value: provider
                                                                          .sovUploadModel
                                                                          ?.result
                                                                          ?.firstWhereOrNull((res) =>
                                                                              res.targetField ==
                                                                              field[
                                                                                  'target'])
                                                                          ?.matches
                                                                          ?.any((match) =>
                                                                              match.name ==
                                                                              field[
                                                                                  'spreadsheet']) ??
                                                                      false
                                                                  ? field[
                                                                      'spreadsheet']
                                                                  : null,

                                                              hint: Text(
                                                                "Select mapping",
                                                                style: CustomTypography(
                                                                        context)
                                                                    .Subtitle1,
                                                              ),

                                                              items: provider
                                                                      .sovUploadModel
                                                                      ?.result
                                                                      ?.firstWhereOrNull((res) =>
                                                                          res.targetField ==
                                                                          field[
                                                                              'target'])
                                                                      ?.matches
                                                                      ?.map(
                                                                          (match) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value: match
                                                                          .name,
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            match.name ??
                                                                                "Unknown",
                                                                            style:
                                                                                CustomTypography(context).Subtitle2,
                                                                          ),
                                                                          Spacer(),
                                                                          Text(
                                                                            '${match.percentage ?? 0}% Match',
                                                                            style:
                                                                                CustomTypography(context).Caption,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  }).toList() ??
                                                                  [],
                                                              // Prevent null list

                                                              selectedItemBuilder:
                                                                  (context) {
                                                                return provider
                                                                        .sovUploadModel
                                                                        ?.result
                                                                        ?.firstWhereOrNull((res) =>
                                                                            res.targetField ==
                                                                            field[
                                                                                'target'])
                                                                        ?.matches
                                                                        ?.map(
                                                                            (match) {
                                                                      return Align(
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child:
                                                                            Text(
                                                                          match.name ??
                                                                              "Unknown",
                                                                          style:
                                                                              CustomTypography(context).Subtitle1,
                                                                        ),
                                                                      );
                                                                    }).toList() ??
                                                                    [];
                                                              },

                                                              onChanged:
                                                                  (newValue) {
                                                                setState(() {
                                                                  field['spreadsheet'] =
                                                                      newValue!;
                                                                  field['status'] =
                                                                      'Manual Mapped';
                                                                  _tempfields
                                                                      .add(
                                                                          field);
                                                                });
                                                                print(
                                                                    "Status: ${field['status']}");
                                                                print(
                                                                    "Selected Value: $newValue");
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        TextButton(
                                                          onPressed: field[
                                                                      'status'] ==
                                                                  'Manual Mapped'
                                                              ? () {
                                                                  setState(() {
                                                                    field['status'] =
                                                                        'Unmapped';

                                                                    // Find the original mapping
                                                                    var originalField = _initialfields.firstWhereOrNull((test) =>
                                                                        test[
                                                                            "target"] ==
                                                                        field[
                                                                            "target"]);

                                                                    if (originalField !=
                                                                        null) {
                                                                      field["spreadsheet"] =
                                                                          originalField[
                                                                              "spreadsheet"];
                                                                    } else {
                                                                      field["spreadsheet"] =
                                                                          '';
                                                                    }

                                                                    // Update field lists accordingly
                                                                    _tempfields.removeWhere((test) =>
                                                                        test[
                                                                            "spreadsheet"] ==
                                                                        field[
                                                                            "spreadsheet"]);
                                                                    _pendingReverts[
                                                                            field['target']] =
                                                                        true; // Mark field for revert
                                                                  });
                                                                }
                                                              : null,
                                                          // Disable if not manually mapped
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Revert',
                                                                style:
                                                                    TextStyle(
                                                                  color: field[
                                                                              'status'] ==
                                                                          'Manual Mapped'
                                                                      ? AppColors
                                                                          .primaryMain
                                                                      : Colors
                                                                          .grey,
                                                                ),
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
                                                padding: const EdgeInsets.only(
                                                    top: 4.0, right: 4.0),
                                                child: _buildStatusChip(
                                                    field['status']),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              }),
                Consumer<UploadSovProvider>(
                    builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return CircularProgressIndicator();
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMain,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: _handleNext,
                          child: Text("Submit All",
                              style: CustomTypography(context)
                                  .ButtonLarge
                                  .copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNext() {
    bool hasUnmappedFields =
        _fields.any((field) => field['status'] == 'Unmapped');

    if (hasUnmappedFields) {
      // Show a warning if there are unmapped fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getTranslated(
              context, "app_unmapped_fields_warning")),
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
          widget.subAccountName ?? "",
          widget.subAccountId,
        );
      } else {
        provider.submitSovHeadersAccounts(
          context,
          widget.tempId,
          provider.sovUploadModel?.url ?? "",
          _fields,
          widget.subAccountName ?? "",
        );
      }
    }
  }
}
