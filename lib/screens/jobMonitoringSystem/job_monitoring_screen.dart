import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../providers/job_monitoring_provier.dart';
import 'maintainance_bottom_sheet.dart';

class JobMonitoringDashboard extends StatefulWidget {
  const JobMonitoringDashboard({super.key});

  @override
  JobMonitoringDashboardState createState() => JobMonitoringDashboardState();
}

class JobMonitoringDashboardState extends State<JobMonitoringDashboard> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, bool> expandedJobs = {};
  Map<String, bool> expandedSubprocess = {};

  bool _isExpanded = false;
  bool _showNotificationDot = true;

  GlobalKey expansionTileKey = GlobalKey();

  GlobalKey subProcessCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize the JobMonitoringProvider and fetch the company IDs
    Provider.of<JobMonitoringProvider>(context, listen: false)
        .fetchCompanyIds();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          isExpanded: _isExpanded,
          showNotificationDot: _showNotificationDot,
          onExpandPressed: (isExpanded) {
            setState(() {
              _isExpanded = isExpanded;
            });
          },
          onSearchPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        drawer: CustomDrawer(),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3, // Change this value to set the desired opacity (0.0 to 1.0)
                child: Image.asset(
                  'assets/images/mesh.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Text(
                        'Job Monitoring System',
                        style: typography.Body1.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.miscellaneous_services,
                            color: AppColors.warning),
                        onPressed: () {
                          // Open bottom sheet for scheduling a new maintenance.
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return const MaintainanceBottomSheet();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<JobMonitoringProvider>(
                      builder: (context, jobMonitoringProvider, child) {
                    if (jobMonitoringProvider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: jobMonitoringProvider.getJobMonitoringData(),
                      builder: (context, snapshot) {
                        // If no document IDs and not a super admin, show "No processes"
                        if (!jobMonitoringProvider.isSuperAdmin &&
                            jobMonitoringProvider.docIds.isEmpty) {
                          return Center(child: Text('No processes available'));
                        }

                        var jobs = snapshot.data?.docs ?? [];

                        return ListView.builder(
                          physics: ClampingScrollPhysics(),
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            var jobData =
                                jobs[index].data() as Map<String, dynamic>;
                            //(jobData.toString());
                            String jobId = jobData['id'] ?? '';
                            int completedTasks =
                                jobData['process_in_progress_count'] ?? 0;
                            int totalTasks = 1;
                            if (jobData['subprocesses'] != null) {
                              totalTasks = jobData['subprocesses'].length;
                            }
                            int totalLocations =
                                jobData['total_locations'] ?? 0;
                            String ownerName =
                                jobData['owner_name'] ?? 'Unknown Owner';
                            String processType =
                                jobData['current_process_type'] ??
                                    'Unknown Process Type';
                            // make first letter capital
                            processType = processType[0].toUpperCase() +
                                processType.substring(1);
                            int successCount = jobData['location_processed'] ??
                                0; // Can be calculated
                            int failureCount =
                                (jobData['location_unprocessed'] ?? 0);
                            String sovName =
                                jobData['sov_name'] ?? 'Unknown SOV';

                            return _buildJobCard(
                              jobId: jobId,
                              completedTasks: completedTasks,
                              totalTasks: totalTasks,
                              ownerName: ownerName,
                              processType: processType,
                              totalLocations: totalLocations,
                              successCount: successCount,
                              failureCount: failureCount,
                              jobData: jobData,
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard({
    required String jobId,
    required int completedTasks,
    required int totalTasks,
    required String ownerName,
    required String processType,
    required int totalLocations,
    required int successCount,
    required int failureCount,
    required Map<String, dynamic> jobData,
  }) {
    var typography = CustomTypography(context);

    // Define color variations for hover effect
    final Color collapsedColor =
        Theme.of(context).hoverColor.withOpacity(0.1); // Main card hover color
    final Color expandedColor = Theme.of(context).hoverColor;
    final Color expandedColor2 =
        Theme.of(context).hoverColor; // Darker hover color for expanded section

    return Card(
      color: collapsedColor, // Main card hover color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedBackgroundColor: collapsedColor,
        // Collapsed state color
        backgroundColor: expandedColor2,
        // Expanded section hover color
        showTrailingIcon: false,
        maintainState: false,
        tilePadding: EdgeInsets.all(12.0),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side of the card with title and progress indicator
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobId,
                        style: typography.Body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Progress bar
                          Expanded(
                            child: LinearProgressIndicator(
                              value: completedTasks / totalTasks,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              color: AppColors.primaryMain,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Progress text
                          Text(
                            '$completedTasks/$totalTasks',
                            style: typography.Subtitle2.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // Right side icons
                SvgPicture.asset(
                  'assets/images/contract.svg',
                ),
                SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                  child: Icon(
                    expandedJobs[jobId] ?? false
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: AppColors.primaryMain,
                  ),
                ),
              ],
            ),
            // Expanded content (subprocesses)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text("Main Process" //processType,
                            ),
                        backgroundColor: AppColors.primaryMain,
                        labelStyle: typography.Body1.copyWith(
                          color: AppColors.black,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                    ],
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(jobData['sov_name'] ?? 'Unknown SOV',
                            style: typography.Body2.copyWith(
                              color: AppColors.primaryMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end),
                        SizedBox(width: 8),
                        Text('@$ownerName',
                            style: typography.Body2.copyWith(
                              color: Colors.grey[500],
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Total Locations and Success/Failure Count
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Locations', style: typography.Body2),
                      Text(
                        '$totalLocations',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIconWithCount(
                          Icons.check_circle, Colors.green, successCount),
                      SizedBox(width: 8),
                      _buildIconWithCount(
                          Icons.error_outline, Colors.red, failureCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          // Subprocess list
          Container(
            color: expandedColor,
            child: Container(
              color: expandedColor,
              child: Card(
                margin: EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
                color: expandedColor,
                // Use darker hover color for expanded content
                child: _buildSubprocesses(jobData),
              ),
            ),
          ),
        ],
        onExpansionChanged: (isExpanded) {
          setState(() {
            expandedJobs[jobId] = isExpanded;
          });
        },
      ),
    );
  }

  Widget _buildIconWithCount(IconData icon, Color color, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 4),
          Text(
            '$count',
            style: CustomTypography(context).Body2,
          ),
        ],
      ),
    );
  }

  Widget _buildSubprocesses(Map<String, dynamic> jobData) {
    var unsortedSubprocesses = jobData['subprocesses'] as Map<String, dynamic>? ?? {};
    var subprocesses = Map<String, dynamic>.fromEntries(
        unsortedSubprocesses.entries.toList()
          ..sort((a, b) {
            // Safely access the 'sub_process_name' field from each entry, or fallback to 'Location Set 0'
            String subProcessNameA = (a.value as Map<String, dynamic>)['sub_process_name'] ?? 'Location Set 0';
            String subProcessNameB = (b.value as Map<String, dynamic>)['sub_process_name'] ?? 'Location Set 0';

            // Extract the numerical part from the 'sub_process_name'
            RegExp regex = RegExp(r'(\d+)$');
            var matchA = regex.firstMatch(subProcessNameA);
            var matchB = regex.firstMatch(subProcessNameB);

            // Convert the numerical part to an integer for comparison, fallback to 0 if not found
            int numberA = matchA != null ? int.parse(matchA.group(0)!) : 0;
            int numberB = matchB != null ? int.parse(matchB.group(0)!) : 0;

            // Compare the base part of the name (without numbers), then compare the numerical parts
            int stringCompare = subProcessNameA.replaceAll(RegExp(r'\d+$'), '').compareTo(subProcessNameB.replaceAll(RegExp(r'\d+$'), ''));

            // If the base names are the same, compare the numerical part
            if (stringCompare == 0) {
              return numberA.compareTo(numberB);
            }
            return stringCompare;
          })
    );

    final cardHeight = 120.0; // Approximate height of each subprocess card
    final maxHeight = cardHeight * 3; // Maximum height for 3 cards

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          children: subprocesses.entries.map((entry) {
            var subprocessData =
                <String, dynamic>{}; // Define a fallback empty map

            if (entry.value is Map<String, dynamic>) {
              // Safely cast if it is of the expected type
              subprocessData = entry.value as Map<String, dynamic>;
            } else {
              log('Unexpected data format for subprocess: ${entry.value}');
            }
            String subprocessId =
                subprocessData['payload']?['subtask_id'] ?? 'Unknown Name';
            String subprocessName =
                subprocessData['sub_process_name'] ?? 'Unknown Name';
            String locationSetName = subprocessData['location_set_name'] ??
                'Location Set'; // Can be calculated
            int successCount =
                subprocessData['result']?['counts']?['processed_counts'] ?? 1;
            int failureCount =
                subprocessData['result']?['counts']?['unprocessed_counts'] ?? 0;
            int totalTasks = subprocessData['total_location_to_process'] ?? 1;
            int completedTasks = successCount;
            var typography = CustomTypography(context);

            // Define color variations for hover effect
            final Color collapsedColor = Theme.of(context)
                .hoverColor
                .withOpacity(0.1); // Main card hover color
            final Color expandedColor = Theme.of(context).hoverColor;
            final Color expandedColor2 = Theme.of(context)
                .hoverColor; // Darker hover color for expanded section

            return ExpansionTile(
              maintainState: true,
              showTrailingIcon: false,
              tilePadding: EdgeInsets.all(0),
              title: SizedBox(
                height: cardHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column to hold the "+" icon and dotted line
                      Column(
                        children: [
                          Icon(
                              expandedSubprocess[subprocessName] ?? false
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              color: Colors.grey),
                          // "+" icon
                          CustomPaint(
                            size: Size(1, cardHeight - 40),
                            // Adjust height as needed
                            painter: DottedLinePainter(),
                          ),
                        ],
                      ),
                      SizedBox(width: 16), // Space between the line and content

                      // Main Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(
                              subprocessId,
                              style: typography.Body1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: completedTasks / totalTasks,
                                    minHeight: 4,
                                    backgroundColor: Colors.grey[300],
                                    color: AppColors.primaryMain,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '$completedTasks/$totalTasks',
                                  style: typography.Subtitle2.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    subprocessName,
                                  ),
                                  backgroundColor:
                                      AppColors.primaryMain.withOpacity(0.2),
                                  //.withOpacity(0.5),//AppColors.hover,
                                  labelStyle: typography.Body1.copyWith(
                                    color: AppColors.primaryMain,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildIconWithCount(Icons.check_circle,
                                        Colors.green, successCount),
                                    SizedBox(width: 8),
                                    _buildIconWithCount(Icons.error_outline,
                                        Colors.red, totalTasks - successCount),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onExpansionChanged: (isExpanded) {
                setState(() {
                  expandedSubprocess[subprocessName] = isExpanded;
                });
              },
              children: [
                Container(
                  color: expandedColor,
                  child: Container(
                    color: expandedColor,
                    child: Card(
                      margin: EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(0)),
                      ),
                      color: expandedColor,
                      // Use darker hover color for expanded content
                      child: _buildTasks(subprocessData),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTasks(Map<String, dynamic> subprocessData) {
    var typography = CustomTypography(context);

    // Access different keys directly from the API response
    var assetUploadData = subprocessData['asset_upload'];
    var boundaryData =
        subprocessData['boundary'] as Map<String, dynamic>? ?? {};
    var hazardData =
        subprocessData['hazard_file'] as Map<String, dynamic>? ?? {};
    var hazardScore =
        subprocessData['hazard_score'] as Map<String, dynamic>? ?? {};
    var overallData = subprocessData['overall_score'];
    var scoreData = subprocessData['total_score_counts'];

    return ListView(
      physics: ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        // Geocoding Task (placeholder for now)
        _buildTaskCard(
          geeTaskID: 'GEE-TaskID: '+assetUploadData?['task_id'] ?? "",
          taskName: "Geocoding",
          description: "",
          successCount:
          subprocessData['result']?['counts']?['processed_counts'] ?? 0,
          failureCount:
          subprocessData['result']?['counts']?['processed_counts'] ?? 0,
          typography: typography,
          status: subprocessData['status'] ?? '',
        ),

        // Asset Upload Task
        if (assetUploadData != null)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: '+assetUploadData['task_id'],
            taskName: "Asset Upload",
            description: "",
            successCount: assetUploadData['processed'] ?? 0,
            failureCount: assetUploadData['unprocessed'] ?? 0,
            typography: typography,
            scoreData: scoreData,
            status: (subprocessData['asset_upload_status'] ?? false)
                ? 'completed'
                : 'in progress',
          ),

        // Boundary Intersection Tasks
        for (var entry in boundaryData.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: '+entry.key,
            taskName: "Boundary Intersection",
            description:
                "${entry.value['vendor_name']}/${entry.value['hazard_name']}",
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
          ),

        // Hazard Tasks
        for (var entry in hazardData.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: '+entry.key,
            taskName: "Hazard",
            description:
                "${entry.value['vendor_name']}/${entry.value['hazard_name']}",
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
          ),

        // Hazard Score Tasks
        for (var entry in hazardScore.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: '+entry.key.toString(),
            taskName: "Hazard Score",
            description: (entry.value['vendor_name'] is String
                    ? entry.value['vendor_name']
                    : entry.value['vendor_name'] is List &&
                            entry.value['vendor_name'].isNotEmpty
                        ? entry.value['vendor_name'][0]
                        : 'Unknown Vendor') +
                '/' +
                (entry.value['hazard_name'] ?? 'Unknown Hazard'),
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
          ),

        // Overall Task
        if (overallData != null)
          _buildTaskCard(
            geeTaskID: subprocessData['payload']['subtask_id'],
            taskName: "Overall Score",
            description: "",
            successCount: overallData['processed'] ?? 0,
            failureCount: overallData['unprocessed'] ?? 0,
            typography: typography,
            scoreData: scoreData,
            status: overallData['score']['status']??'READY',
          ),

        // Score and Overall Score
        if (scoreData != null) _buildScoreSection(scoreData, typography),
      ],
    );
  }

  Widget _buildTaskCard({
    required String taskName,
    required String description,
    required int successCount,
    required int failureCount,
    required CustomTypography typography,
    Map<String, dynamic>? scoreData,
    required geeTaskID,
    required String status,
  }) {
    print(
        "TaskName: $taskName, Description: $description, SuccessCount: $successCount, FailureCount: $failureCount, GeeTaskID: $geeTaskID, Status: $status");
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).hoverColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$geeTaskID",
              style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(taskName,
                        style: typography.Body2.copyWith(color: getStatusColor(context, status))),
                    Text(
                      'Status: ${_getStatusText(status)}',
                      style: typography.Body2.copyWith(
                          color: getStatusColor(context, status)),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          description,
                          style: typography.Body2.copyWith(
                              color: Colors.grey[500]),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      if (taskName.toLowerCase() != 'geocoding')
                        if (status.toLowerCase() == 'completed')
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child:
                                Icon(Icons.check_circle, color: Colors.green),
                          ),
                      if (status.toLowerCase() != 'completed')
                        Lottie.asset('assets/lottie/loading.json',
                            height: 24, width: 24),
                      if (taskName.toLowerCase() == 'geocoding')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildIconWithCount(
                                Icons.check_circle, Colors.green, successCount),
                            SizedBox(width: 4),
                            _buildIconWithCount(
                                Icons.error_outline, Colors.red, failureCount),
                          ],
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
    );
  }

  Widget _buildScoreSection(
      Map<String, dynamic> scoreData, CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score:',
            style: typography.Body2.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('1 Star: ${scoreData["1"] ?? 0}', style: typography.Body2),
        Text('2 Stars: ${scoreData["2"] ?? 0}', style: typography.Body2),
        Text('3 Stars: ${scoreData["3"] ?? 0}', style: typography.Body2),
        Text('4 Stars: ${scoreData["4"] ?? 0}', style: typography.Body2),
        Text('5 Stars: ${scoreData["5"] ?? 0}', style: typography.Body2),
      ],
    );
  }

  Color getStatusColor(BuildContext context, String? status) {
    switch (status) {
      case 'failed':
      case 'cancelled':
      case 'FAILED':
      case 'CANCELLED':
        return Colors.red;
      case 'in_progress':
      case 'inprogress':
      case 'RUNNING':
        return Colors.yellow;
      case 'completed':
      case 'compleated':
        case 'COMPLETED':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  _getStatusText(String status) {
    switch (status) {
      case 'failed':
      case 'FAILED':
        return 'Failed';
      case 'in_progress':
      case 'inprogress':
      case 'RUNNING':
        return 'In Progress';
      case 'completed':
      case 'compleated':
      case 'COMPLETED':
        return 'Completed';
      case 'cancelled':
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;
    var max = size.height;
    var dashWidth = 4;
    var dashSpace = 4;
    double startY = 0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
