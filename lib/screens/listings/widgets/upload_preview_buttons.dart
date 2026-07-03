import 'package:flutter/material.dart';
import 'package:RiskSphere/screens/listings/my_location_list.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/components/custom_button.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/upload_sov_provider.dart';

class UploadPreviewButtons extends StatefulWidget {
  final String processId;
  final String accountId;
  final String accountName;
  final String? subAccountName;
  final String tempId;
  final String subAccountId;
  final List<Map<String, dynamic>>? selectedLocations;

  const UploadPreviewButtons({
    Key? key,
    required this.processId,
    required this.accountId,
    required this.accountName,
    this.subAccountName,
    required this.tempId,
    required this.subAccountId,
    this.selectedLocations,
  }) : super(key: key);

  @override
  State<UploadPreviewButtons> createState() => _UploadPreviewButtonsState();
}

class _UploadPreviewButtonsState extends State<UploadPreviewButtons> {
  late bool _isCancelLoading = false;
  bool _isSubmitLoading = false;

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: AppColors.primaryMain,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isCancelLoading
                    ? null
                    : () {
                        // Show model dialog with text like On click give a model of warning, that this will cancel the process and the data uploaded will be purged. it cannot be recover, you will have to restart by upload the file again.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          // Disable dismissal while loading
                          builder: (context) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: Text(
                                  "Are you sure you want to cancel the process?",
                                  style: typography.Body1.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                content: Text(
                                  "This will cancel the process and the data uploaded will be purged. It cannot be recovered. You will have to restart by uploading the file again.",
                                  style: typography.Body2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                actions: [
                                  if (!_isCancelLoading)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "No, Go Back",
                                        style: typography.Body1,
                                      ),
                                    ),
                                  _isCancelLoading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.blue,
                                          ),
                                        )
                                      : CustomButton(
                                          type: ButtonType.danger,
                                          onPressed: () async {
                                            setState(() {
                                              _isCancelLoading = true;
                                            });

                                            var result = await Provider.of<
                                                        UploadSovProvider>(
                                                    context,
                                                    listen: false)
                                                .cancelSovUploadProcess(
                                                    context, widget.tempId);

                                            if (result) {
                                              Navigator.pop(
                                                  context); // Close the dialog
                                              Navigator.pop(
                                                  context); // Navigate back
                                            } else {
                                              setState(() {
                                                _isCancelLoading = false;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Error cancelling the process. Please try again."),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            "Yes, Cancel",
                                            style: typography.Body1,
                                          ),
                                        ),
                                ],
                              );
                            });
                          },
                        );
                      },
                child: _isCancelLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryMain,
                        ),
                      )
                    : Text(
                        'Cancel',
                        style: typography.ButtonLarge.copyWith(
                          color: AppColors.primaryMain,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMain,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    _isSubmitLoading ? null : () => _showCommitDialog(context),
                child: _isSubmitLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        'Commit Locations',
                        style: typography.ButtonLarge.copyWith(
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommitDialog(BuildContext context) {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);

    int geocodingCount = provider.geocodingList.length ?? 0;
    int duplicateCount = provider.duplicateLocations.length ?? 0;
    int conflictCount = provider.conflictLocations.length ?? 0;
    showDialog(
      context: context,
      builder: (context) {
        final typography = CustomTypography(context); // Get typography instance

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 10),
          // Adjust inset padding
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Do you want to proceed?",
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white12, // Divider color matching the screenshot
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // if (geocodingCount != 0) ...[
                Row(
                  children: [
                    Text(
                      widget.selectedLocations == null
                          ? '0'
                          : (geocodingCount == widget.selectedLocations!.length
                              ? geocodingCount.toString()
                              : widget.selectedLocations!.length.toString()),
                      style: typography.Body1.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Locations will be processed!",
                      style: typography.Body2.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                // ],
                //   if (duplicateCount != 0) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      duplicateCount.toString(),
                      style: typography.Body1.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Locations will be reused!",
                      style: typography.Body2.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
              // ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white12, // Divider color matching the screenshot
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryMain),
                      // Border for the "No" button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "No",
                      style: typography.Body1.copyWith(
                          color: AppColors.primaryMain),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (geocodingCount + duplicateCount > 0) {
                        _commitLocations(context);
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyLocationList(
                                      accountID: widget.accountId,
                                      subAccountID: widget.subAccountId,
                                      accountName: widget.accountName,
                                      subAccountName:
                                          widget.subAccountName ?? "",
                                    )),
                            (route) => false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("No locations to commit!"),
                          ),
                        );
                      }
                    },
                    child: Text(
                      "Yes",
                      style: typography.Body1.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _commitLocations(BuildContext context) async {
    var provider = Provider.of<UploadSovProvider>(context, listen: false);

    setState(() {
      _isSubmitLoading = true; // Show loader
    });

    await provider.commitSelectedLocations(context, widget.accountId,
        widget.accountName, widget.tempId, widget.subAccountId);

    setState(() {
      _isSubmitLoading = false; // Hide loader after submission
    });
  }
}
