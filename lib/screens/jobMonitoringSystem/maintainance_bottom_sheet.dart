import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:RiskSphere/design_system/components/custom_button.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/providers/job_monitoring_provier.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/enums.dart';
import '../../design_system/primitives/app_colors.dart';
import '../../models/maintainance_model.dart';

class MaintainanceBottomSheet extends StatefulWidget {
  const MaintainanceBottomSheet({super.key});

  @override
  _MaintainanceBottomSheetState createState() =>
      _MaintainanceBottomSheetState();
}

class _MaintainanceBottomSheetState extends State<MaintainanceBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  String? _editingId;  // Null if creating a new maintenance period.
  bool _isEditing = false;  // To toggle between create and edit modes.

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getData();
  }

  _getData() {
    var jobMonitoringProvider =
        Provider.of<JobMonitoringProvider>(context, listen: false);
    jobMonitoringProvider.getMaintainancePeriod();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 16),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                //margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.center,
                  labelStyle:
                      CustomTypography(context).BottomNavigationActiveLabel,
                  unselectedLabelStyle:
                      CustomTypography(context).BottomNavigationActiveLabel,
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800], // Highlighted tab background
                  ),
                  //indicatorPadding: EdgeInsets.symmetric(horizontal: -MediaQuery.of(context).size.width*0.05),
                  indicatorSize: TabBarIndicatorSize.tab,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  tabs: [
                    Tab(
                        child: Text('Plan Maintenance',
                            style: CustomTypography(context).InputLabel)),
                    Tab(
                        child: Text('Maintenance Schedule',
                            style: CustomTypography(context).InputLabel)),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTab(),
                _buildListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select maintenance period',
              style: CustomTypography(context).H5_Regular),
          const SizedBox(height: 16),
          _buildDateTimeField(
            label: 'Start date and time',
            hint: _startDate != null
                ? _formatDate(_startDate!)
                : 'DD/MM/YYYY HH:MM',
            onIconPressed: () => _selectStartDate(context),
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            label: 'End date and time',
            hint:
                _endDate != null ? _formatDate(_endDate!) : 'DD/MM/YYYY HH:MM',
            onIconPressed: () => _selectEndDate(context),
          ),
          const SizedBox(height: 16),
          Consumer<JobMonitoringProvider>(
            builder: (context, jobMonitoringProvider, child) {
              return Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [


                      Expanded(
                        child: jobMonitoringProvider.isAddLoading
                            ? const Center(child: CircularProgressIndicator())
                            :   CustomButton(
                          type: ButtonType.elevated,
                          onPressed: _isButtonEnabled() ? (_isEditing ? _updateMaintenance : _scheduleMaintenance) : null,
                          child: Text(_isEditing ? 'Update' : 'Schedule Maintenance',
                              style: CustomTypography(context).ButtonLarge, textAlign: TextAlign.center,),
                        ),

                      ),
                    ],
                  ),
                  if (_isEditing)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: jobMonitoringProvider.isAddLoading
                            ? const Center(child: CircularProgressIndicator())
                            :   CustomButton(
                          type: ButtonType.text,
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _isEditing = false;
                              _editingId = null;
                            });
                          },
                          child: Text('Clear',
                              style: CustomTypography(context).ButtonLarge, textAlign: TextAlign.center,),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String hint,
    required VoidCallback onIconPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CustomTypography(context).Body2),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.grey),
              onPressed: onIconPressed,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          _startDate = selectedDateTime;
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) return;

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          _endDate = selectedDateTime;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final format = DateFormat('dd/MM/yyyy hh:mm a');
    return format.format(date);
  }

  bool _isButtonEnabled() {
    return _startDate != null && _endDate != null;
  }

  Future<void> _scheduleMaintenance() async {
    print('Local: ${_startDate!.toIso8601String()}');
    print('Local: ${_endDate!.toIso8601String()}');
    print('UTC: ${_startDate!.toUtc().toIso8601String()}');
    print('UTC: ${_endDate!.toUtc().toIso8601String()}');
    var jobMonitoringProvider =
        Provider.of<JobMonitoringProvider>(context, listen: false);
    String result = await jobMonitoringProvider.addMaintainancePeriod(
      _startDate!.toUtc().toIso8601String(),
      _endDate!.toUtc().toIso8601String(),
    );
    if (result == 'Schedule added successfully') {
      Fluttertoast.showToast(
        msg:
            'Maintenance scheduled successfully from ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.of(context).pop();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to schedule maintenance',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildListTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<JobMonitoringProvider>(
            builder: (context, jobMonitoringProvider, child) {
              if (jobMonitoringProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              List<MaintainanceModel> maintenancePeriods =
                  jobMonitoringProvider.maintainancePeriods;

              if (maintenancePeriods.isEmpty) {
                return Center(
                    child: Text('No maintenance periods found.',
                        style: CustomTypography(context).Body1));
              }

              return ListView.builder(
                itemCount: maintenancePeriods.length,
                itemBuilder: (context, index) {
                  MaintainanceModel period = maintenancePeriods[index];
                  print('UTC: ${period.startTime}');
                  String formattedStartTime =
                      _formatDate(period.startTime!.toLocal());
                  print('Local: $formattedStartTime');
                  print('UTC: ${period.endTime}');
                  String formattedEndTime =
                      _formatDate(period.endTime!.toLocal());
                  print('Local: $formattedEndTime');

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).hoverColor.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text('Start',
                                      style: CustomTypography(context).Caption),
                                ),
                                SizedBox(width: 8),
                                Text(formattedStartTime,
                                    style: CustomTypography(context).Body2),
                              ],
                            ),
                            Spacer(),
                            if (period.status != 'completed')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey[600]),
                              onPressed: () {
                                // Switch to Plan Maintenance tab and autofill data
                                setState(() {
                                  _tabController.index = 0;
                                  _startDate = period.startTime?.toLocal();
                                  _endDate = period.endTime?.toLocal();
                                  _editingId = period.id;
                                  _isEditing = true;
                                });
                              },
                            ),

                            if (period.status != 'completed')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.grey[600]),
                              onPressed: () async {
                                // Ask for confirmation before deleting
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Delete Maintenance'),
                                      content: Text(
                                          'Are you sure you want to delete this maintenance period?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            bool result = await jobMonitoringProvider.deleteMaintainancePeriod(period.id!);
                                            if (result) {
                                              Fluttertoast.showToast(
                                                msg: 'Maintenance deleted successfully.',
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor: Colors.green,
                                                textColor: Colors.white,
                                              );
                                              setState(() {
                                                jobMonitoringProvider.maintainancePeriods.removeAt(index);  // Remove from the list locally
                                              });
                                            } else {
                                              Fluttertoast.showToast(
                                                msg: 'Failed to delete maintenance.',
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                              );
                                            }
                                          },
                                          child: Text('Delete', style: CustomTypography(context).Body1,),
                                        ),
                                      ],
                                    );
                                  },
                                );

                              },
                            ),

                          ],
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text(' End ',
                                      style: CustomTypography(context).Caption),
                                ),
                                SizedBox(width: 8),
                                Text(formattedEndTime,
                                    style: CustomTypography(context).Body2),
                              ],
                            ),
                            Spacer(),
                            Chip(
                              label: Text(_getStatus(period.status),
                                  style: CustomTypography(context).Caption.copyWith(color: _getStatusColor(period.status))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateMaintenance() async {
    var jobMonitoringProvider =
    Provider.of<JobMonitoringProvider>(context, listen: false);
    print('Local: ${_startDate!.toIso8601String()}');
    print('Local: ${_endDate!.toIso8601String()}');
    print('UTC: ${_startDate!.toUtc().toIso8601String()}');
    print('UTC: ${_endDate!.toUtc().toIso8601String()}');

    String result = await jobMonitoringProvider.editMaintainancePeriod(
      _startDate!.toUtc().toIso8601String(),
      _endDate!.toUtc().toIso8601String(),
      _editingId!,
    );

    if (result == 'Update successful') {
      Fluttertoast.showToast(
        msg: 'Maintenance updated successfully.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      setState(() {
        _isEditing = false;
        _editingId = null;
      });
      Navigator.of(context).pop();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to update maintenance.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  String _getStatus(String? status) {
    if (status == 'pending') {
      return 'Pending';
    } else if (status == 'in_progress') {
      return 'In Progress';
    } else if (status == 'completed') {
      return 'Completed';
    } else {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == 'pending') {
      return Colors.orange;
    } else if (status == 'in_progress') {
      return AppColors.primaryMain;
    } else if (status == 'completed') {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

}
