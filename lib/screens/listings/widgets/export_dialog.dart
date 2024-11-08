import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:provider/provider.dart';

import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../service/language_service.dart';
import '../../../providers/sov_list_provider.dart';

class ExportDialog extends StatefulWidget {
  final String accountId;
  final String subAccountId;
  final List<String> locationId;
  final String sovId;

  const ExportDialog({Key? key, required this.accountId, required this.subAccountId, required this.locationId, this.sovId = ''}) : super(key: key);

  @override
  _ExportDialogState createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _format = 'doc';
  ExportType _exportType = ExportType.Profile;
  bool _includeImagesAsUrl = true;
  bool _downloadImagesInZip = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SOVListProvider>(context);
    var typography = CustomTypography(context);
    return Stack(
      children: [
        AlertDialog(
          title: Text(LanguageService.getTranslated(context, "export_dialog_title"), style: typography.Body1),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: CustomSpacing.six),
              DropdownButtonFormField<String>(
                value: _format,
                items: [
                  DropdownMenuItem(
                    value: 'doc',
                    child: Text('Word(.doc)', style: typography.Body1),
                  ),
                  DropdownMenuItem(
                    value: 'excel',
                    child: Text('Excel(.xls)',style: typography.Body1),
                  ),
                  DropdownMenuItem(
                    value: 'pdf',
                    child: Text('PDF', style: typography.Body1),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _format = value!;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: LanguageService.getTranslated(context, "export_dialog_format"),
                ),
                style: typography.Body1,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(LanguageService.getTranslated(context, "export_dialog_profile"), style: typography.Body1),
                leading: Radio(
                  value: ExportType.Profile,
                  groupValue: _exportType,
                  onChanged: (value) {
                    setState(() {
                      _exportType = value as ExportType;
                    });
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(LanguageService.getTranslated(context, "export_dialog_table"), style: typography.Body1),
                leading: Radio(
                  value: ExportType.Table,
                  groupValue: _exportType,
                  onChanged: (value) {
                    setState(() {
                      _exportType = value as ExportType;
                    });
                  },
                ),
              ),
              Divider(),
              SwitchListTile(
                title: Text(LanguageService.getTranslated(context, "export_dialog_include_images_as_url"), style: typography.Body1),
                value: _includeImagesAsUrl,
                onChanged: (value) {
                  setState(() {
                    _includeImagesAsUrl = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text(LanguageService.getTranslated(context, "export_dialog_download_images_in_zip"), style: typography.Body1),
                value: _downloadImagesInZip,
                onChanged: (value) {
                  setState(() {
                    _downloadImagesInZip = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LanguageService.getTranslated(context, "export_dialog_cancel"), style: typography.Body1),
            ),
            CustomButton(
              onPressed: () async {
                if(widget.locationId.isNotEmpty) {
                  final exportData = //{
                  // "data":
                  {
                    /*"format": _format.toLowerCase(),
                    "fileType":
                    _exportType == ExportType.Profile ? "profile" : "table",
                    "includeImage": _includeImagesAsUrl,
                    "downloadImagesInZip": _downloadImagesInZip,
                    "sov_id": widget.sovId,
                    "location_id": widget.locationId,*/
                    "location_id": widget.locationId,
                    // }
                  };
                  await provider.exportData(
                      context, widget.accountId, widget.subAccountId,
                      exportData, widget.sovId);
                } else {
                  final exportData = //{
                  // "data":
                  {
                    /*"format": _format.toLowerCase(),
                    "fileType":
                    _exportType == ExportType.Profile ? "profile" : "table",
                    "includeImage": _includeImagesAsUrl,
                    "downloadImagesInZip": _downloadImagesInZip,*/
                    "location_id": widget.locationId,
                    // }
                  };
                  await provider.exportData(
                      context, widget.accountId, widget.subAccountId,
                      exportData, widget.sovId);
                }
              },
              child: Text(LanguageService.getTranslated(context, "export_dialog_download"), style: typography.Body1),
              type: ButtonType.elevated,
            ),
          ],
        ),
        if (provider.isExportLoading)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
