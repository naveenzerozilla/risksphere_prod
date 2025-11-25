import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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
  final Set<String> _usedDataParameters = {};
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
        final hasMatch = result.matchedField != null;
        final fallbackId =
            (result.matches != null && result.matches!.isNotEmpty)
                ? result.matches!.first.id
                : null;

        // -------------------------
        // 1️⃣ IGNORE LOGIC
        // -------------------------
        final idToUse = result.matchedField?.id ?? fallbackId;
        final isIgnore = idToUse != null && idToUse.endsWith("_ignore");

        // -------------------------
        // 2️⃣ MATCH PERCENT LOGIC
        // -------------------------
        int matchPercent;

        if (isIgnore) {
          matchPercent = 0;
        } else {
          matchPercent = hasMatch ? 100 : 0;
        }
        // final hasMatch = result.matchedField != null;
        // final fallbackId = (result.matches != null && result.matches!.isNotEmpty)
        //     ? result.matches!.first.id
        //     : null;
        //
        // // If we are using fallback id → percentage must be 0
        // final matchPercent = hasMatch ? 100 : 0;

        return {
          'id': result.matchedField?.id ?? fallbackId,
          'target': result.targetField,
          'spreadsheet': result.matchedField?.name ?? '',
          'initialSpreadsheet': result.matchedField?.name ?? '',
          'status': result.mappingStatus?.label ?? 'Unmapped',
          'initialStatus': result.mappingStatus?.label ?? 'Unmapped',
          'isChecked': result.isChecked,
          'isUserEdited': result.isUserEdited,

          // 🎯 main fix
          'matchPercent': matchPercent,
          'percentage': matchPercent,

          'is_data_parameter': result.matchedField?.is_data_parameter ?? false,
        };
      }).toList();

      _initialfields = provider.sovUploadModel!.result!.map((result) {
        return {
          'id': result.matchedField?.id,
          'target': result.targetField,
          'spreadsheet': result.matchedField?.name ?? '',
          'initialSpreadsheet': result.matchedField?.name ?? '',
          'status': result.mappingStatus?.label ?? 'Unmapped',
          'initialStatus': result.mappingStatus?.label ?? 'Unmapped',
          'isChecked': result.isChecked,
          'isUserEdited': result.isUserEdited,
          'matchPercent': result.matchedField?.percentage,
          'is_data_parameter': result.matchedField?.is_data_parameter ?? false,
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SOV - Upload & Map",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 4),
            Text("Choose columns to map to spreadsheet fields.",
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
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
                    ?
                Builder(builder: (context) {
                  return Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _fields
                            .where((field) =>
                        _searchQuery.isEmpty ||
                            field['target']
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .map((field) {
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
                                        children: [
                                          Transform(
                                            transform: Matrix4.rotationZ(1.5708),
                                            alignment: Alignment.center,
                                            child: Icon(Icons.subdirectory_arrow_right, size: 20),
                                          ),
                                          SizedBox(width: 8),
                                          Text(field['target'],
                                              style: CustomTypography(context).Subtitle1),
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
                                              child: DropdownButtonHideUnderline(
                                                child: Builder(builder: (context) {
                                                  final matches = provider.sovUploadModel
                                                      ?.result
                                                      ?.firstWhereOrNull((res) =>
                                                  res.targetField ==
                                                      field['target'])
                                                      ?.matches ??
                                                      [];

                                                  // BUILD ITEMS with disable logic
                                                  final dropdownItems = matches.map((match) {
                                                    final String valueName = match.name ?? '';
                                                    final String displayName =
                                                        valueName +
                                                            (match.is_data_parameter == true
                                                                ? ' (P)'
                                                                : '');

                                                    final bool disableOption =
                                                        match.is_data_parameter == true &&
                                                            _usedDataParameters
                                                                .contains(valueName) &&
                                                            field['spreadsheet'] != valueName;

                                                    return DropdownMenuItem<String>(
                                                      value: valueName,
                                                      enabled: !disableOption,
                                                      child: Opacity(
                                                        opacity: disableOption ? 0.4 : 1.0,
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(displayName,
                                                                  style:
                                                                  CustomTypography(context)
                                                                      .Subtitle2),
                                                            ),
                                                            Text(
                                                              '${match.percentage ?? 0}% Match',
                                                              style: CustomTypography(context)
                                                                  .Caption,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList();

                                                  return DropdownButton2<String>(
                                                    isExpanded: true,
                                                    dropdownStyleData: DropdownStyleData(
                                                      maxHeight: 300,
                                                      width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                          0.9 -
                                                          75,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surface,
                                                      ),
                                                      offset: Offset(0, -2),
                                                    ),
                                                    buttonStyleData: const ButtonStyleData(
                                                      padding:
                                                      EdgeInsets.symmetric(horizontal: 10),
                                                    ),
                                                    style: CustomTypography(context).Subtitle1,
                                                    hint: Text("Select mapping",
                                                        style: CustomTypography(context)
                                                            .Subtitle1),

                                                    value: (field['spreadsheet']
                                                        ?.toString()
                                                        .isNotEmpty ??
                                                        false)
                                                        ? field['spreadsheet']
                                                        : null,

                                                    items: dropdownItems,

                                                    selectedItemBuilder: (context) {
                                                      return matches.map((match) {
                                                        final dis = (match.name ?? '') +
                                                            (match.is_data_parameter == true
                                                                ? ' (P)'
                                                                : '');
                                                        return Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: Text(
                                                            dis,
                                                            style: CustomTypography(context)
                                                                .Subtitle1,
                                                          ),
                                                        );
                                                      }).toList();
                                                    },

                                                    onChanged: (newValue) {
                                                      if (newValue == null) return;

                                                      final match = matches.firstWhereOrNull(
                                                              (m) => m.name == newValue);

                                                      setState(() {
                                                        // Remove previous DP
                                                        final prev = field['spreadsheet'];
                                                        if (prev != null &&
                                                            prev.toString().isNotEmpty &&
                                                            field['is_data_parameter'] == true) {
                                                          _usedDataParameters.remove(prev);
                                                        }

                                                        // Assign new values
                                                        field['spreadsheet'] = newValue;
                                                        field['id'] = match?.id;
                                                        field['percentage'] =
                                                            match?.percentage ?? 0;
                                                        field['matchPercent'] =
                                                            match?.percentage ?? 0;
                                                        field['is_data_parameter'] =
                                                            match?.is_data_parameter ?? false;
                                                        field['status'] = 'Manual Mapped';

                                                        // Add new DP
                                                        if (match?.is_data_parameter == true) {
                                                          _usedDataParameters.add(newValue);
                                                        }

                                                        // Update temp fields
                                                        _tempfields.removeWhere((t) =>
                                                        t['target'] == field['target']);
                                                        _tempfields.add(
                                                            Map<String, dynamic>.from(field));
                                                      });
                                                    },
                                                  );
                                                }),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),

                                          /// REVERT BUTTON (same logic as above sections)
                                          TextButton(
                                            onPressed: field['status'] == 'Manual Mapped'
                                                ? () {
                                              setState(() {
                                                final current = field['spreadsheet'];

                                                if (current != null &&
                                                    current.toString().isNotEmpty &&
                                                    field['is_data_parameter'] == true) {
                                                  _usedDataParameters.remove(current);
                                                }

                                                var original =
                                                _initialfields.firstWhereOrNull(
                                                        (t) =>
                                                    t["target"] ==
                                                        field["target"]);

                                                if (original != null) {
                                                  field["spreadsheet"] =
                                                      original["spreadsheet"] ?? '';
                                                  field["is_data_parameter"] =
                                                      original["is_data_parameter"] ??
                                                          false;
                                                  field["percentage"] =
                                                      original["percentage"] ?? 0;
                                                  field["matchPercent"] =
                                                      original["percentage"] ?? 0;

                                                  if (field["is_data_parameter"] == true &&
                                                      field["spreadsheet"]
                                                          .toString()
                                                          .isNotEmpty) {
                                                    _usedDataParameters
                                                        .add(field["spreadsheet"]);
                                                  }
                                                } else {
                                                  field["spreadsheet"] = '';
                                                  field["is_data_parameter"] = false;
                                                  field["percentage"] = 0;
                                                  field["matchPercent"] = 0;
                                                }

                                                field['status'] = 'Unmapped';

                                                _tempfields.removeWhere((t) =>
                                                t['target'] == field['target']);
                                                _pendingReverts[field['target']] = true;
                                              });
                                            }
                                                : null,
                                            child: Text(
                                              'Revert',
                                              style: TextStyle(
                                                color: field['status'] == 'Manual Mapped'
                                                    ? AppColors.primaryMain
                                                    : Colors.grey,
                                              ),
                                            ),
                                          )
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
                                  padding: EdgeInsets.only(top: 4.0, right: 4.0),
                                  child: _buildStatusChip(field['status']),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                })

              // Builder(builder: (context) {
                //         return Expanded(
                //           child: SingleChildScrollView(
                //             child: Column(
                //               children: _fields
                //                   .where((field) =>
                //                       _searchQuery.isEmpty ||
                //                       field['target']
                //                           .toLowerCase()
                //                           .contains(_searchQuery.toLowerCase()))
                //                   .map((field)
                //                       // _fields.map((field)
                //
                //                       {
                //                 return Stack(
                //                   clipBehavior: Clip.hardEdge,
                //                   children: [
                //                     Card(
                //                       color: Theme.of(context)
                //                           .colorScheme
                //                           .surfaceContainerHigh,
                //                       child: Padding(
                //                         padding: const EdgeInsets.all(8.0),
                //                         child: Column(
                //                           crossAxisAlignment:
                //                               CrossAxisAlignment.start,
                //                           children: [
                //                             Row(
                //                               mainAxisAlignment:
                //                                   MainAxisAlignment.start,
                //                               children: [
                //                                 // rotate 90 to right
                //                                 Transform(
                //                                     transform:
                //                                         Matrix4.rotationZ(
                //                                             1.5708),
                //                                     alignment: Alignment.center,
                //                                     child: Icon(
                //                                       Icons
                //                                           .subdirectory_arrow_right,
                //                                       size: 20,
                //                                     )),
                //
                //                                 SizedBox(width: 8),
                //                                 Text(field['target'],
                //                                     style: CustomTypography(
                //                                             context)
                //                                         .Subtitle1),
                //                               ],
                //                             ),
                //                             SizedBox(height: 8),
                //                             Row(
                //                               children: [
                //                                 Expanded(
                //                                   child: Container(
                //                                     decoration: BoxDecoration(
                //                                       border: Border.all(
                //                                           color: Colors.grey),
                //                                       borderRadius:
                //                                           BorderRadius.circular(
                //                                               8),
                //                                     ),
                //                                     child: DropdownButton<
                //                                             String>(
                //                                         isExpanded: true,
                //                                         padding:
                //                                             EdgeInsets.symmetric(
                //                                                 horizontal: 10),
                //                                         menuMaxHeight: 300,
                //                                         borderRadius:
                //                                             BorderRadius.circular(
                //                                                 8),
                //                                         style:
                //                                             CustomTypography(context)
                //                                                 .Subtitle1,
                //                                         underline: SizedBox(),
                //                                         menuWidth: 250,
                //
                //                                         // Ensure selected value exists in dropdown items, otherwise set null
                //                                         value: provider.sovUploadModel?.result?.firstWhereOrNull((res) => res.targetField == field['target'])?.matches?.any((match) => match.name == field['spreadsheet']) ??
                //                                                 false
                //                                             ? field[
                //                                                 'spreadsheet']
                //                                             : null,
                //                                         hint: Text(
                //                                           "Select mapping",
                //                                           style:
                //                                               CustomTypography(
                //                                                       context)
                //                                                   .Subtitle1,
                //                                         ),
                //                                         items:
                //                                             provider.sovUploadModel
                //                                                     ?.result
                //                                                     ?.firstWhereOrNull(
                //                                                         (res) =>
                //                                                             res.targetField == field['target'])
                //                                                     ?.matches
                //                                                     ?.map((match) {
                //                                                   return DropdownMenuItem<
                //                                                       String>(
                //                                                     value: match
                //                                                         .name,
                //                                                     child: Row(
                //                                                       children: [
                //                                                         Text(
                //                                                           match.name ??
                //                                                               "Unknown",
                //                                                           style:
                //                                                               CustomTypography(context).Subtitle2,
                //                                                         ),
                //                                                         Spacer(),
                //                                                         Text(
                //                                                           '${match.percentage ?? 0}% Match',
                //                                                           style:
                //                                                               CustomTypography(context).Caption,
                //                                                         ),
                //                                                       ],
                //                                                     ),
                //                                                   );
                //                                                 }).toList() ??
                //                                                 [],
                //                                         // Prevent null list
                //                                         selectedItemBuilder: (context) {
                //                                           return provider
                //                                                   .sovUploadModel
                //                                                   ?.result
                //                                                   ?.firstWhereOrNull((res) =>
                //                                                       res.targetField ==
                //                                                       field[
                //                                                           'target'])
                //                                                   ?.matches
                //                                                   ?.map(
                //                                                       (match) {
                //                                                 return Align(
                //                                                   alignment:
                //                                                       Alignment
                //                                                           .centerLeft,
                //                                                   child: Text(
                //                                                     match.name ??
                //                                                         "Unknown",
                //                                                     style: CustomTypography(
                //                                                             context)
                //                                                         .Subtitle1,
                //                                                   ),
                //                                                 );
                //                                               }).toList() ??
                //                                               [];
                //                                         },
                //                                         onChanged: (newValue) {
                //                                           final match = provider
                //                                               .sovUploadModel
                //                                               ?.result
                //                                               ?.firstWhereOrNull((res) =>
                //                                                   res.targetField ==
                //                                                   field[
                //                                                       'target'])
                //                                               ?.matches
                //                                               ?.firstWhereOrNull(
                //                                                   (m) =>
                //                                                       m.name ==
                //                                                       newValue);
                //
                //                                           setState(() {
                //                                             field['spreadsheet'] =
                //                                                 newValue!;
                //                                             field['id'] = match
                //                                                     ?.id ??
                //                                                 ""; // <<--- ADD THIS
                //                                             field['percentage'] =
                //                                                 match?.percentage ??
                //                                                     0;
                //                                             field['is_data_parameter'] =
                //                                                 match?.is_data_parameter ??
                //                                                     false;
                //                                             field['status'] =
                //                                                 'Manual Mapped';
                //                                             _tempfields
                //                                                 .add(field);
                //                                           });
                //                                         }),
                //                                   ),
                //                                 ),
                //                                 SizedBox(width: 10),
                //                                 TextButton(
                //                                   onPressed: field['status'] ==
                //                                           'Manual Mapped'
                //                                       ? () {
                //                                           setState(() {
                //                                             // Find the original mapping
                //                                             var originalField =
                //                                                 _initialfields
                //                                                     .firstWhereOrNull((test) =>
                //                                                         test[
                //                                                             "target"] ==
                //                                                         field[
                //                                                             "target"]);
                //
                //                                             if (originalField !=
                //                                                 null) {
                //                                               field["spreadsheet"] =
                //                                                   originalField[
                //                                                       "spreadsheet"];
                //                                               field["is_data_parameter"] =
                //                                                   originalField[
                //                                                           "is_data_parameter"] ??
                //                                                       false;
                //
                //                                               if (originalField[
                //                                                       'status'] ==
                //                                                   'Auto Mapped') {
                //                                                 setState(() {
                //                                                   field['status'] =
                //                                                       'Auto Mapped';
                //                                                 });
                //                                                 _automappedfields
                //                                                     .add(field);
                //                                               } else {
                //                                                 setState(() {
                //                                                   field['status'] =
                //                                                       'Unmapped';
                //                                                 });
                //                                                 _unmappedfields
                //                                                     .add(field);
                //                                               }
                //                                             } else {
                //                                               field["spreadsheet"] =
                //                                                   '';
                //                                             }
                //
                //                                             // Update field lists accordingly
                //                                             _tempfields.removeWhere(
                //                                                 (test) =>
                //                                                     test[
                //                                                         "spreadsheet"] ==
                //                                                     field[
                //                                                         "spreadsheet"]);
                //
                //                                             _manualappedfields
                //                                                 .removeWhere((test) =>
                //                                                     test[
                //                                                         "spreadsheet"] ==
                //                                                     field[
                //                                                         "spreadsheet"]);
                //
                //                                             _pendingReverts[field[
                //                                                     'target']] =
                //                                                 true; // Mark field for revert
                //                                           });
                //                                         }
                //                                       : null,
                //                                   child: Row(
                //                                     children: [
                //                                       Text(
                //                                         'Revert',
                //                                         style: TextStyle(
                //                                           color: field[
                //                                                       'status'] ==
                //                                                   'Manual Mapped'
                //                                               ? AppColors
                //                                                   .primaryMain
                //                                               : Colors.grey,
                //                                         ),
                //                                       ),
                //                                     ],
                //                                   ),
                //                                 ),
                //                               ],
                //                             ),
                //                             SizedBox(height: 8),
                //                           ],
                //                         ),
                //                       ),
                //                     ),
                //                     Align(
                //                       alignment: Alignment.topRight,
                //                       child: Padding(
                //                         padding: const EdgeInsets.only(
                //                             top: 4.0, right: 4.0),
                //                         child:
                //                             _buildStatusChip(field['status']),
                //                       ),
                //                     ),
                //                   ],
                //                 );
                //               }).toList(),
                //             ),
                //           ),
                //         );
                //       })
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
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                          child:
                                                              DropdownButton2<
                                                                  String>(
                                                            isExpanded: true,

                                                            dropdownStyleData:
                                                                DropdownStyleData(
                                                              maxHeight: 300,
                                                              width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.9 -
                                                                  75,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surface,
                                                              ),
                                                              offset:
                                                                  const Offset(
                                                                      0, -2),
                                                            ),

                                                            buttonStyleData:
                                                                const ButtonStyleData(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10),
                                                            ),

                                                            style:
                                                                CustomTypography(
                                                                        context)
                                                                    .Subtitle1,

                                                            hint: Text(
                                                              "Select mapping",
                                                              style: CustomTypography(
                                                                      context)
                                                                  .Subtitle1,
                                                            ),

                                                            // ============================
                                                            //   SELECTED VALUE CHECK
                                                            // ============================
                                                            value: provider
                                                                        .sovUploadModel
                                                                        ?.result
                                                                        ?.firstWhereOrNull(
                                                                          (res) =>
                                                                              res.targetField ==
                                                                              field['target'],
                                                                        )
                                                                        ?.matches
                                                                        ?.any((match) =>
                                                                            match.name ==
                                                                            field[
                                                                                'spreadsheet']) ??
                                                                    false
                                                                ? field[
                                                                    'spreadsheet']
                                                                : null,

                                                            // ============================
                                                            //        DROPDOWN ITEMS
                                                            // ============================
                                                            items: provider
                                                                    .sovUploadModel
                                                                    ?.result
                                                                    ?.firstWhereOrNull(
                                                                      (res) =>
                                                                          res.targetField ==
                                                                          field[
                                                                              'target'],
                                                                    )
                                                                    ?.matches
                                                                    ?.map(
                                                                      (match) =>
                                                                          DropdownMenuItem<
                                                                              String>(
                                                                        value: match
                                                                            .name,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              match.name ?? "Unknown",
                                                                              style: CustomTypography(context).Subtitle2,
                                                                            ),
                                                                            const Spacer(),
                                                                            Text(
                                                                              '${match.percentage ?? 0}% Match',
                                                                              style: CustomTypography(context).Caption,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList() ??
                                                                [],

                                                            // ============================
                                                            //   SELECTED ITEM BUILDER
                                                            // ============================
                                                            selectedItemBuilder:
                                                                (context) {
                                                              return provider
                                                                      .sovUploadModel
                                                                      ?.result
                                                                      ?.firstWhereOrNull(
                                                                        (res) =>
                                                                            res.targetField ==
                                                                            field['target'],
                                                                      )
                                                                      ?.matches
                                                                      ?.map(
                                                                        (match) =>
                                                                            Align(
                                                                          alignment:
                                                                              Alignment.centerLeft,
                                                                          child:
                                                                              Text(
                                                                            match.name ??
                                                                                "Unknown",
                                                                            style:
                                                                                CustomTypography(context).Subtitle1,
                                                                          ),
                                                                        ),
                                                                      )
                                                                      .toList() ??
                                                                  [];
                                                            },
                                                            onChanged:
                                                                (newValue) {
                                                              final match = provider
                                                                  .sovUploadModel
                                                                  ?.result
                                                                  ?.firstWhereOrNull(
                                                                    (res) =>
                                                                        res.targetField ==
                                                                        field[
                                                                            'target'],
                                                                  )
                                                                  ?.matches
                                                                  ?.firstWhereOrNull((m) =>
                                                                      m.name ==
                                                                      newValue);

                                                              setState(() {
                                                                field['spreadsheet'] =
                                                                    newValue!;
                                                                field['status'] =
                                                                    'Manual Mapped';
                                                                field['is_data_parameter'] =
                                                                    match?.is_data_parameter ??
                                                                        false;
                                                                _tempfields
                                                                    .add(field);
                                                              });

                                                              print(
                                                                  "Selected: $newValue");
                                                              print(
                                                                  "is_data_parameter: ${match?.is_data_parameter}");
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Expanded(
                                                    //   child: Container(
                                                    //     decoration:
                                                    //         BoxDecoration(
                                                    //       border: Border.all(
                                                    //           color:
                                                    //               Colors.grey),
                                                    //       borderRadius:
                                                    //           BorderRadius
                                                    //               .circular(8),
                                                    //     ),
                                                    //     child: DropdownButton<
                                                    //         String>(
                                                    //       isExpanded: true,
                                                    //       padding: EdgeInsets
                                                    //           .symmetric(
                                                    //               horizontal:
                                                    //                   10),
                                                    //       menuMaxHeight: 300,
                                                    //       borderRadius:
                                                    //           BorderRadius
                                                    //               .circular(8),
                                                    //       style:
                                                    //           CustomTypography(
                                                    //                   context)
                                                    //               .Subtitle1,
                                                    //       underline: SizedBox(),
                                                    //       menuWidth: 250,
                                                    //       value: provider
                                                    //                   .sovUploadModel
                                                    //                   ?.result
                                                    //                   ?.firstWhereOrNull((res) =>
                                                    //                       res.targetField ==
                                                    //                       field[
                                                    //                           'target'])
                                                    //                   ?.matches
                                                    //                   ?.any((match) =>
                                                    //                       match
                                                    //                           .name ==
                                                    //                       field[
                                                    //                           'spreadsheet']) ??
                                                    //               false
                                                    //           ? field[
                                                    //               'spreadsheet']
                                                    //           : null,
                                                    //       // Ensure value exists in dropdown
                                                    //
                                                    //       hint: Text(
                                                    //         "Select mapping",
                                                    //         style:
                                                    //             CustomTypography(
                                                    //                     context)
                                                    //                 .Subtitle1,
                                                    //       ),
                                                    //
                                                    //       items: provider
                                                    //               .sovUploadModel
                                                    //               ?.result
                                                    //               ?.firstWhereOrNull((res) =>
                                                    //                   res.targetField ==
                                                    //                   field[
                                                    //                       'target'])
                                                    //               ?.matches
                                                    //               ?.map(
                                                    //                   (match) {
                                                    //             return DropdownMenuItem<
                                                    //                 String>(
                                                    //               value: match
                                                    //                   .name,
                                                    //               child: Row(
                                                    //                 children: [
                                                    //                   Text(
                                                    //                     match.name ??
                                                    //                         "Unknown",
                                                    //                     style: CustomTypography(context)
                                                    //                         .Subtitle2,
                                                    //                   ),
                                                    //                   Spacer(),
                                                    //                   Text(
                                                    //                     '${match.percentage ?? 0}% Match',
                                                    //                     style: CustomTypography(context)
                                                    //                         .Caption,
                                                    //                   ),
                                                    //                 ],
                                                    //               ),
                                                    //             );
                                                    //           }).toList() ??
                                                    //           [],
                                                    //       // Prevent null list
                                                    //
                                                    //       selectedItemBuilder:
                                                    //           (context) {
                                                    //         return provider
                                                    //                 .sovUploadModel
                                                    //                 ?.result
                                                    //                 ?.firstWhereOrNull((res) =>
                                                    //                     res.targetField ==
                                                    //                     field[
                                                    //                         'target'])
                                                    //                 ?.matches
                                                    //                 ?.map(
                                                    //                     (match) {
                                                    //               return Align(
                                                    //                 alignment:
                                                    //                     Alignment
                                                    //                         .centerLeft,
                                                    //                 child: Text(
                                                    //                   match.name ??
                                                    //                       "Unknown",
                                                    //                   style: CustomTypography(
                                                    //                           context)
                                                    //                       .Subtitle1,
                                                    //                 ),
                                                    //               );
                                                    //             }).toList() ??
                                                    //             [];
                                                    //       },
                                                    //
                                                    //       onChanged:
                                                    //           (newValue) {
                                                    //             final match = provider.sovUploadModel?.result
                                                    //                 ?.firstWhereOrNull((res) => res.targetField == field['target'])
                                                    //                 ?.matches
                                                    //                 ?.firstWhereOrNull((m) => m.name == newValue);
                                                    //         setState(() {
                                                    //           field['spreadsheet'] =
                                                    //               newValue!;
                                                    //           field['status'] =
                                                    //               'Manual Mapped';
                                                    //           field['is_data_parameter'] = match?.is_data_parameter ?? false;
                                                    //           _tempfields
                                                    //               .add(field);
                                                    //         });
                                                    //       },
                                                    //     ),
                                                    //   ),
                                                    // ),
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
                                                                  field["is_data_parameter"] =
                                                                      originalField[
                                                                              "is_data_parameter"] ??
                                                                          false;
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
                                      children: _manualappedfields
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
                                                                DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownButton2<
                                                                      String>(
                                                                isExpanded:
                                                                    true,

                                                                // ============================
                                                                //      DROPDOWN STYLING
                                                                // ============================
                                                                dropdownStyleData:
                                                                    DropdownStyleData(
                                                                  maxHeight:
                                                                      300,
                                                                  width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.9 -
                                                                      75,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .surface,
                                                                  ),
                                                                  offset:
                                                                      const Offset(
                                                                          0,
                                                                          -2),
                                                                ),

                                                                buttonStyleData:
                                                                    const ButtonStyleData(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10),
                                                                ),

                                                                style: CustomTypography(
                                                                        context)
                                                                    .Subtitle1,

                                                                hint: Text(
                                                                  "Select mapping",
                                                                  style: CustomTypography(
                                                                          context)
                                                                      .Subtitle1,
                                                                ),

                                                                // ============================
                                                                //  SELECTED VALUE CHECK
                                                                // ============================
                                                                value: provider
                                                                            .sovUploadModel
                                                                            ?.result
                                                                            ?.firstWhereOrNull(
                                                                              (res) => res.targetField == field['target'],
                                                                            )
                                                                            ?.matches
                                                                            ?.any((match) =>
                                                                                match.name ==
                                                                                field['spreadsheet']) ??
                                                                        false
                                                                    ? field['spreadsheet']
                                                                    : null,

                                                                // ============================
                                                                //        DROPDOWN ITEMS
                                                                // ============================
                                                                items: provider
                                                                        .sovUploadModel
                                                                        ?.result
                                                                        ?.firstWhereOrNull(
                                                                          (res) =>
                                                                              res.targetField ==
                                                                              field['target'],
                                                                        )
                                                                        ?.matches
                                                                        ?.map(
                                                                          (match) =>
                                                                              DropdownMenuItem<String>(
                                                                            value:
                                                                                match.name,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Text(
                                                                                  match.name ?? "Unknown",
                                                                                  style: CustomTypography(context).Subtitle2,
                                                                                ),
                                                                                const Spacer(),
                                                                                Text(
                                                                                  '${match.percentage ?? 0}% Match',
                                                                                  style: CustomTypography(context).Caption,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                        .toList() ??
                                                                    [],

                                                                // ============================
                                                                //    SELECTED ITEM BUILDER
                                                                // ============================
                                                                selectedItemBuilder:
                                                                    (context) {
                                                                  return provider
                                                                          .sovUploadModel
                                                                          ?.result
                                                                          ?.firstWhereOrNull(
                                                                            (res) =>
                                                                                res.targetField ==
                                                                                field['target'],
                                                                          )
                                                                          ?.matches
                                                                          ?.map(
                                                                            (match) =>
                                                                                Align(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Text(
                                                                                match.name ?? "Unknown",
                                                                                style: CustomTypography(context).Subtitle1,
                                                                              ),
                                                                            ),
                                                                          )
                                                                          .toList() ??
                                                                      [];
                                                                },

                                                                onChanged:
                                                                    (newValue) {
                                                                  final match = provider
                                                                      .sovUploadModel
                                                                      ?.result
                                                                      ?.firstWhereOrNull((res) =>
                                                                          res.targetField ==
                                                                          field[
                                                                              'target'])
                                                                      ?.matches
                                                                      ?.firstWhereOrNull((m) =>
                                                                          m.name ==
                                                                          newValue);
                                                                  setState(() {
                                                                    field['spreadsheet'] =
                                                                        newValue!;
                                                                    field['status'] =
                                                                        'Auto Mapped'; // Auto Mapped as you wrote
                                                                    field['is_data_parameter'] =
                                                                        match?.is_data_parameter ??
                                                                            false;
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
                                                        ),
                                                        SizedBox(width: 10),
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              final current = field['spreadsheet'];

                                                              // 1️⃣ REMOVE FROM usedDataParameters FIRST (VERY IMPORTANT)
                                                              if (current != null &&
                                                                  current.toString().isNotEmpty &&
                                                                  field['is_data_parameter'] == true) {
                                                                _usedDataParameters.remove(current);
                                                              }

                                                              // 2️⃣ Restore original field
                                                              var original = _initialfields.firstWhereOrNull(
                                                                    (test) => test["target"] == field["target"],
                                                              );

                                                              if (original != null) {
                                                                field["spreadsheet"] = original["spreadsheet"] ?? '';
                                                                field["is_data_parameter"] = original["is_data_parameter"] ?? false;
                                                                field["percentage"] = original["percentage"] ?? 0;
                                                                field["matchPercent"] = original["percentage"] ?? 0;

                                                                // 3️⃣ If original was DP, add back ONLY original spreadsheet
                                                                if (field["is_data_parameter"] == true &&
                                                                    field["spreadsheet"].toString().isNotEmpty) {
                                                                  _usedDataParameters.add(field["spreadsheet"]);
                                                                }
                                                              } else {
                                                                // No original → fully reset
                                                                field["spreadsheet"] = '';
                                                                field["is_data_parameter"] = false;
                                                                field["percentage"] = 0;
                                                                field["matchPercent"] = 0;
                                                              }

                                                              // 4️⃣ Move the field to correct list
                                                              field['status'] = 'Unmapped';

                                                              // 5️⃣ Remove from manual mapped list
                                                              _manualappedfields.removeWhere((t) => t['target'] == field['target']);

                                                              // 6️⃣ Add to unmapped list
                                                              _unmappedfields.add(field);

                                                              // 7️⃣ Clean temp fields
                                                              _tempfields.removeWhere((t) => t['target'] == field['target']);
                                                              _pendingReverts[field['target']] = true;
                                                            });
                                                          },

                                                          // onPressed: field[
                                                          //             'status'] ==
                                                          //         'Manual Mapped'
                                                          //     ? () {
                                                          //         setState(() {
                                                          //           // Find the original mapping
                                                          //           var originalField = _initialfields.firstWhereOrNull((test) =>
                                                          //               test[
                                                          //                   "target"] ==
                                                          //               field[
                                                          //                   "target"]);
                                                          //
                                                          //           if (originalField !=
                                                          //               null) {
                                                          //             field["spreadsheet"] =
                                                          //                 originalField[
                                                          //                     "spreadsheet"];
                                                          //             field[
                                                          //                 "is_data_parameter"] = originalField[
                                                          //                     "is_data_parameter"] ??
                                                          //                 false;
                                                          //
                                                          //             if (originalField[
                                                          //                     'status'] ==
                                                          //                 'Auto Mapped') {
                                                          //               setState(
                                                          //                   () {
                                                          //                 field['status'] =
                                                          //                     'Auto Mapped';
                                                          //               });
                                                          //               _automappedfields
                                                          //                   .add(field);
                                                          //             } else {
                                                          //               setState(
                                                          //                   () {
                                                          //                 field['status'] =
                                                          //                     'Unmapped';
                                                          //               });
                                                          //               _unmappedfields
                                                          //                   .add(field);
                                                          //             }
                                                          //           } else {
                                                          //             field["spreadsheet"] =
                                                          //                 '';
                                                          //           }
                                                          //
                                                          //           // Update field lists accordingly
                                                          //           _tempfields.removeWhere((test) =>
                                                          //               test[
                                                          //                   "spreadsheet"] ==
                                                          //               field[
                                                          //                   "spreadsheet"]);
                                                          //
                                                          //           _manualappedfields.removeWhere((test) =>
                                                          //               test[
                                                          //                   "spreadsheet"] ==
                                                          //               field[
                                                          //                   "spreadsheet"]);
                                                          //
                                                          //           _pendingReverts[
                                                          //                   field['target']] =
                                                          //               true; // Mark field for revert
                                                          //         });
                                                          //       }
                                                          //     : null,
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
                            :
                Builder(builder: (context) {
                  return Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _unmappedfields
                            .where((field) =>
                        _searchQuery.isEmpty ||
                            field['target']
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .map((field) {
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
                                          Transform(
                                              transform: Matrix4.rotationZ(1.5708),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.subdirectory_arrow_right,
                                                size: 20,
                                              )),
                                          SizedBox(width: 8),
                                          Text(field['target'],
                                              style: CustomTypography(context).Subtitle1),
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
                                              child: DropdownButtonHideUnderline(
                                                child: Builder(builder: (context) {
                                                  // fetch matches
                                                  final matches = provider.sovUploadModel
                                                      ?.result
                                                      ?.firstWhereOrNull((res) =>
                                                  res.targetField ==
                                                      field['target'])
                                                      ?.matches ??
                                                      [];

                                                  // build items with disable logic
                                                  final dropdownItems = matches.map((match) {
                                                    final String valueName = match.name ?? '';
                                                    final String displayName =
                                                        valueName +
                                                            (match.is_data_parameter == true
                                                                ? ' (P)'
                                                                : '');

                                                    // disable rule:
                                                    // 1) this match is a data parameter
                                                    // 2) that valueName is already used somewhere else
                                                    // 3) this row is NOT the one currently using it
                                                    final bool disableThisOption =
                                                        match.is_data_parameter == true &&
                                                            _usedDataParameters
                                                                .contains(valueName) &&
                                                            field['spreadsheet'] != valueName;

                                                    return DropdownMenuItem<String>(
                                                      value: valueName,
                                                      enabled: !disableThisOption,
                                                      child: Opacity(
                                                        opacity: disableThisOption ? 0.4 : 1.0,
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                displayName.isNotEmpty
                                                                    ? displayName
                                                                    : "Unknown",
                                                                style: CustomTypography(context)
                                                                    .Subtitle2,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${match.percentage ?? 0}% Match',
                                                              style: CustomTypography(context)
                                                                  .Caption,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList();

                                                  return DropdownButton2<String>(
                                                    isExpanded: true,
                                                    dropdownStyleData: DropdownStyleData(
                                                      maxHeight: 300,
                                                      width:
                                                      MediaQuery.of(context).size.width *
                                                          0.9 -
                                                          75,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        color:
                                                        Theme.of(context).colorScheme.surface,
                                                      ),
                                                      offset: const Offset(0, -2),
                                                    ),
                                                    buttonStyleData: const ButtonStyleData(
                                                      padding:
                                                      EdgeInsets.symmetric(horizontal: 10),
                                                    ),
                                                    style: CustomTypography(context).Subtitle1,
                                                    hint: Text(
                                                      "Ignore",
                                                      style:
                                                      CustomTypography(context).Subtitle1,
                                                    ),
                                                    value: (field['spreadsheet']?.toString().isNotEmpty ??
                                                        false)
                                                        ? field['spreadsheet']
                                                        : null,
                                                    items: dropdownItems,
                                                    selectedItemBuilder: (context) {
                                                      return matches.map((match) {
                                                        final display = (match.name ?? '') +
                                                            (match.is_data_parameter == true
                                                                ? ' (P)'
                                                                : '');
                                                        return Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: Text(
                                                            display.isNotEmpty
                                                                ? display
                                                                : "Unknown",
                                                            style: CustomTypography(context)
                                                                .Subtitle1,
                                                          ),
                                                        );
                                                      }).toList();
                                                    },
                                                    onChanged: (newValue) {
                                                      if (newValue == null) return;

                                                      // newValue is valueName (match.name)
                                                      final match = matches.firstWhereOrNull(
                                                              (m) => m.name == newValue);

                                                      setState(() {
                                                        // remove previous parameter if it was a data parameter
                                                        final prev = field['spreadsheet'];
                                                        if (prev != null &&
                                                            prev.toString().isNotEmpty &&
                                                            field['is_data_parameter'] == true) {
                                                          _usedDataParameters.remove(prev);
                                                        }

                                                        // assign new values (use valueName as stored value)
                                                        field['spreadsheet'] = newValue;
                                                        field['status'] = 'Manual Mapped';
                                                        field['id'] = match?.id;
                                                        field['percentage'] = match?.percentage ?? 0;
                                                        field['matchPercent'] = match?.percentage ?? 0;
                                                        field['is_data_parameter'] =
                                                            match?.is_data_parameter ?? false;

                                                        // if new one is data parameter, add to used set (use valueName)
                                                        if (match?.is_data_parameter == true) {
                                                          _usedDataParameters.add(newValue);
                                                        }

                                                        // Save in temp fields (replace previous)
                                                        _tempfields.removeWhere(
                                                                (t) => t['target'] == field['target']);
                                                        _tempfields.add(Map<String, dynamic>.from(field));
                                                      });
                                                    },
                                                  );
                                                }),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),

                                          /// REVERT BUTTON
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                final current = field['spreadsheet'];

                                                // 1️⃣ REMOVE FROM usedDataParameters FIRST (VERY IMPORTANT)
                                                if (current != null &&
                                                    current.toString().isNotEmpty &&
                                                    field['is_data_parameter'] == true) {
                                                  _usedDataParameters.remove(current);
                                                }

                                                // 2️⃣ Restore original field
                                                var original = _initialfields.firstWhereOrNull(
                                                      (test) => test["target"] == field["target"],
                                                );

                                                if (original != null) {
                                                  field["spreadsheet"] = original["spreadsheet"] ?? '';
                                                  field["is_data_parameter"] = original["is_data_parameter"] ?? false;
                                                  field["percentage"] = original["percentage"] ?? 0;
                                                  field["matchPercent"] = original["percentage"] ?? 0;

                                                  // 3️⃣ If original was DP, add back ONLY original spreadsheet
                                                  if (field["is_data_parameter"] == true &&
                                                      field["spreadsheet"].toString().isNotEmpty) {
                                                    _usedDataParameters.add(field["spreadsheet"]);
                                                  }
                                                } else {
                                                  // No original → fully reset
                                                  field["spreadsheet"] = '';
                                                  field["is_data_parameter"] = false;
                                                  field["percentage"] = 0;
                                                  field["matchPercent"] = 0;
                                                }

                                                // 4️⃣ Move the field to correct list
                                                field['status'] = 'Unmapped';

                                                // 5️⃣ Remove from manual mapped list
                                                _manualappedfields.removeWhere((t) => t['target'] == field['target']);

                                                // 6️⃣ Add to unmapped list
                                                _unmappedfields.add(field);

                                                // 7️⃣ Clean temp fields
                                                _tempfields.removeWhere((t) => t['target'] == field['target']);
                                                _pendingReverts[field['target']] = true;
                                              });
                                            },

                                            // onPressed: field['status'] == 'Manual Mapped'
                                            //     ? () {
                                            //   setState(() {
                                            //     final current = field['spreadsheet'];
                                            //
                                            //     // 1) Remove old data parameter from unique list
                                            //     if (current != null &&
                                            //         current.toString().isNotEmpty &&
                                            //         field['is_data_parameter'] == true) {
                                            //       _usedDataParameters.remove(current);
                                            //     }
                                            //
                                            //     // 2) Get original field
                                            //     var original = _initialfields.firstWhereOrNull(
                                            //             (test) => test["target"] == field["target"]);
                                            //
                                            //     if (original != null) {
                                            //       // Restore original spreadsheet mapping
                                            //       field["spreadsheet"] =
                                            //           original["spreadsheet"] ?? '';
                                            //
                                            //       // Restore data parameter flag
                                            //       field["is_data_parameter"] =
                                            //           original["is_data_parameter"] ?? false;
                                            //
                                            //       // Restore percentage / matchPercent
                                            //       field["percentage"] = original["percentage"] ?? 0;
                                            //       field["matchPercent"] = original["percentage"] ?? 0;
                                            //
                                            //       // If original field was a data parameter — re-add it by valueName
                                            //       if (field["is_data_parameter"] == true &&
                                            //           field["spreadsheet"].toString().isNotEmpty) {
                                            //         _usedDataParameters.add(field["spreadsheet"]);
                                            //       }
                                            //     } else {
                                            //       // No original mapping — fully reset
                                            //       field["spreadsheet"] = '';
                                            //       field["is_data_parameter"] = false;
                                            //       field["percentage"] = 0;
                                            //       field["matchPercent"] = 0;
                                            //     }
                                            //
                                            //     // Restore status
                                            //     field['status'] = 'Unmapped';
                                            //
                                            //     // Update temp fields
                                            //     _tempfields.removeWhere((t) => t['target'] == field['target']);
                                            //     _pendingReverts[field['target']] = true;
                                            //   });
                                            // }
                                            //     : null,
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Revert',
                                                  style: TextStyle(
                                                    color: field['status'] == 'Manual Mapped'
                                                        ? AppColors.primaryMain
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
                                  padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                                  child: _buildStatusChip(field['status']),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),

                // Builder(builder: (context) {
                //                 return Expanded(
                //                   child: SingleChildScrollView(
                //                     child: Column(
                //                       children: _unmappedfields
                //                           .where((field) =>
                //                               _searchQuery.isEmpty ||
                //                               field['target']
                //                                   .toLowerCase()
                //                                   .contains(_searchQuery
                //                                       .toLowerCase()))
                //                           .map((field) {
                //                         return Stack(
                //                           clipBehavior: Clip.hardEdge,
                //                           children: [
                //                             Card(
                //                               color: Theme.of(context)
                //                                   .colorScheme
                //                                   .surfaceContainerHigh,
                //                               child: Padding(
                //                                 padding:
                //                                     const EdgeInsets.all(8.0),
                //                                 child: Column(
                //                                   crossAxisAlignment:
                //                                       CrossAxisAlignment.start,
                //                                   children: [
                //                                     Row(
                //                                       mainAxisAlignment:
                //                                           MainAxisAlignment
                //                                               .start,
                //                                       children: [
                //                                         Transform(
                //                                             transform: Matrix4
                //                                                 .rotationZ(
                //                                                     1.5708),
                //                                             alignment: Alignment
                //                                                 .center,
                //                                             child: Icon(
                //                                               Icons
                //                                                   .subdirectory_arrow_right,
                //                                               size: 20,
                //                                             )),
                //                                         SizedBox(width: 8),
                //                                         Text(field['target'],
                //                                             style:
                //                                                 CustomTypography(
                //                                                         context)
                //                                                     .Subtitle1),
                //                                       ],
                //                                     ),
                //                                     SizedBox(height: 8),
                //                                     Row(
                //                                       children: [
                //                                         Expanded(
                //                                           child: Container(
                //                                             decoration:
                //                                                 BoxDecoration(
                //                                               border: Border.all(
                //                                                   color: Colors
                //                                                       .grey),
                //                                               borderRadius:
                //                                                   BorderRadius
                //                                                       .circular(
                //                                                           8),
                //                                             ),
                //                                             child:
                //                                                 DropdownButtonHideUnderline(
                //                                               child: Builder(
                //                                                   builder:
                //                                                       (context) {
                //                                                 // fetch matches
                //                                                 final matches = provider
                //                                                         .sovUploadModel
                //                                                         ?.result
                //                                                         ?.firstWhereOrNull((res) =>
                //                                                             res.targetField ==
                //                                                             field['target'])
                //                                                         ?.matches ??
                //                                                     [];
                //
                //                                                 // build items with disable logic
                //                                                 final dropdownItems =
                //                                                     matches.map(
                //                                                         (match) {
                //                                                   final matchName =
                //                                                       '${match.name}// ?? "Unknown"}${match.is_data_parameter == true ? " (P)" : ""}';
                //                                                   // disable rule:
                //                                                   final disableThisOption = match
                //                                                               .is_data_parameter ==
                //                                                           true &&
                //                                                       _usedDataParameters
                //                                                           .contains(
                //                                                               matchName) &&
                //                                                       field['spreadsheet'] !=
                //                                                           matchName;
                //
                //                                                   return DropdownMenuItem<
                //                                                       String>(
                //                                                     value:
                //                                                         matchName,
                //                                                     enabled:
                //                                                         !disableThisOption,
                //                                                     child:
                //                                                         Opacity(
                //                                                       opacity: disableThisOption
                //                                                           ? 0.4
                //                                                           : 1.0,
                //                                                       child:
                //                                                           Row(
                //                                                         children: [
                //                                                           Text(
                //                                                             matchName,
                //                                                             style:
                //                                                                 CustomTypography(context).Subtitle2,
                //                                                           ),
                //                                                           Spacer(),
                //                                                           Text(
                //                                                             '${match.percentage ?? 0}% Match',
                //                                                             style:
                //                                                                 CustomTypography(context).Caption,
                //                                                           ),
                //                                                         ],
                //                                                       ),
                //                                                     ),
                //                                                   );
                //                                                 }).toList();
                //
                //                                                 return DropdownButton2<
                //                                                     String>(
                //                                                   isExpanded:
                //                                                       true,
                //                                                   dropdownStyleData:
                //                                                       DropdownStyleData(
                //                                                     maxHeight:
                //                                                         300,
                //                                                     width: MediaQuery.of(context).size.width *
                //                                                             0.9 -
                //                                                         75,
                //                                                     decoration:
                //                                                         BoxDecoration(
                //                                                       borderRadius:
                //                                                           BorderRadius.circular(
                //                                                               8),
                //                                                       color: Theme.of(
                //                                                               context)
                //                                                           .colorScheme
                //                                                           .surface,
                //                                                     ),
                //                                                     offset:
                //                                                         const Offset(
                //                                                             0,
                //                                                             -2),
                //                                                   ),
                //                                                   buttonStyleData:
                //                                                       const ButtonStyleData(
                //                                                     padding: EdgeInsets.symmetric(
                //                                                         horizontal:
                //                                                             10),
                //                                                   ),
                //                                                   style: CustomTypography(
                //                                                           context)
                //                                                       .Subtitle1,
                //                                                   hint: Text(
                //                                                     "Select mapping",
                //                                                     style: CustomTypography(
                //                                                             context)
                //                                                         .Subtitle1,
                //                                                   ),
                //                                                   value: (field['spreadsheet']
                //                                                               ?.isNotEmpty ??
                //                                                           false)
                //                                                       ? field[
                //                                                           'spreadsheet']
                //                                                       : null,
                //                                                   items:
                //                                                       dropdownItems,
                //                                                   selectedItemBuilder:
                //                                                       (context) {
                //                                                     return matches
                //                                                         .map((match) =>
                //                                                             Align(
                //                                                               alignment: Alignment.centerLeft,
                //                                                               child: Text(
                //                                                                 match.name ?? "Unknown",
                //                                                                 style: CustomTypography(context).Subtitle1,
                //                                                               ),
                //                                                             ))
                //                                                         .toList();
                //                                                   },
                //                                                   onChanged:
                //                                                       (newValue) {
                //                                                     if (newValue ==
                //                                                         null)
                //                                                       return;
                //
                //                                                     final match =
                //                                                         matches.firstWhereOrNull((m) =>
                //                                                             m.name ==
                //                                                             newValue);
                //                                                     setState(
                //                                                         () {
                //                                                       // remove previous parameter
                //                                                       final prev =
                //                                                           field[
                //                                                               'spreadsheet'];
                //                                                       if (prev !=
                //                                                               null &&
                //                                                           prev
                //                                                               .isNotEmpty &&
                //                                                           field['is_data_parameter'] ==
                //                                                               true) {
                //                                                         _usedDataParameters
                //                                                             .remove(prev);
                //                                                       }
                //
                //                                                       // Required UI fields
                //                                                       field['spreadsheet'] =
                //                                                           newValue;
                //                                                       field['status'] =
                //                                                           'Manual Mapped';
                //                                                       field['id'] =
                //                                                           match
                //                                                               ?.id;
                //
                //                                                       // 🔥 The correct mapping values that backend needs
                //                                                       field['percentage'] =
                //                                                           match?.percentage ??
                //                                                               0;
                //                                                       field[
                //                                                           'matchPercent'] = match
                //                                                               ?.percentage ??
                //                                                           0; // UI display
                //                                                       field[
                //                                                           'is_data_parameter'] = match
                //                                                               ?.is_data_parameter ??
                //                                                           false;
                //
                //                                                       // Handle unique data parameters
                //                                                       if (match
                //                                                               ?.is_data_parameter ==
                //                                                           true) {
                //                                                         _usedDataParameters
                //                                                             .add(newValue);
                //                                                       }
                //
                //                                                       // Save in temp fields
                //                                                       _tempfields.removeWhere((t) =>
                //                                                           t['target'] ==
                //                                                           field[
                //                                                               'target']);
                //                                                       _tempfields.add(Map<
                //                                                           String,
                //                                                           dynamic>.from(field));
                //                                                     });
                //
                //                                                     // setState(
                //                                                     //     () {
                //                                                     //   // remove previous parameter
                //                                                     //   final prev =
                //                                                     //       field[
                //                                                     //           'spreadsheet'];
                //                                                     //   if (prev !=
                //                                                     //           null &&
                //                                                     //       prev
                //                                                     //           .isNotEmpty &&
                //                                                     //       field['is_data_parameter'] ==
                //                                                     //           true) {
                //                                                     //     _usedDataParameters
                //                                                     //         .remove(prev);
                //                                                     //   }
                //                                                     //
                //                                                     //   field['spreadsheet'] =
                //                                                     //       newValue;
                //                                                     //   field['status'] =
                //                                                     //       'Manual Mapped';
                //                                                     //   field['id'] =
                //                                                     //       match
                //                                                     //           ?.id;
                //                                                     //   field['matchPercent'] =
                //                                                     //       match?.percentage ??
                //                                                     //           0;
                //                                                     //   field[
                //                                                     //       'is_data_parameter'] = match
                //                                                     //           ?.is_data_parameter ??
                //                                                     //       false;
                //                                                     //
                //                                                     //   if (match
                //                                                     //           ?.is_data_parameter ==
                //                                                     //       true) {
                //                                                     //     _usedDataParameters
                //                                                     //         .add(newValue);
                //                                                     //   }
                //                                                     //
                //                                                     //   _tempfields.removeWhere((t) =>
                //                                                     //       t['target'] ==
                //                                                     //       field[
                //                                                     //           'target']);
                //                                                     //   _tempfields.add(Map<
                //                                                     //       String,
                //                                                     //       dynamic>.from(field));
                //                                                     // });
                //                                                   },
                //                                                 );
                //                                               }),
                //                                             ),
                //                                           ),
                //                                         ),
                //                                         SizedBox(width: 10),
                //
                //                                         /// REVERT BUTTON FIXED
                //                                         TextButton(
                //                                           onPressed: field[
                //                                                       'status'] ==
                //                                                   'Manual Mapped'
                //                                               ? () {
                //                                                   setState(() {
                //                                                     final current =
                //                                                         field[
                //                                                             'spreadsheet'];
                //
                //                                                     // 1️⃣ Remove old data parameter from unique list
                //                                                     if (current !=
                //                                                             null &&
                //                                                         current
                //                                                             .isNotEmpty &&
                //                                                         field['is_data_parameter'] ==
                //                                                             true) {
                //                                                       _usedDataParameters
                //                                                           .remove(
                //                                                               current);
                //                                                     }
                //
                //                                                     // 2️⃣ Get original field
                //                                                     var original = _initialfields.firstWhereOrNull((test) =>
                //                                                         test[
                //                                                             "target"] ==
                //                                                         field[
                //                                                             "target"]);
                //
                //                                                     if (original !=
                //                                                         null) {
                //                                                       // Restore original spreadsheet mapping
                //                                                       field["spreadsheet"] =
                //                                                           original["spreadsheet"] ??
                //                                                               '';
                //
                //                                                       // Restore data parameter flag
                //                                                       field[
                //                                                           "is_data_parameter"] = original[
                //                                                               "is_data_parameter"] ??
                //                                                           false;
                //
                //                                                       // 🔥 Restore original percentage
                //                                                       field["percentage"] =
                //                                                           original["percentage"] ??
                //                                                               0;
                //
                //                                                       // 🔥 Restore UI matchPercent
                //                                                       field["matchPercent"] =
                //                                                           original["percentage"] ??
                //                                                               0;
                //
                //                                                       // If original field was a data parameter — re-add it
                //                                                       if (field["is_data_parameter"] ==
                //                                                               true &&
                //                                                           field["spreadsheet"]
                //                                                               .toString()
                //                                                               .isNotEmpty) {
                //                                                         _usedDataParameters
                //                                                             .add(field["spreadsheet"]);
                //                                                       }
                //                                                     } else {
                //                                                       // No original mapping — fully reset
                //                                                       field["spreadsheet"] =
                //                                                           '';
                //                                                       field["is_data_parameter"] =
                //                                                           false;
                //                                                       field["percentage"] =
                //                                                           0; // FIX
                //                                                       field["matchPercent"] =
                //                                                           0; // FIX
                //                                                     }
                //
                //                                                     // Restore status
                //                                                     field['status'] =
                //                                                         'Unmapped';
                //
                //                                                     // Update temp fields
                //                                                     _tempfields.removeWhere((t) =>
                //                                                         t['target'] ==
                //                                                         field[
                //                                                             'target']);
                //                                                     _pendingReverts[
                //                                                             field['target']] =
                //                                                         true;
                //                                                   });
                //                                                 }
                //                                               : null,
                //
                //                                           // onPressed: field[
                //                                           //             'status'] ==
                //                                           //         'Manual Mapped'
                //                                           //     ? () {
                //                                           //         setState(() {
                //                                           //           final current =
                //                                           //               field[
                //                                           //                   'spreadsheet'];
                //                                           //
                //                                           //           if (current !=
                //                                           //                   null &&
                //                                           //               current
                //                                           //                   .isNotEmpty &&
                //                                           //               field['is_data_parameter'] ==
                //                                           //                   true) {
                //                                           //             _usedDataParameters
                //                                           //                 .remove(
                //                                           //                     current);
                //                                           //           }
                //                                           //
                //                                           //           var original = _initialfields.firstWhereOrNull((test) =>
                //                                           //               test[
                //                                           //                   "target"] ==
                //                                           //               field[
                //                                           //                   "target"]);
                //                                           //
                //                                           //           if (original !=
                //                                           //               null) {
                //                                           //             field["spreadsheet"] =
                //                                           //                 original[
                //                                           //                     "spreadsheet"];
                //                                           //             field[
                //                                           //                 "is_data_parameter"] = original[
                //                                           //                     "is_data_parameter"] ??
                //                                           //                 false;
                //                                           //
                //                                           //             if (field[
                //                                           //                     "is_data_parameter"] ==
                //                                           //                 true) {
                //                                           //               _usedDataParameters
                //                                           //                   .add(field["spreadsheet"]);
                //                                           //             }
                //                                           //           } else {
                //                                           //             field["spreadsheet"] =
                //                                           //                 '';
                //                                           //             field["is_data_parameter"] =
                //                                           //                 false;
                //                                           //           }
                //                                           //
                //                                           //           field['status'] =
                //                                           //               'Unmapped';
                //                                           //
                //                                           //           _tempfields.removeWhere((t) =>
                //                                           //               t['target'] ==
                //                                           //               field[
                //                                           //                   'target']);
                //                                           //           _pendingReverts[
                //                                           //                   field['target']] =
                //                                           //               true;
                //                                           //         });
                //                                           //       }
                //                                           //     : null,
                //                                           child: Row(
                //                                             children: [
                //                                               Text(
                //                                                 'Revert',
                //                                                 style:
                //                                                     TextStyle(
                //                                                   color: field[
                //                                                               'status'] ==
                //                                                           'Manual Mapped'
                //                                                       ? AppColors
                //                                                           .primaryMain
                //                                                       : Colors
                //                                                           .grey,
                //                                                 ),
                //                                               ),
                //                                             ],
                //                                           ),
                //                                         ),
                //                                       ],
                //                                     ),
                //                                     SizedBox(height: 8),
                //                                   ],
                //                                 ),
                //                               ),
                //                             ),
                //                             Align(
                //                               alignment: Alignment.topRight,
                //                               child: Padding(
                //                                 padding: const EdgeInsets.only(
                //                                     top: 4.0, right: 4.0),
                //                                 child: _buildStatusChip(
                //                                     field['status']),
                //                               ),
                //                             ),
                //                           ],
                //                         );
                //                       }).toList(),
                //                     ),
                //                   ),
                //                 );
                //               }),

                // Builder(builder: (context) {
                //                 return Expanded(
                //                   child: SingleChildScrollView(
                //                     child: Column(
                //                       children: _unmappedfields
                //                           .where((field) =>
                //                               _searchQuery.isEmpty ||
                //                               field['target']
                //                                   .toLowerCase()
                //                                   .contains(_searchQuery
                //                                       .toLowerCase()))
                //                           .map((field) {
                //                         return Stack(
                //                           clipBehavior: Clip.hardEdge,
                //                           children: [
                //                             Card(
                //                               color: Theme.of(context)
                //                                   .colorScheme
                //                                   .surfaceContainerHigh,
                //                               child: Padding(
                //                                 padding:
                //                                     const EdgeInsets.all(8.0),
                //                                 child: Column(
                //                                   crossAxisAlignment:
                //                                       CrossAxisAlignment.start,
                //                                   children: [
                //                                     Row(
                //                                       mainAxisAlignment:
                //                                           MainAxisAlignment
                //                                               .start,
                //                                       children: [
                //                                         // rotate 90 to right
                //                                         Transform(
                //                                             transform: Matrix4
                //                                                 .rotationZ(
                //                                                     1.5708),
                //                                             alignment: Alignment
                //                                                 .center,
                //                                             child: Icon(
                //                                               Icons
                //                                                   .subdirectory_arrow_right,
                //                                               size: 20,
                //                                             )),
                //
                //                                         SizedBox(width: 8),
                //                                         Text(field['target'],
                //                                             style:
                //                                                 CustomTypography(
                //                                                         context)
                //                                                     .Subtitle1),
                //                                       ],
                //                                     ),
                //                                     SizedBox(height: 8),
                //                                     Row(
                //                                       children: [
                //                                         Expanded(
                //                                           child: Container(
                //                                             decoration:
                //                                                 BoxDecoration(
                //                                               border: Border.all(
                //                                                   color: Colors
                //                                                       .grey),
                //                                               borderRadius:
                //                                                   BorderRadius
                //                                                       .circular(
                //                                                           8),
                //                                             ),
                //                                             child:
                //                                                 DropdownButtonHideUnderline(
                //                                               child:
                //                                               DropdownButton2<
                //                                                       String>(
                //                                                   isExpanded:
                //                                                       true,
                //                                                   dropdownStyleData:
                //                                                       DropdownStyleData(
                //                                                     maxHeight:
                //                                                         300,
                //                                                     width: MediaQuery.of(context).size.width *
                //                                                             0.9 -
                //                                                         75,
                //                                                     // SAME AS ABOVE
                //                                                     decoration:
                //                                                         BoxDecoration(
                //                                                       borderRadius:
                //                                                           BorderRadius.circular(
                //                                                               8),
                //                                                       color: Theme.of(
                //                                                               context)
                //                                                           .colorScheme
                //                                                           .surface,
                //                                                     ),
                //                                                     offset:
                //                                                         const Offset(
                //                                                             0,
                //                                                             -2),
                //                                                   ),
                //                                                   buttonStyleData:
                //                                                       const ButtonStyleData(
                //                                                     padding: EdgeInsets.symmetric(
                //                                                         horizontal:
                //                                                             10),
                //                                                   ),
                //                                                   style: CustomTypography(context)
                //                                                       .Subtitle1,
                //                                                   hint: Text(
                //                                                     "Select mapping",
                //                                                     style: CustomTypography(
                //                                                             context)
                //                                                         .Subtitle1,
                //                                                   ),
                //                                                   value: provider
                //                                                               .sovUploadModel
                //                                                               ?.result
                //                                                               ?.firstWhereOrNull(
                //                                                                 (res) => res.targetField == field['target'],
                //                                                               )
                //                                                               ?.matches
                //                                                               ?.any((match) =>
                //                                                                   match.name ==
                //                                                                   field[
                //                                                                       'spreadsheet']) ??
                //                                                           false
                //                                                       ? field[
                //                                                           'spreadsheet']
                //                                                       : null,
                //                                                   items: provider
                //                                                           .sovUploadModel
                //                                                           ?.result
                //                                                           ?.firstWhereOrNull(
                //                                                             (res) =>
                //                                                                 res.targetField ==
                //                                                                 field['target'],
                //                                                           )
                //                                                           ?.matches
                //                                                           ?.map(
                //                                                             (match) =>
                //                                                                 DropdownMenuItem<String>(
                //                                                               value: match.name,
                //                                                               child: Row(
                //                                                                 children: [
                //                                                                   Text(
                //                                                                     match.name ?? "Unknown",
                //                                                                     // '${match.name}// ?? "Unknown"}${match.is_data_parameter == true ? " (P)" : ""}',
                //                                                                     style: CustomTypography(context).Subtitle2,
                //                                                                   ),
                //                                                                   const Spacer(),
                //                                                                   Text(
                //                                                                     '${match.percentage ?? 0}% Match',
                //                                                                     style: CustomTypography(context).Caption,
                //                                                                   ),
                //                                                                 ],
                //                                                               ),
                //                                                             ),
                //                                                           )
                //                                                           .toList() ??
                //                                                       [],
                //                                                   selectedItemBuilder:
                //                                                       (context) {
                //                                                     return provider
                //                                                             .sovUploadModel
                //                                                             ?.result
                //                                                             ?.firstWhereOrNull(
                //                                                               (res) => res.targetField == field['target'],
                //                                                             )
                //                                                             ?.matches
                //                                                             ?.map(
                //                                                               (match) => Align(
                //                                                                 alignment: Alignment.centerLeft,
                //                                                                 child: Text(
                //                                                                   match.name ?? "Unknown",
                //                                                                   style: CustomTypography(context).Subtitle1,
                //                                                                 ),
                //                                                               ),
                //                                                             )
                //                                                             .toList() ??
                //                                                         [];
                //                                                   },
                //                                                   onChanged:
                //                                                       (newValue) {
                //                                                     final match = provider
                //                                                         .sovUploadModel
                //                                                         ?.result
                //                                                         ?.firstWhereOrNull((res) =>
                //                                                             res.targetField ==
                //                                                             field[
                //                                                                 'target'])
                //                                                         ?.matches
                //                                                         ?.firstWhereOrNull((m) =>
                //                                                             m.name ==
                //                                                             newValue);
                //
                //                                                     setState(
                //                                                         () {
                //                                                       field['spreadsheet'] =
                //                                                           newValue!;
                //                                                       field['status'] =
                //                                                           'Manual Mapped';
                //
                //                                                       field[
                //                                                           'id'] = match
                //                                                               ?.id ??
                //                                                           field[
                //                                                               'id'];
                //
                //                                                       field[
                //                                                           'matchPercent'] = match
                //                                                               ?.percentage ??
                //                                                           field[
                //                                                               'matchPercent'];
                //
                //                                                       // Keep other values
                //                                                       field[
                //                                                           'is_data_parameter'] = match
                //                                                               ?.is_data_parameter ??
                //                                                           false;
                //
                //                                                       _tempfields
                //                                                           .add(
                //                                                               field);
                //                                                     });
                //                                                     print(
                //                                                         "percentage");
                //                                                     print(match
                //                                                         ?.percentage);
                //                                                   }
                //
                //                                                   // onChanged:
                //                                                   //     (newValue) {
                //                                                   //   final match = provider
                //                                                   //       .sovUploadModel
                //                                                   //       ?.result
                //                                                   //       ?.firstWhereOrNull((res) =>
                //                                                   //           res.targetField ==
                //                                                   //           field[
                //                                                   //               'target'])
                //                                                   //       ?.matches
                //                                                   //       ?.firstWhereOrNull((m) =>
                //                                                   //           m.name ==
                //                                                   //           newValue);
                //                                                   //
                //                                                   //   setState(() {
                //                                                   //     field['spreadsheet'] =
                //                                                   //         newValue!;
                //                                                   //     field['status'] =
                //                                                   //         'Manual Mapped';
                //                                                   //
                //                                                   //     // 🔥 Add this line (important)
                //                                                   //     field[
                //                                                   //         'id'] = match
                //                                                   //             ?.id ??
                //                                                   //         field[
                //                                                   //             'id'];
                //                                                   //
                //                                                   //     field['is_data_parameter'] =
                //                                                   //         match?.is_data_parameter ??
                //                                                   //             false;
                //                                                   //     _tempfields
                //                                                   //         .add(
                //                                                   //             field);
                //                                                   //   });
                //                                                   //
                //                                                   //   print(
                //                                                   //       "Selected: $newValue");
                //                                                   //   print(
                //                                                   //       "Selected ID: ${field['id']}");
                //                                                   // },
                //
                //                                                   // onChanged:
                //                                                   //     (newValue) {
                //                                                   //   final match = provider
                //                                                   //       .sovUploadModel
                //                                                   //       ?.result
                //                                                   //       ?.firstWhereOrNull(
                //                                                   //         (res) =>
                //                                                   //             res.targetField ==
                //                                                   //             field['target'],
                //                                                   //       )
                //                                                   //       ?.matches
                //                                                   //       ?.firstWhereOrNull((m) =>
                //                                                   //           m.name ==
                //                                                   //           newValue);
                //                                                   //
                //                                                   //   setState(() {
                //                                                   //     field['spreadsheet'] =
                //                                                   //         newValue!;
                //                                                   //     field['status'] =
                //                                                   //         'Manual Mapped'; // ALWAYS manual mapped
                //                                                   //     field['is_data_parameter'] =
                //                                                   //         match?.is_data_parameter ??
                //                                                   //             false;
                //                                                   //     _tempfields
                //                                                   //         .add(
                //                                                   //             field);
                //                                                   //   });
                //                                                   //
                //                                                   //   print(
                //                                                   //       "Selected: $newValue");
                //                                                   //   print(
                //                                                   //       "is_data_parameter: ${match?.is_data_parameter}");
                //                                                   //   print(
                //                                                   //       "Status Updated: ${field['status']}");
                //                                                   // },
                //                                                   ),
                //                                             ),
                //                                           ),
                //                                         ),
                //                                         SizedBox(width: 10),
                //                                         TextButton(
                //                                           onPressed: field[
                //                                                       'status'] ==
                //                                                   'Manual Mapped'
                //                                               ? () {
                //                                                   setState(() {
                //                                                     field['status'] =
                //                                                         'Unmapped';
                //
                //                                                     // Find the original mapping
                //                                                     var originalField = _initialfields.firstWhereOrNull((test) =>
                //                                                         test[
                //                                                             "target"] ==
                //                                                         field[
                //                                                             "target"]);
                //
                //                                                     if (originalField !=
                //                                                         null) {
                //                                                       field["spreadsheet"] =
                //                                                           originalField[
                //                                                               "spreadsheet"];
                //                                                       field[
                //                                                           "is_data_parameter"] = originalField[
                //                                                               "is_data_parameter"] ??
                //                                                           false;
                //                                                     } else {
                //                                                       field["spreadsheet"] =
                //                                                           '';
                //                                                     }
                //
                //                                                     // Update field lists accordingly
                //                                                     _tempfields.removeWhere((test) =>
                //                                                         test[
                //                                                             "spreadsheet"] ==
                //                                                         field[
                //                                                             "spreadsheet"]);
                //                                                     _pendingReverts[
                //                                                             field['target']] =
                //                                                         true; // Mark field for revert
                //                                                   });
                //                                                 }
                //                                               : null,
                //                                           // Disable if not manually mapped
                //                                           child: Row(
                //                                             children: [
                //                                               Text(
                //                                                 'Revert',
                //                                                 style:
                //                                                     TextStyle(
                //                                                   color: field[
                //                                                               'status'] ==
                //                                                           'Manual Mapped'
                //                                                       ? AppColors
                //                                                           .primaryMain
                //                                                       : Colors
                //                                                           .grey,
                //                                                 ),
                //                                               ),
                //                                             ],
                //                                           ),
                //                                         ),
                //                                       ],
                //                                     ),
                //                                     SizedBox(height: 8),
                //                                   ],
                //                                 ),
                //                               ),
                //                             ),
                //                             Align(
                //                               alignment: Alignment.topRight,
                //                               child: Padding(
                //                                 padding: const EdgeInsets.only(
                //                                     top: 4.0, right: 4.0),
                //                                 child: _buildStatusChip(
                //                                     field['status']),
                //                               ),
                //                             ),
                //                           ],
                //                         );
                //                       }).toList(),
                //                     ),
                //                   ),
                //                 );
                //               }),
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
                          child: Text(
                            "Submit All",
                            style: CustomTypography(context)
                                .ButtonLarge
                                .copyWith(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(
                  height: 20,
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNext() {
    // Ensure correct data parameter handling
    List<Map<String, dynamic>> fieldsToSubmit = _fields.map((field) {
      final Map<String, dynamic> updatedField =
          Map<String, dynamic>.from(field);
      if (field['is_data_parameter'] != true) {
        updatedField.remove('is_data_parameter');
      } else {
        updatedField['is_data_parameter'] = true;
      }
      return updatedField;
    }).toList();

    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    if (widget.accountId.isNotEmpty && widget.accountName.isNotEmpty) {

      provider.submitSovHeadersSubAccounts(
        context,
        widget.tempId,
        provider.sovUploadModel?.url ?? "",
        fieldsToSubmit,
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
        fieldsToSubmit,
        widget.subAccountName ?? "",
      );
    }
  }
}

// import 'package:collection/collection.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:RiskSphere/design_system/primitives/app_colors.dart';
// import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
// import 'package:provider/provider.dart';
// import '../../../service/language_service.dart';
// import '../../../providers/upload_sov_provider.dart';
//
// class MappingScreen extends StatefulWidget {
//   final String tempId;
//   final String accountId;
//   final String accountName;
//   final String? subAccountName;
//   final String subAccountId;
//
//   const MappingScreen(
//       {super.key,
//       required this.tempId,
//       this.accountId = '',
//       this.accountName = '',
//       this.subAccountName,
//       this.subAccountId = ''});
//
//   @override
//   _MappingScreenState createState() => _MappingScreenState();
// }
//
// class _MappingScreenState extends State<MappingScreen> {
//   Map<String, bool> _pendingReverts = {};
//   List<Map<String, dynamic>> _fields = [];
//   List<Map<String, dynamic>> _initialfields = [];
//   List<Map<String, dynamic>> _tempfields = [];
//   List<Map<String, dynamic>> _automappedfields = [];
//   List<Map<String, dynamic>> _manualappedfields = [];
//   List<Map<String, dynamic>> _unmappedfields = [];
//
//   List<Map<String, dynamic>> _dropdownItems = [];
//   final GlobalKey _autoMappedKey = GlobalKey();
//   final GlobalKey _manualMappedKey = GlobalKey();
//   final GlobalKey _unmappedKey = GlobalKey();
//
//   String _searchQuery = '';
//   String _selectedFilter = 'All';
//   bool _hasChanges = false;
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _getData();
//   }
//
//   void _getData() async {
//     await Provider.of<UploadSovProvider>(context, listen: false)
//         .fetchSovHeaders(context, widget.tempId);
//     _initializeFields();
//   }
//
//   void _initializeFields() {
//     final provider = Provider.of<UploadSovProvider>(context, listen: false);
//     if (provider.sovUploadModel != null &&
//         provider.sovUploadModel!.result != null) {
//       _fields.clear();
//       _unmappedfields.clear();
//       _manualappedfields.clear();
//       _automappedfields.clear();
//       _fields = provider.sovUploadModel!.result!.map((result) {
//         return {
//           'id': result.matchedField?.id ?? result.id,
//           'target': result.targetField,
//           'spreadsheet': result.matchedField?.name ?? '',
//           'initialSpreadsheet': result.matchedField?.name ?? '',
//           'status': result.mappingStatus?.label ?? 'Unmapped',
//           'initialStatus': result.mappingStatus?.label ?? 'Unmapped',
//           'isChecked': result.isChecked,
//           'isUserEdited': result.isUserEdited,
//           'is_data_parameter': result.matchedField?.is_data_parameter,
//           'matchPercent': result.matchedField?.percentage ?? 0,
//         };
//       }).toList();
//       _initialfields = provider.sovUploadModel!.result!.map((result) {
//         return {
//           'id': result.matchedField?.id ?? result.id,
//           'target': result.targetField,
//           'spreadsheet': result.matchedField?.name ?? '',
//           'initialSpreadsheet': result.matchedField?.name ?? '',
//           'status': result.mappingStatus?.label ?? 'Unmapped',
//           'initialStatus': result.mappingStatus?.label ?? 'Unmapped',
//           'isChecked': result.isChecked,
//           'isUserEdited': result.isUserEdited,
//           'is_data_parameter': result.matchedField?.is_data_parameter,
//           'matchPercent': result.matchedField?.percentage ?? 0,
//         };
//       }).toList();
//
//       _automappedfields =
//           _fields.where((test) => test["status"] == 'Auto Mapped').toList();
//       _manualappedfields =
//           _fields.where((test) => test["status"] == 'Manual Mapped').toList();
//       _unmappedfields =
//           _fields.where((test) => test["status"] == 'Unmapped').toList();
//
//       Set<String> uniqueDropdownValues = {};
//
//       _dropdownItems = provider.sovUploadModel!.result!.expand((result) {
//         return result.matches!.map((match) {
//           return {
//             'value': match.name,
//             'label': match.name,
//             'matchPercent': match.percentage ?? 0,
//           };
//         }).where((item) {
//           return uniqueDropdownValues.add(item['value'] as String);
//         }).toList();
//       }).toList();
//
//       _dropdownItems.sort((a, b) =>
//           (b['matchPercent'] as int).compareTo(a['matchPercent'] as int));
//
//       setState(() {});
//     }
//   }
//
//   Widget _buildStatusChip(String status) {
//     Color color;
//     switch (status) {
//       case 'Unmapped':
//         color = Colors.red.withOpacity(0.4);
//         break;
//       case 'Manual Mapped':
//         color = Colors.orange.withOpacity(0.4);
//         break;
//       case 'Auto Mapped':
//         color = Colors.green.withOpacity(0.4);
//         break;
//       default:
//         color = Colors.grey;
//     }
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(8), topRight: Radius.circular(8)),
//       ),
//       child: Text(status,
//           style: TextStyle(
//               color: color == Colors.grey ? Colors.black : Colors.white)),
//     );
//   }
//
//   void _applyPendingReverts() {
//     setState(() {
//       for (var field in _fields) {
//         if (_pendingReverts.containsKey(field['target']) &&
//             _pendingReverts[field['target']] == true) {
//           field['spreadsheet'] =
//               field['initialSpreadsheet']; // Restore old value
//           // field['status'] = 'Unmapped'; // Change status back
//         }
//       }
//       _pendingReverts.clear(); // Clear pending revert list after applying
//     });
//   }
//
//   void scrollTo(GlobalKey key) {
//     final context = key.currentContext;
//     if (context != null) {
//       Scrollable.ensureVisible(
//         context,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         alignment: 0.5, // Center the chip if possible
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("SOV - Upload & Map",
//                 style: TextStyle(color: Colors.white, fontSize: 18)),
//             SizedBox(height: 4),
//             Text("Choose columns to map to spreadsheet fields.",
//                 style: TextStyle(color: Colors.white, fontSize: 15)),
//           ],
//         ),
//       ),
//       body: Consumer<UploadSovProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (provider.sovUploadModel == null ||
//               provider.sovUploadModel!.result == null) {
//             return Center(
//                 child: Text(LanguageService.getTranslated(
//                     context, "app_no_data_available")));
//           }
//           return Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 SizedBox(height: 5),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         onChanged: (value) {
//                           setState(() {
//                             _searchQuery = value;
//                           });
//                         },
//                         style: TextStyle(color: Colors.white), // Text color
//                         decoration: InputDecoration(
//                           hintText: LanguageService.getTranslated(
//                               context, "app_search_target_name"),
//                           hintStyle: TextStyle(color: Colors.grey[400]),
//                           // Placeholder color
//                           filled: true,
//                           fillColor: Colors.black87,
//                           // Dark background
//                           prefixIcon:
//                               Icon(Icons.search, color: Colors.grey[400]),
//                           contentPadding: EdgeInsets.symmetric(
//                               vertical: 12, horizontal: 30),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(
//                                 color: Colors.grey[600]!), // Border color
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.blue[200]!),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
//                 SingleChildScrollView(
//                   controller: _scrollController,
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       SizedBox(height: 2),
//                       FilterChip(
//                         disabledColor: Colors.blue,
//                         key: _autoMappedKey,
//                         label: Text(LanguageService.getTranslated(
//                             context, "app_auto_mapped")),
//                         selected: _selectedFilter == 'Auto Mapped',
//                         onSelected: (bool selected) {
//                           setState(() {
//                             _hasChanges = true;
//                             _selectedFilter = 'Auto Mapped';
//                             _applyPendingReverts();
//                           });
//                           scrollTo(_autoMappedKey);
//                         },
//                       ),
//                       SizedBox(width: 8),
//                       FilterChip(
//                         key: _manualMappedKey,
//                         label: Text(LanguageService.getTranslated(
//                             context, "app_manual_mapped")),
//                         selected: _selectedFilter == 'Manual Mapped',
//                         onSelected: (bool selected) {
//                           setState(() {
//                             _hasChanges = true;
//                             _selectedFilter = 'Manual Mapped';
//                             _applyPendingReverts();
//                           });
//                           scrollTo(_manualMappedKey);
//                         },
//                       ),
//                       SizedBox(width: 8),
//                       FilterChip(
//                         key: _unmappedKey,
//                         label: Text(LanguageService.getTranslated(
//                             context, "app_unmapped")),
//                         selected: _selectedFilter == 'Unmapped',
//                         onSelected: (bool selected) {
//                           setState(() {
//                             _hasChanges = true;
//                             _selectedFilter = 'Unmapped';
//                             _applyPendingReverts();
//                           });
//                           scrollTo(_unmappedKey);
//                         },
//                       ),
//                       SizedBox(width: 8),
//                       if (_hasChanges)
//                         TextButton(
//                           onPressed: () {
//                             setState(() {
//                               _selectedFilter = 'All';
//                               _hasChanges = false;
//                             });
//                           },
//                           style: TextButton.styleFrom(
//                             foregroundColor: Colors.blue,
//                             backgroundColor: Colors.black,
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 14, vertical: 6),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               side: BorderSide(color: Colors.blue),
//                             ),
//                           ),
//                           child: Text("View all parameters"),
//                         ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 _selectedFilter == 'All'
//                     ? Builder(builder: (context) {
//                         return Expanded(
//                           child: SingleChildScrollView(
//                             child: Column(
//                               children: _fields
//                                   .where((field) =>
//                                       _searchQuery.isEmpty ||
//                                       field['target']
//                                           .toLowerCase()
//                                           .contains(_searchQuery.toLowerCase()))
//                                   .map((field)
//                                       // _fields.map((field)
//
//                                       {
//                                 return Stack(
//                                   clipBehavior: Clip.hardEdge,
//                                   children: [
//                                     Card(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .surfaceContainerHigh,
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.start,
//                                               children: [
//                                                 // rotate 90 to right
//                                                 Transform(
//                                                     transform:
//                                                         Matrix4.rotationZ(
//                                                             1.5708),
//                                                     alignment: Alignment.center,
//                                                     child: Icon(
//                                                       Icons
//                                                           .subdirectory_arrow_right,
//                                                       color: Colors.white,
//                                                       size: 20,
//                                                     )),
//
//                                                 SizedBox(width: 8),
//                                                 Text(field['target'],
//                                                     style: TextStyle(
//                                                       color:
//                                                           AppColors.primaryMain,
//                                                       fontSize: 14,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     )),
//                                               ],
//                                             ),
//                                             SizedBox(height: 8),
//                                             Row(
//                                               children: [
//                                                 Expanded(
//                                                   child: Container(
//                                                     decoration: BoxDecoration(
//                                                       border: Border.all(
//                                                           color: Colors.grey),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               8),
//                                                     ),
//                                                     child:
//                                                         DropdownButtonHideUnderline(
//                                                       child: DropdownButton2<
//                                                           String>(
//                                                         isExpanded: true,
//                                                         // dropdownStyleData:
//                                                         dropdownStyleData:
//                                                             DropdownStyleData(
//                                                           maxHeight: 300,
//                                                           width: MediaQuery.of(
//                                                                           context)
//                                                                       .size
//                                                                       .width *
//                                                                   0.9 -
//                                                               75,
//                                                           decoration:
//                                                               BoxDecoration(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         8),
//                                                             color: Theme.of(
//                                                                     context)
//                                                                 .colorScheme
//                                                                 .surface,
//                                                           ),
//                                                           // Show dropdown above if there's not enough space below
//                                                           // direction: DropdownDirection.down,
//                                                           offset: const Offset(
//                                                               0, -2),
//                                                         ),
//
//                                                         buttonStyleData:
//                                                             const ButtonStyleData(
//                                                           padding: EdgeInsets
//                                                               .symmetric(
//                                                                   horizontal:
//                                                                       10),
//                                                         ),
//                                                         style: CustomTypography(
//                                                                 context)
//                                                             .Subtitle1,
//                                                         hint: Text(
//                                                           "Ignore",
//                                                           style:
//                                                               CustomTypography(
//                                                                       context)
//                                                                   .Subtitle1,
//                                                         ),
//
//                                                         // 👇 value check logic
//                                                         value: provider
//                                                                     .sovUploadModel
//                                                                     ?.result
//                                                                     ?.firstWhereOrNull(
//                                                                       (res) =>
//                                                                           res.targetField ==
//                                                                           field[
//                                                                               'target'],
//                                                                     )
//                                                                     ?.matches
//                                                                     ?.any((match) =>
//                                                                         match
//                                                                             .name ==
//                                                                         field[
//                                                                             'spreadsheet']) ??
//                                                                 false
//                                                             ? field[
//                                                                 'spreadsheet']
//                                                             : null,
//
//                                                         items: provider
//                                                                 .sovUploadModel
//                                                                 ?.result
//                                                                 ?.firstWhereOrNull(
//                                                                   (res) =>
//                                                                       res.targetField ==
//                                                                       field[
//                                                                           'target'],
//                                                                 )
//                                                                 ?.matches
//                                                                 ?.map((match) {
//                                                               return DropdownMenuItem<
//                                                                   String>(
//                                                                 value:
//                                                                     match.name,
//                                                                 child: Row(
//                                                                   children: [
//                                                                     Text(
//                                                                       match.name ??
//                                                                           "Unknown",
//                                                                       style: CustomTypography(
//                                                                               context)
//                                                                           .Subtitle2,
//                                                                     ),
//                                                                     const Spacer(),
//                                                                     Text(
//                                                                       '${match.percentage ?? 0}% Match',
//                                                                       style: CustomTypography(
//                                                                               context)
//                                                                           .Caption,
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               );
//                                                             }).toList() ??
//                                                             [],
//
//                                                         selectedItemBuilder:
//                                                             (context) {
//                                                           return provider
//                                                                   .sovUploadModel
//                                                                   ?.result
//                                                                   ?.firstWhereOrNull(
//                                                                     (res) =>
//                                                                         res.targetField ==
//                                                                         field[
//                                                                             'target'],
//                                                                   )
//                                                                   ?.matches
//                                                                   ?.map(
//                                                                       (match) {
//                                                                 return Align(
//                                                                   alignment:
//                                                                       Alignment
//                                                                           .centerLeft,
//                                                                   child: Text(
//                                                                     match.name ??
//                                                                         "Unknown",
//                                                                     style: CustomTypography(
//                                                                             context)
//                                                                         .Subtitle1,
//                                                                   ),
//                                                                 );
//                                                               }).toList() ??
//                                                               [];
//                                                         },
//
//                                                         onChanged: (newValue) {
//                                                           setState(() {
//                                                             field['spreadsheet'] =
//                                                                 newValue!;
//                                                             field['status'] =
//                                                                 'Manual Mapped';
//                                                             _tempfields
//                                                                 .add(field);
//                                                           });
//                                                           print(
//                                                               "Status: ${field['status']}");
//                                                           print(
//                                                               "Selected Value1: $newValue");
//                                                         },
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 SizedBox(width: 10),
//                                                 TextButton(
//                                                   onPressed: field['status'] ==
//                                                           'Manual Mapped'
//                                                       ? () {
//                                                           setState(() {
//                                                             // Find the original mapping
//                                                             var originalField =
//                                                                 _initialfields
//                                                                     .firstWhereOrNull((test) =>
//                                                                         test[
//                                                                             "target"] ==
//                                                                         field[
//                                                                             "target"]);
//
//                                                             if (originalField !=
//                                                                 null) {
//                                                               field["spreadsheet"] =
//                                                                   originalField[
//                                                                       "spreadsheet"];
//
//                                                               if (originalField[
//                                                                       'status'] ==
//                                                                   'Auto Mapped') {
//                                                                 setState(() {
//                                                                   field['status'] =
//                                                                       'Auto Mapped';
//                                                                 });
//                                                                 _automappedfields
//                                                                     .add(field);
//                                                               } else {
//                                                                 setState(() {
//                                                                   field['status'] =
//                                                                       'Unmapped';
//                                                                 });
//                                                                 _unmappedfields
//                                                                     .add(field);
//                                                               }
//                                                             } else {
//                                                               field["spreadsheet"] =
//                                                                   '';
//                                                             }
//
//                                                             // Update field lists accordingly
//                                                             _tempfields.removeWhere(
//                                                                 (test) =>
//                                                                     test[
//                                                                         "spreadsheet"] ==
//                                                                     field[
//                                                                         "spreadsheet"]);
//
//                                                             _manualappedfields
//                                                                 .removeWhere((test) =>
//                                                                     test[
//                                                                         "spreadsheet"] ==
//                                                                     field[
//                                                                         "spreadsheet"]);
//
//                                                             _pendingReverts[field[
//                                                                     'target']] =
//                                                                 true; // Mark field for revert
//                                                           });
//                                                         }
//                                                       : null,
//                                                   child: Row(
//                                                     children: [
//                                                       Text(
//                                                         'Revert',
//                                                         style: TextStyle(
//                                                           color: field[
//                                                                       'status'] ==
//                                                                   'Manual Mapped'
//                                                               ? AppColors
//                                                                   .primaryMain
//                                                               : Colors.grey,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             SizedBox(height: 8),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Align(
//                                       alignment: Alignment.topRight,
//                                       child: Padding(
//                                         padding: const EdgeInsets.only(
//                                             top: 4.0, right: 4.0),
//                                         child:
//                                             _buildStatusChip(field['status']),
//                                       ),
//                                     ),
//                                   ],
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                         );
//                       })
//                     : _selectedFilter == 'Auto Mapped'
//                         ? Builder(builder: (context) {
//                             return Expanded(
//                               child: SingleChildScrollView(
//                                 child: Column(
//                                   children:
//
//                                       // _automappedfields.map((field)
//
//                                       _automappedfields
//                                           .where((field) =>
//                                               _searchQuery.isEmpty ||
//                                               field['target']
//                                                   .toLowerCase()
//                                                   .contains(_searchQuery
//                                                       .toLowerCase()))
//                                           .map((field) {
//                                     return Stack(
//                                       clipBehavior: Clip.hardEdge,
//                                       children: [
//                                         Card(
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .surfaceContainerHigh,
//                                           child: Padding(
//                                             padding: const EdgeInsets.all(8.0),
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.start,
//                                                   children: [
//                                                     // rotate 90 to right
//                                                     Transform(
//                                                         transform:
//                                                             Matrix4.rotationZ(
//                                                                 1.5708),
//                                                         alignment:
//                                                             Alignment.center,
//                                                         child: Icon(
//                                                           Icons
//                                                               .subdirectory_arrow_right,
//                                                           size: 20,
//                                                         )),
//
//                                                     SizedBox(width: 8),
//                                                     Text(field['target'],
//                                                         style: TextStyle(
//                                                           color: AppColors
//                                                               .primaryMain,
//                                                           fontSize: 14,
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                         ))
//                                                   ],
//                                                 ),
//                                                 SizedBox(height: 8),
//                                                 Row(
//                                                   children: [
//                                                     Expanded(
//                                                       child: Container(
//                                                         decoration:
//                                                             BoxDecoration(
//                                                           border: Border.all(
//                                                               color:
//                                                                   Colors.grey),
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(8),
//                                                         ),
//                                                         child: DropdownButton2<
//                                                             String>(
//                                                           isExpanded: true,
//                                                           dropdownStyleData:
//                                                               DropdownStyleData(
//                                                             maxHeight: 300,
//                                                             // 👇 Reduce dropdown width slightly
//                                                             width: MediaQuery.of(
//                                                                             context)
//                                                                         .size
//                                                                         .width *
//                                                                     0.9 -
//                                                                 40,
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           8),
//                                                               color: Theme.of(
//                                                                       context)
//                                                                   .colorScheme
//                                                                   .surface,
//                                                             ),
//                                                             // 👇 Adjust offset so it aligns nicely under the field
//                                                             offset:
//                                                                 const Offset(
//                                                                     10, 4),
//                                                           ),
//                                                           buttonStyleData:
//                                                               const ButtonStyleData(
//                                                             padding: EdgeInsets
//                                                                 .symmetric(
//                                                                     horizontal:
//                                                                         10,
//                                                                     vertical:
//                                                                         4),
//                                                           ),
//                                                           style:
//                                                               CustomTypography(
//                                                                       context)
//                                                                   .Subtitle1,
//                                                           underline:
//                                                               const SizedBox(),
//                                                           value: provider
//                                                                       .sovUploadModel
//                                                                       ?.result
//                                                                       ?.firstWhereOrNull((res) =>
//                                                                           res.targetField ==
//                                                                           field[
//                                                                               'target'])
//                                                                       ?.matches
//                                                                       ?.any((match) =>
//                                                                           match
//                                                                               .name ==
//                                                                           field[
//                                                                               'spreadsheet']) ??
//                                                                   false
//                                                               ? field[
//                                                                   'spreadsheet']
//                                                               : null,
//                                                           hint: Text(
//                                                             "Ignore",
//                                                             style:
//                                                                 CustomTypography(
//                                                                         context)
//                                                                     .Subtitle1,
//                                                           ),
//                                                           items: provider
//                                                                   .sovUploadModel
//                                                                   ?.result
//                                                                   ?.firstWhereOrNull((res) =>
//                                                                       res.targetField ==
//                                                                       field[
//                                                                           'target'])
//                                                                   ?.matches
//                                                                   ?.map(
//                                                                       (match) {
//                                                                 return DropdownMenuItem<
//                                                                     String>(
//                                                                   value: match
//                                                                       .name,
//                                                                   child: Row(
//                                                                     children: [
//                                                                       Text(
//                                                                         match.name ??
//                                                                             "Unknown",
//                                                                         style: CustomTypography(context)
//                                                                             .Subtitle2,
//                                                                       ),
//                                                                       const Spacer(),
//                                                                       Text(
//                                                                         '${match.percentage ?? 0}% Match',
//                                                                         style: CustomTypography(context)
//                                                                             .Caption,
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 );
//                                                               }).toList() ??
//                                                               [],
//                                                           selectedItemBuilder:
//                                                               (context) {
//                                                             return provider
//                                                                     .sovUploadModel
//                                                                     ?.result
//                                                                     ?.firstWhereOrNull((res) =>
//                                                                         res.targetField ==
//                                                                         field[
//                                                                             'target'])
//                                                                     ?.matches
//                                                                     ?.map(
//                                                                         (match) {
//                                                                   return Align(
//                                                                     alignment:
//                                                                         Alignment
//                                                                             .centerLeft,
//                                                                     child: Text(
//                                                                       match.name ??
//                                                                           "Unknown",
//                                                                       style: CustomTypography(
//                                                                               context)
//                                                                           .Subtitle1,
//                                                                     ),
//                                                                   );
//                                                                 }).toList() ??
//                                                                 [];
//                                                           },
//                                                           onChanged:
//                                                               (newValue) {
//                                                             setState(() {
//                                                               field['spreadsheet'] =
//                                                                   newValue!;
//                                                               field['status'] =
//                                                                   'Manual Mapped';
//                                                               _tempfields
//                                                                   .add(field);
//                                                             });
//                                                           },
//                                                         ),
//                                                       ),
//                                                     ),
//
//                                                     // Expanded(
//                                                     //   child: Container(
//                                                     //     decoration:
//                                                     //         BoxDecoration(
//                                                     //       border: Border.all(
//                                                     //           color:
//                                                     //               Colors.grey),
//                                                     //       borderRadius:
//                                                     //           BorderRadius
//                                                     //               .circular(8),
//                                                     //     ),
//                                                     //     child: DropdownButton<
//                                                     //         String>(
//                                                     //       isExpanded: true,
//                                                     //       padding: EdgeInsets
//                                                     //           .symmetric(
//                                                     //               horizontal:
//                                                     //                   10),
//                                                     //       menuMaxHeight: 300,
//                                                     //       borderRadius:
//                                                     //           BorderRadius
//                                                     //               .circular(8),
//                                                     //       style:
//                                                     //           CustomTypography(
//                                                     //                   context)
//                                                     //               .Subtitle1,
//                                                     //       underline: SizedBox(),
//                                                     //       menuWidth: 250,
//                                                     //       value: provider
//                                                     //                   .sovUploadModel
//                                                     //                   ?.result
//                                                     //                   ?.firstWhereOrNull((res) =>
//                                                     //                       res.targetField ==
//                                                     //                       field[
//                                                     //                           'target'])
//                                                     //                   ?.matches
//                                                     //                   ?.any((match) =>
//                                                     //                       match
//                                                     //                           .name ==
//                                                     //                       field[
//                                                     //                           'spreadsheet']) ??
//                                                     //               false
//                                                     //           ? field[
//                                                     //               'spreadsheet']
//                                                     //           : null,
//                                                     //       // Ensure value exists in dropdown
//                                                     //
//                                                     //       hint: Text(
//                                                     //         "Ignore",
//                                                     //         style:
//                                                     //             CustomTypography(
//                                                     //                     context)
//                                                     //                 .Subtitle1,
//                                                     //       ),
//                                                     //
//                                                     //       items: provider
//                                                     //               .sovUploadModel
//                                                     //               ?.result
//                                                     //               ?.firstWhereOrNull((res) =>
//                                                     //                   res.targetField ==
//                                                     //                   field[
//                                                     //                       'target'])
//                                                     //               ?.matches
//                                                     //               ?.map(
//                                                     //                   (match) {
//                                                     //             return DropdownMenuItem<
//                                                     //                 String>(
//                                                     //               value: match
//                                                     //                   .name,
//                                                     //               child: Row(
//                                                     //                 children: [
//                                                     //                   Text(
//                                                     //                     match.name ??
//                                                     //                         "Unknown",
//                                                     //                     style: CustomTypography(context)
//                                                     //                         .Subtitle2,
//                                                     //                   ),
//                                                     //                   Spacer(),
//                                                     //                   Text(
//                                                     //                     '${match.percentage ?? 0}% Match',
//                                                     //                     style: CustomTypography(context)
//                                                     //                         .Caption,
//                                                     //                   ),
//                                                     //                 ],
//                                                     //               ),
//                                                     //             );
//                                                     //           }).toList() ??
//                                                     //           [],
//                                                     //       // Prevent null list
//                                                     //
//                                                     //       selectedItemBuilder:
//                                                     //           (context) {
//                                                     //         return provider
//                                                     //                 .sovUploadModel
//                                                     //                 ?.result
//                                                     //                 ?.firstWhereOrNull((res) =>
//                                                     //                     res.targetField ==
//                                                     //                     field[
//                                                     //                         'target'])
//                                                     //                 ?.matches
//                                                     //                 ?.map(
//                                                     //                     (match) {
//                                                     //               return Align(
//                                                     //                 alignment:
//                                                     //                     Alignment
//                                                     //                         .centerLeft,
//                                                     //                 child: Text(
//                                                     //                   match.name ??
//                                                     //                       "Unknown",
//                                                     //                   style: CustomTypography(
//                                                     //                           context)
//                                                     //                       .Subtitle1,
//                                                     //                 ),
//                                                     //               );
//                                                     //             }).toList() ??
//                                                     //             [];
//                                                     //       },
//                                                     //
//                                                     //       onChanged:
//                                                     //           (newValue) {
//                                                     //         setState(() {
//                                                     //           field['spreadsheet'] =
//                                                     //               newValue!;
//                                                     //           field['status'] =
//                                                     //               'Manual Mapped';
//                                                     //           _tempfields
//                                                     //               .add(field);
//                                                     //         });
//                                                     //       },
//                                                     //     ),
//                                                     //   ),
//                                                     // ),
//                                                     SizedBox(width: 10),
//                                                     TextButton(
//                                                       onPressed: field[
//                                                                   'status'] ==
//                                                               'Manual Mapped'
//                                                           ? () {
//                                                               setState(() {
//                                                                 field['status'] =
//                                                                     "Auto Mapped";
//                                                                 var originalField =
//                                                                     _initialfields.firstWhereOrNull((test) =>
//                                                                         test[
//                                                                             "target"] ==
//                                                                         field[
//                                                                             "target"]);
//
//                                                                 if (originalField !=
//                                                                     null) {
//                                                                   field["spreadsheet"] =
//                                                                       originalField[
//                                                                           "spreadsheet"];
//                                                                 }
//
//                                                                 _tempfields.removeWhere(
//                                                                     (test) =>
//                                                                         test[
//                                                                             "spreadsheet"] ==
//                                                                         field[
//                                                                             "spreadsheet"]);
//                                                                 _pendingReverts[
//                                                                         field[
//                                                                             'target']] =
//                                                                     true;
//                                                               });
//                                                             }
//                                                           : null,
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             'Revert',
//                                                             style: TextStyle(
//                                                               color: field[
//                                                                           'status'] ==
//                                                                       'Manual Mapped'
//                                                                   ? AppColors
//                                                                       .primaryMain
//                                                                   : Colors.grey,
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 SizedBox(height: 8),
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                         Align(
//                                           alignment: Alignment.topRight,
//                                           child: Padding(
//                                             padding: const EdgeInsets.only(
//                                                 top: 4.0, right: 4.0),
//                                             child: _buildStatusChip(
//                                                 field['status']),
//                                           ),
//                                         ),
//                                       ],
//                                     );
//                                   }).toList(),
//                                 ),
//                               ),
//                             );
//                           })
//                         : _selectedFilter == 'Manual Mapped'
//                             ? Builder(builder: (context) {
//                                 return Expanded(
//                                   child: SingleChildScrollView(
//                                     child: Column(
//                                       children: _manualappedfields
//                                           .where((field) =>
//                                               _searchQuery.isEmpty ||
//                                               field['target']
//                                                   .toLowerCase()
//                                                   .contains(_searchQuery
//                                                       .toLowerCase()))
//                                           .map((field) {
//                                         return Stack(
//                                           clipBehavior: Clip.hardEdge,
//                                           children: [
//                                             Card(
//                                               color: Theme.of(context)
//                                                   .colorScheme
//                                                   .surfaceContainerHigh,
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.all(8.0),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         // rotate 90 to right
//                                                         Transform(
//                                                             transform: Matrix4
//                                                                 .rotationZ(
//                                                                     1.5708),
//                                                             alignment: Alignment
//                                                                 .center,
//                                                             child: Icon(
//                                                               Icons
//                                                                   .subdirectory_arrow_right,
//                                                               size: 20,
//                                                             )),
//
//                                                         SizedBox(width: 8),
//                                                         Text(
//                                                           field['target'],
//                                                           style: TextStyle(
//                                                             color: AppColors
//                                                                 .primaryMain,
//                                                             fontSize: 14,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     SizedBox(height: 8),
//                                                     Row(
//                                                       children: [
//                                                         Expanded(
//                                                           child: Container(
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               border: Border.all(
//                                                                   color: Colors
//                                                                       .grey),
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           8),
//                                                             ),
//                                                             child:
//                                                                 DropdownButtonHideUnderline(
//                                                               child:
//                                                                   DropdownButton2<
//                                                                       String>(
//                                                                 isExpanded:
//                                                                     true,
//
//                                                                 dropdownStyleData:
//                                                                     DropdownStyleData(
//                                                                   maxHeight:
//                                                                       300,
//                                                                   // 👇 dropdown width reduced slightly compared to the field
//                                                                   width: MediaQuery.of(context)
//                                                                               .size
//                                                                               .width *
//                                                                           0.9 -
//                                                                       75,
//                                                                   decoration:
//                                                                       BoxDecoration(
//                                                                     borderRadius:
//                                                                         BorderRadius
//                                                                             .circular(8),
//                                                                     color: Theme.of(
//                                                                             context)
//                                                                         .colorScheme
//                                                                         .surface,
//                                                                   ),
//                                                                   // 👇 ensures dropdown appears just below the field
//                                                                   offset:
//                                                                       const Offset(
//                                                                           0,
//                                                                           -2),
//                                                                 ),
//
//                                                                 buttonStyleData:
//                                                                     const ButtonStyleData(
//                                                                   padding: EdgeInsets
//                                                                       .symmetric(
//                                                                           horizontal:
//                                                                               10),
//                                                                 ),
//
//                                                                 style: CustomTypography(
//                                                                         context)
//                                                                     .Subtitle1,
//
//                                                                 hint: Text(
//                                                                   "Ignore",
//                                                                   style: CustomTypography(
//                                                                           context)
//                                                                       .Subtitle1,
//                                                                 ),
//
//                                                                 // 👇 Ensure selected value exists in dropdown items, otherwise null
//                                                                 value: provider
//                                                                             .sovUploadModel
//                                                                             ?.result
//                                                                             ?.firstWhereOrNull(
//                                                                               (res) => res.targetField == field['target'],
//                                                                             )
//                                                                             ?.matches
//                                                                             ?.any((match) =>
//                                                                                 match.name ==
//                                                                                 field['spreadsheet']) ??
//                                                                         false
//                                                                     ? field['spreadsheet']
//                                                                     : null,
//
//                                                                 items: provider
//                                                                         .sovUploadModel
//                                                                         ?.result
//                                                                         ?.firstWhereOrNull(
//                                                                           (res) =>
//                                                                               res.targetField ==
//                                                                               field['target'],
//                                                                         )
//                                                                         ?.matches
//                                                                         ?.map(
//                                                                             (match) {
//                                                                       return DropdownMenuItem<
//                                                                           String>(
//                                                                         value: match
//                                                                             .name,
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               match.name ?? "Unknown",
//                                                                               style: CustomTypography(context).Subtitle2,
//                                                                             ),
//                                                                             const Spacer(),
//                                                                             Text(
//                                                                               '${match.percentage ?? 0}% Match',
//                                                                               style: CustomTypography(context).Caption,
//                                                                             ),
//                                                                           ],
//                                                                         ),
//                                                                       );
//                                                                     }).toList() ??
//                                                                     [],
//
//                                                                 // 👇 Prevent null list
//                                                                 selectedItemBuilder:
//                                                                     (context) {
//                                                                   return provider
//                                                                           .sovUploadModel
//                                                                           ?.result
//                                                                           ?.firstWhereOrNull(
//                                                                             (res) =>
//                                                                                 res.targetField ==
//                                                                                 field['target'],
//                                                                           )
//                                                                           ?.matches
//                                                                           ?.map(
//                                                                               (match) {
//                                                                         return Align(
//                                                                           alignment:
//                                                                               Alignment.centerLeft,
//                                                                           child:
//                                                                               Text(
//                                                                             match.name ??
//                                                                                 "Unknown",
//                                                                             style:
//                                                                                 CustomTypography(context).Subtitle1,
//                                                                           ),
//                                                                         );
//                                                                       }).toList() ??
//                                                                       [];
//                                                                 },
//
//                                                                 onChanged:
//                                                                     (newValue) {
//                                                                   setState(() {
//                                                                     field['spreadsheet'] =
//                                                                         newValue!;
//                                                                     field['status'] =
//                                                                         'Auto Mapped';
//                                                                     _tempfields
//                                                                         .add(
//                                                                             field);
//                                                                   });
//                                                                   print(
//                                                                       "Status: ${field['status']}");
//                                                                   print(
//                                                                       "Selected Value: $newValue");
//                                                                 },
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//
//                                                         // Expanded(
//                                                         //   child: Container(
//                                                         //     decoration:
//                                                         //         BoxDecoration(
//                                                         //       border: Border.all(
//                                                         //           color: Colors
//                                                         //               .grey),
//                                                         //       borderRadius:
//                                                         //           BorderRadius
//                                                         //               .circular(
//                                                         //                   8),
//                                                         //     ),
//                                                         //     child:
//                                                         //         DropdownButton<
//                                                         //             String>(
//                                                         //       isExpanded: true,
//                                                         //       padding: EdgeInsets
//                                                         //           .symmetric(
//                                                         //               horizontal:
//                                                         //                   10),
//                                                         //       menuMaxHeight:
//                                                         //           300,
//                                                         //       borderRadius:
//                                                         //           BorderRadius
//                                                         //               .circular(
//                                                         //                   8),
//                                                         //       style: CustomTypography(
//                                                         //               context)
//                                                         //           .Subtitle1,
//                                                         //       underline:
//                                                         //           SizedBox(),
//                                                         //       menuWidth: 250,
//                                                         //
//                                                         //       // Ensure selected value exists in dropdown items, otherwise set null
//                                                         //       value: provider
//                                                         //                   .sovUploadModel
//                                                         //                   ?.result
//                                                         //                   ?.firstWhereOrNull((res) =>
//                                                         //                       res.targetField ==
//                                                         //                       field[
//                                                         //                           'target'])
//                                                         //                   ?.matches
//                                                         //                   ?.any((match) =>
//                                                         //                       match.name ==
//                                                         //                       field[
//                                                         //                           'spreadsheet']) ??
//                                                         //               false
//                                                         //           ? field[
//                                                         //               'spreadsheet']
//                                                         //           : null,
//                                                         //
//                                                         //       hint: Text(
//                                                         //         "Ignore",
//                                                         //         style: CustomTypography(
//                                                         //                 context)
//                                                         //             .Subtitle1,
//                                                         //       ),
//                                                         //
//                                                         //       items: provider
//                                                         //               .sovUploadModel
//                                                         //               ?.result
//                                                         //               ?.firstWhereOrNull((res) =>
//                                                         //                   res.targetField ==
//                                                         //                   field[
//                                                         //                       'target'])
//                                                         //               ?.matches
//                                                         //               ?.map(
//                                                         //                   (match) {
//                                                         //             return DropdownMenuItem<
//                                                         //                 String>(
//                                                         //               value: match
//                                                         //                   .name,
//                                                         //               child:
//                                                         //                   Row(
//                                                         //                 children: [
//                                                         //                   Text(
//                                                         //                     match.name ??
//                                                         //                         "Unknown",
//                                                         //                     style:
//                                                         //                         CustomTypography(context).Subtitle2,
//                                                         //                   ),
//                                                         //                   Spacer(),
//                                                         //                   Text(
//                                                         //                     '${match.percentage ?? 0}% Match',
//                                                         //                     style:
//                                                         //                         CustomTypography(context).Caption,
//                                                         //                   ),
//                                                         //                 ],
//                                                         //               ),
//                                                         //             );
//                                                         //           }).toList() ??
//                                                         //           [],
//                                                         //       // Prevent null list
//                                                         //
//                                                         //       selectedItemBuilder:
//                                                         //           (context) {
//                                                         //         return provider
//                                                         //                 .sovUploadModel
//                                                         //                 ?.result
//                                                         //                 ?.firstWhereOrNull((res) =>
//                                                         //                     res.targetField ==
//                                                         //                     field[
//                                                         //                         'target'])
//                                                         //                 ?.matches
//                                                         //                 ?.map(
//                                                         //                     (match) {
//                                                         //               return Align(
//                                                         //                 alignment:
//                                                         //                     Alignment.centerLeft,
//                                                         //                 child:
//                                                         //                     Text(
//                                                         //                   match.name ??
//                                                         //                       "Unknown",
//                                                         //                   style:
//                                                         //                       CustomTypography(context).Subtitle1,
//                                                         //                 ),
//                                                         //               );
//                                                         //             }).toList() ??
//                                                         //             [];
//                                                         //       },
//                                                         //
//                                                         //       onChanged:
//                                                         //           (newValue) {
//                                                         //         setState(() {
//                                                         //           field['spreadsheet'] =
//                                                         //               newValue!;
//                                                         //           field['status'] =
//                                                         //               'Auto Mapped';
//                                                         //           _tempfields
//                                                         //               .add(
//                                                         //                   field);
//                                                         //         });
//                                                         //         print(
//                                                         //             "Status: ${field['status']}");
//                                                         //         print(
//                                                         //             "Selected Value: $newValue");
//                                                         //       },
//                                                         //     ),
//                                                         //   ),
//                                                         // ),
//                                                         SizedBox(width: 10),
//                                                         TextButton(
//                                                           onPressed: field[
//                                                                       'status'] ==
//                                                                   'Manual Mapped'
//                                                               ? () {
//                                                                   setState(() {
//                                                                     // Find the original mapping
//                                                                     var originalField = _initialfields.firstWhereOrNull((test) =>
//                                                                         test[
//                                                                             "target"] ==
//                                                                         field[
//                                                                             "target"]);
//
//                                                                     if (originalField !=
//                                                                         null) {
//                                                                       field["spreadsheet"] =
//                                                                           originalField[
//                                                                               "spreadsheet"];
//
//                                                                       if (originalField[
//                                                                               'status'] ==
//                                                                           'Auto Mapped') {
//                                                                         setState(
//                                                                             () {
//                                                                           field['status'] =
//                                                                               'Auto Mapped';
//                                                                         });
//                                                                         _automappedfields
//                                                                             .add(field);
//                                                                       } else {
//                                                                         setState(
//                                                                             () {
//                                                                           field['status'] =
//                                                                               'Unmapped';
//                                                                         });
//                                                                         _unmappedfields
//                                                                             .add(field);
//                                                                       }
//                                                                     } else {
//                                                                       field["spreadsheet"] =
//                                                                           '';
//                                                                     }
//
//                                                                     // Update field lists accordingly
//                                                                     _tempfields.removeWhere((test) =>
//                                                                         test[
//                                                                             "spreadsheet"] ==
//                                                                         field[
//                                                                             "spreadsheet"]);
//
//                                                                     _manualappedfields.removeWhere((test) =>
//                                                                         test[
//                                                                             "spreadsheet"] ==
//                                                                         field[
//                                                                             "spreadsheet"]);
//
//                                                                     _pendingReverts[
//                                                                             field['target']] =
//                                                                         true; // Mark field for revert
//                                                                   });
//                                                                 }
//                                                               : null,
//                                                           // Disable if not manually mapped
//                                                           child: Row(
//                                                             children: [
//                                                               Text(
//                                                                 'Revert',
//                                                                 style:
//                                                                     TextStyle(
//                                                                   color: field[
//                                                                               'status'] ==
//                                                                           'Manual Mapped'
//                                                                       ? AppColors
//                                                                           .primaryMain
//                                                                       : Colors
//                                                                           .grey,
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     SizedBox(height: 8),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                             Align(
//                                               alignment: Alignment.topRight,
//                                               child: Padding(
//                                                 padding: const EdgeInsets.only(
//                                                     top: 4.0, right: 4.0),
//                                                 child: _buildStatusChip(
//                                                     field['status']),
//                                               ),
//                                             ),
//                                           ],
//                                         );
//                                       }).toList(),
//                                     ),
//                                   ),
//                                 );
//                               })
//                             : Builder(builder: (context) {
//                                 return Expanded(
//                                   child: SingleChildScrollView(
//                                     child: Column(
//                                       children: _unmappedfields
//                                           .where((field) =>
//                                               _searchQuery.isEmpty ||
//                                               field['target']
//                                                   .toLowerCase()
//                                                   .contains(_searchQuery
//                                                       .toLowerCase()))
//                                           .map((field) {
//                                         return Stack(
//                                           clipBehavior: Clip.hardEdge,
//                                           children: [
//                                             Card(
//                                               color: Theme.of(context)
//                                                   .colorScheme
//                                                   .surfaceContainerHigh,
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.all(8.0),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         // rotate 90 to right
//                                                         Transform(
//                                                             transform: Matrix4
//                                                                 .rotationZ(
//                                                                     1.5708),
//                                                             alignment: Alignment
//                                                                 .center,
//                                                             child: Icon(
//                                                               Icons
//                                                                   .subdirectory_arrow_right,
//                                                               size: 20,
//                                                             )),
//
//                                                         SizedBox(width: 8),
//                                                         Text(field['target'],
//                                                             style: TextStyle(
//                                                               color: AppColors
//                                                                   .primaryMain,
//                                                               fontSize: 14,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             )),
//                                                       ],
//                                                     ),
//                                                     SizedBox(height: 8),
//                                                     Row(
//                                                       children: [
//                                                         Expanded(
//                                                           child: Container(
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               border: Border.all(
//                                                                   color: Colors
//                                                                       .grey),
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           8),
//                                                             ),
//                                                             child:
//                                                                 DropdownButtonHideUnderline(
//                                                               child:
//                                                                   DropdownButton2<
//                                                                       String>(
//                                                                 isExpanded:
//                                                                     true,
//
//                                                                 dropdownStyleData:
//                                                                     DropdownStyleData(
//                                                                   maxHeight:
//                                                                       300,
//                                                                   width: MediaQuery.of(context)
//                                                                               .size
//                                                                               .width *
//                                                                           0.9 -
//                                                                       75,
//                                                                   decoration:
//                                                                       BoxDecoration(
//                                                                     borderRadius:
//                                                                         BorderRadius
//                                                                             .circular(8),
//                                                                     color: Theme.of(
//                                                                             context)
//                                                                         .colorScheme
//                                                                         .surface,
//                                                                   ),
//                                                                   offset:
//                                                                       const Offset(
//                                                                           0,
//                                                                           -2),
//                                                                 ),
//
//                                                                 buttonStyleData:
//                                                                     const ButtonStyleData(
//                                                                   padding: EdgeInsets
//                                                                       .symmetric(
//                                                                           horizontal:
//                                                                               10),
//                                                                 ),
//
//                                                                 style: CustomTypography(
//                                                                         context)
//                                                                     .Subtitle1,
//
//                                                                 hint: Text(
//                                                                   "Ignore",
//                                                                   style: CustomTypography(
//                                                                           context)
//                                                                       .Subtitle1,
//                                                                 ),
//
//                                                                 // ✅ Selected Value Validation
//                                                                 value: provider
//                                                                             .sovUploadModel
//                                                                             ?.result
//                                                                             ?.firstWhereOrNull(
//                                                                               (res) => res.targetField == field['target'],
//                                                                             )
//                                                                             ?.matches
//                                                                             ?.any((match) =>
//                                                                                 match.name ==
//                                                                                 field['spreadsheet']) ??
//                                                                         false
//                                                                     ? field['spreadsheet']
//                                                                     : null,
//
//                                                                 // ✅ Dropdown Items
//                                                                 items: provider
//                                                                         .sovUploadModel
//                                                                         ?.result
//                                                                         ?.firstWhereOrNull(
//                                                                           (res) =>
//                                                                               res.targetField ==
//                                                                               field['target'],
//                                                                         )
//                                                                         ?.matches
//                                                                         ?.map((match) =>
//                                                                             match
//                                                                                 .name)
//                                                                         ?.toSet()
//                                                                         ?.map(
//                                                                             (uniqueName) {
//                                                                       final match = provider
//                                                                           .sovUploadModel!
//                                                                           .result!
//                                                                           .firstWhereOrNull((res) =>
//                                                                               res.targetField ==
//                                                                               field[
//                                                                                   'target'])
//                                                                           ?.matches
//                                                                           ?.firstWhere((m) =>
//                                                                               m.name ==
//                                                                               uniqueName);
//
//                                                                       return DropdownMenuItem<
//                                                                           String>(
//                                                                         value:
//                                                                             uniqueName,
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               uniqueName ?? "Unknown",
//                                                                               style: CustomTypography(context).Subtitle2,
//                                                                             ),
//                                                                             const Spacer(),
//                                                                             Text(
//                                                                               '${match?.percentage ?? 0}% Match',
//                                                                               style: CustomTypography(context).Caption,
//                                                                             ),
//                                                                           ],
//                                                                         ),
//                                                                       );
//                                                                     }).toList() ??
//                                                                     [],
//
//                                                                 // ✅ Selected Item Builder
//                                                                 selectedItemBuilder:
//                                                                     (context) {
//                                                                   return provider
//                                                                           .sovUploadModel
//                                                                           ?.result
//                                                                           ?.firstWhereOrNull(
//                                                                             (res) =>
//                                                                                 res.targetField ==
//                                                                                 field['target'],
//                                                                           )
//                                                                           ?.matches
//                                                                           ?.map(
//                                                                               (match) {
//                                                                         return Align(
//                                                                           alignment:
//                                                                               Alignment.centerLeft,
//                                                                           child:
//                                                                               Text(
//                                                                             match.name ??
//                                                                                 "Unknown",
//                                                                             style:
//                                                                                 CustomTypography(context).Subtitle1,
//                                                                           ),
//                                                                         );
//                                                                       }).toList() ??
//                                                                       [];
//                                                                 },
//
//                                                                 // ✅ On Change Handler
//                                                                 onChanged:
//                                                                     (newValue) {
//                                                                   setState(() {
//                                                                     field['spreadsheet'] =
//                                                                         newValue!;
//                                                                     field['status'] =
//                                                                         'Manual Mapped';
//                                                                     _tempfields
//                                                                         .add(
//                                                                             field);
//                                                                   });
//
//                                                                   final match = provider
//                                                                       .sovUploadModel
//                                                                       ?.result
//                                                                       ?.firstWhereOrNull(
//                                                                         (res) =>
//                                                                             res.targetField ==
//                                                                             field['target'],
//                                                                       )
//                                                                       ?.matches
//                                                                       ?.firstWhereOrNull((m) =>
//                                                                           m.name ==
//                                                                           newValue);
//
//                                                                   print(
//                                                                       "Selected Value: $newValue");
//                                                                   print(
//                                                                       "ID: ${match?.id}");
//                                                                   print(
//                                                                       "Percentage: ${match?.percentage}");
//                                                                   print(
//                                                                       "is_data_parameter: ${match?.is_data_parameter}");
//                                                                   print(
//                                                                       "Status: ${field['status']}");
//                                                                 },
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//
//                                                         // Expanded(
//                                                         //   child: Container(
//                                                         //     decoration:
//                                                         //         BoxDecoration(
//                                                         //       border: Border.all(
//                                                         //           color: Colors
//                                                         //               .grey),
//                                                         //       borderRadius:
//                                                         //           BorderRadius
//                                                         //               .circular(
//                                                         //                   8),
//                                                         //     ),
//                                                         //     child:
//                                                         //         DropdownButton<
//                                                         //             String>(
//                                                         //       isExpanded: true,
//                                                         //       padding: EdgeInsets
//                                                         //           .symmetric(
//                                                         //               horizontal:
//                                                         //                   10),
//                                                         //       menuMaxHeight:
//                                                         //           300,
//                                                         //       borderRadius:
//                                                         //           BorderRadius
//                                                         //               .circular(
//                                                         //                   8),
//                                                         //       style: CustomTypography(
//                                                         //               context)
//                                                         //           .Subtitle1,
//                                                         //       underline:
//                                                         //           SizedBox(),
//                                                         //       menuWidth: 250,
//                                                         //
//                                                         //       // Ensure selected value exists in dropdown items, otherwise set null
//                                                         //       value: provider
//                                                         //                   .sovUploadModel
//                                                         //                   ?.result
//                                                         //                   ?.firstWhereOrNull((res) =>
//                                                         //                       res.targetField ==
//                                                         //                       field[
//                                                         //                           'target'])
//                                                         //                   ?.matches
//                                                         //                   ?.any((match) =>
//                                                         //                       match.name ==
//                                                         //                       field[
//                                                         //                           'spreadsheet']) ??
//                                                         //               false
//                                                         //           ? field[
//                                                         //               'spreadsheet']
//                                                         //           : null,
//                                                         //
//                                                         //       hint: Text(
//                                                         //         "Ignore",
//                                                         //         style: CustomTypography(
//                                                         //                 context)
//                                                         //             .Subtitle1,
//                                                         //       ),
//                                                         //       items: provider
//                                                         //               .sovUploadModel
//                                                         //               ?.result
//                                                         //               ?.firstWhereOrNull((res) =>
//                                                         //                   res.targetField ==
//                                                         //                   field[
//                                                         //                       'target'])
//                                                         //               ?.matches
//                                                         //               ?.map((match) =>
//                                                         //                   match
//                                                         //                       .name)
//                                                         //               ?.toSet()
//                                                         //               ?.map(
//                                                         //                   (uniqueName) {
//                                                         //             final match = provider
//                                                         //                 .sovUploadModel!
//                                                         //                 .result!
//                                                         //                 .firstWhereOrNull((res) =>
//                                                         //                     res.targetField ==
//                                                         //                     field[
//                                                         //                         'target'])
//                                                         //                 ?.matches
//                                                         //                 ?.firstWhere((m) =>
//                                                         //                     m.name ==
//                                                         //                     uniqueName);
//                                                         //             return DropdownMenuItem<
//                                                         //                 String>(
//                                                         //               value:
//                                                         //                   uniqueName,
//                                                         //               child:
//                                                         //                   Row(
//                                                         //                 children: [
//                                                         //                   Text(
//                                                         //                     uniqueName ??
//                                                         //                         "Unknown",
//                                                         //                     style:
//                                                         //                         CustomTypography(context).Subtitle2,
//                                                         //                   ),
//                                                         //                   Spacer(),
//                                                         //                   Text(
//                                                         //                     '${match?.percentage ?? 0}% Match',
//                                                         //                     style:
//                                                         //                         CustomTypography(context).Caption,
//                                                         //                   ),
//                                                         //                 ],
//                                                         //               ),
//                                                         //             );
//                                                         //           }).toList() ??
//                                                         //           [],
//                                                         //       // items: provider
//                                                         //       //         .sovUploadModel
//                                                         //       //         ?.result
//                                                         //       //         ?.firstWhereOrNull((res) =>
//                                                         //       //             res.targetField ==
//                                                         //       //             field[
//                                                         //       //                 'target'])
//                                                         //       //         ?.matches
//                                                         //       //         ?.map(
//                                                         //       //             (match) {
//                                                         //       //       return DropdownMenuItem<
//                                                         //       //           String>(
//                                                         //       //         value: match
//                                                         //       //             .name,
//                                                         //       //         child:
//                                                         //       //             Row(
//                                                         //       //           children: [
//                                                         //       //             Text(
//                                                         //       //               match.name ??
//                                                         //       //                   "Unknown",
//                                                         //       //               style:
//                                                         //       //                   CustomTypography(context).Subtitle2,
//                                                         //       //             ),
//                                                         //       //             Spacer(),
//                                                         //       //             Text(
//                                                         //       //               '${match.percentage ?? 0}% Match',
//                                                         //       //               style:
//                                                         //       //                   CustomTypography(context).Caption,
//                                                         //       //             ),
//                                                         //       //           ],
//                                                         //       //         ),
//                                                         //       //       );
//                                                         //       //     }).toList() ??
//                                                         //       //     [],
//                                                         //       // Prevent null list
//                                                         //
//                                                         //       selectedItemBuilder:
//                                                         //           (context) {
//                                                         //         return provider
//                                                         //                 .sovUploadModel
//                                                         //                 ?.result
//                                                         //                 ?.firstWhereOrNull((res) =>
//                                                         //                     res.targetField ==
//                                                         //                     field[
//                                                         //                         'target'])
//                                                         //                 ?.matches
//                                                         //                 ?.map(
//                                                         //                     (match) {
//                                                         //               return Align(
//                                                         //                 alignment:
//                                                         //                     Alignment.centerLeft,
//                                                         //                 child:
//                                                         //                     Text(
//                                                         //                   match.name ??
//                                                         //                       "Unknown",
//                                                         //                   style:
//                                                         //                       CustomTypography(context).Subtitle1,
//                                                         //                 ),
//                                                         //               );
//                                                         //             }).toList() ??
//                                                         //             [];
//                                                         //       },
//                                                         //       onChanged:
//                                                         //           (newValue) {
//                                                         //         setState(() {
//                                                         //           field['spreadsheet'] =
//                                                         //               newValue!;
//                                                         //           field['status'] =
//                                                         //               'Manual Mapped';
//                                                         //           _tempfields
//                                                         //               .add(
//                                                         //                   field);
//                                                         //         });
//                                                         //         final match = provider
//                                                         //             .sovUploadModel
//                                                         //             ?.result
//                                                         //             ?.firstWhereOrNull((res) =>
//                                                         //                 res.targetField ==
//                                                         //                 field[
//                                                         //                     'target'])
//                                                         //             ?.matches
//                                                         //             ?.firstWhereOrNull((m) =>
//                                                         //                 m.name ==
//                                                         //                 newValue);
//                                                         //
//                                                         //         print(
//                                                         //             "Selected Value: $newValue");
//                                                         //         print(
//                                                         //             "ID: ${match?.id}");
//                                                         //         print(
//                                                         //             "Percentage: ${match?.percentage}");
//                                                         //         print(
//                                                         //             "Percentage: ${match?.is_data_parameter}");
//                                                         //         print(
//                                                         //             "Status: ${field['status']}");
//                                                         //       },
//                                                         //     ),
//                                                         //   ),
//                                                         // ),
//                                                         SizedBox(width: 10),
//                                                         TextButton(
//                                                           onPressed: field[
//                                                                       'status'] ==
//                                                                   'Manual Mapped'
//                                                               ? () {
//                                                                   setState(() {
//                                                                     field['status'] =
//                                                                         'Unmapped';
//
//                                                                     // Find the original mapping
//                                                                     var originalField = _initialfields.firstWhereOrNull((test) =>
//                                                                         test[
//                                                                             "target"] ==
//                                                                         field[
//                                                                             "target"]);
//
//                                                                     if (originalField !=
//                                                                         null) {
//                                                                       field["spreadsheet"] =
//                                                                           originalField[
//                                                                               "spreadsheet"];
//                                                                     } else {
//                                                                       field["spreadsheet"] =
//                                                                           '';
//                                                                     }
//
//                                                                     // Update field lists accordingly
//                                                                     _tempfields.removeWhere((test) =>
//                                                                         test[
//                                                                             "spreadsheet"] ==
//                                                                         field[
//                                                                             "spreadsheet"]);
//                                                                     _pendingReverts[
//                                                                             field['target']] =
//                                                                         true; // Mark field for revert
//                                                                   });
//                                                                 }
//                                                               : null,
//                                                           // Disable if not manually mapped
//                                                           child: Row(
//                                                             children: [
//                                                               Text(
//                                                                 'Revert',
//                                                                 style:
//                                                                     TextStyle(
//                                                                   color: field[
//                                                                               'status'] ==
//                                                                           'Manual Mapped'
//                                                                       ? AppColors
//                                                                           .primaryMain
//                                                                       : Colors
//                                                                           .grey,
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     SizedBox(height: 8),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                             Align(
//                                               alignment: Alignment.topRight,
//                                               child: Padding(
//                                                 padding: const EdgeInsets.only(
//                                                     top: 4.0, right: 4.0),
//                                                 child: _buildStatusChip(
//                                                     field['status']),
//                                               ),
//                                             ),
//                                           ],
//                                         );
//                                       }).toList(),
//                                     ),
//                                   ),
//                                 );
//                               }),
//                 Consumer<UploadSovProvider>(
//                   builder: (context, provider, child) {
//                     if (provider.isLoading) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 8.0),
//                       child: Row(
//                         children: [
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.primaryMain,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               onPressed: _handleNext,
//                               child: Text(
//                                 "Submit All",
//                                 style: CustomTypography(context)
//                                     .ButtonLarge
//                                     .copyWith(
//                                         color: Colors.black,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.w500),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//                 SizedBox(height: 20),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   void _handleNext() {
//     // Ensure correct data parameter handling
//     List<Map<String, dynamic>> fieldsToSubmit = _fields.map((field) {
//       // Only include 'is_data_parameter' if true
//       final Map<String, dynamic> updatedField =
//           Map<String, dynamic>.from(field);
//       if (field['is_data_parameter'] != true) {
//         updatedField.remove('is_data_parameter');
//       } else {
//         updatedField['is_data_parameter'] = true;
//       }
//       return updatedField;
//     }).toList();
//
//     final provider = Provider.of<UploadSovProvider>(context, listen: false);
//     if (widget.accountId.isNotEmpty && widget.accountName.isNotEmpty) {
//       provider.submitSovHeadersSubAccounts(
//         context,
//         widget.tempId,
//         provider.sovUploadModel?.url ?? "",
//         fieldsToSubmit,
//         widget.accountId,
//         widget.accountName,
//         widget.subAccountName ?? "",
//         widget.subAccountId,
//       );
//     } else {
//       provider.submitSovHeadersAccounts(
//         context,
//         widget.tempId,
//         provider.sovUploadModel?.url ?? "",
//         fieldsToSubmit,
//         widget.subAccountName ?? "",
//       );
//     }
//   }
//
// // void _handleNext() {
// //   bool hasUnmappedFields =
// //       _fields.any((field) => field['status'] == 'Unmapped');
// //
// //   // if (hasUnmappedFields) {
// //   //   // Show a warning if there are unmapped fields
// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     SnackBar(
// //   //       content: Text(LanguageService.getTranslated(
// //   //           context, "app_unmapped_fields_warning")),
// //   //       backgroundColor: Colors.redAccent,
// //   //     ),
// //   //   );
// //   // } else {
// //   // Proceed with the submission process if all fields are mapped
// //   final provider = Provider.of<UploadSovProvider>(context, listen: false);
// //   if (widget.accountId != '' && widget.accountName != '') {
// //     provider.submitSovHeadersSubAccounts(
// //       context,
// //       widget.tempId,
// //       provider.sovUploadModel?.url ?? "",
// //       _fields,
// //       widget.accountId,
// //       widget.accountName,
// //       widget.subAccountName ?? "",
// //       widget.subAccountId,
// //     );
// //   } else {
// //     provider.submitSovHeadersAccounts(
// //       context,
// //       widget.tempId,
// //       provider.sovUploadModel?.url ?? "",
// //       _fields,
// //       widget.subAccountName ?? "",
// //     );
// //   }
// //   // }
// // }
// }
