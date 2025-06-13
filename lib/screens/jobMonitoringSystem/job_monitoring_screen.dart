import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:RiskSphere/design_system/primitives/app_colors.dart';
import 'package:RiskSphere/design_system/primitives/custom_typography.dart';
import 'package:RiskSphere/screens/listings/my_location_list.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../providers/job_monitoring_provier.dart';
import 'maintainance_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class JobMonitoringDashboard extends StatefulWidget {
  final String? initialProcessId; // New parameter to receive process ID

  const JobMonitoringDashboard({Key? key, this.initialProcessId})
      : super(key: key);

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

  bool isProcessSummaryOpen = false; // For Process Summary
  bool isSubProcessSummaryOpen = false; // For Sub-Process Summary
  String selectedSubProcessId =
      ""; // To track which sub-process summary is open
  String selectedProcessId = ""; // To track which process summary is open

  bool isTaskSummaryOpen = false;
  String selectedTaskId = '';
  String selectedTaskType = '';
  Map<String, dynamic>? taskSummaryData;

  Map<String, dynamic>? jobSummaryData;

  Map<String, dynamic> jobData = {};

  ScrollController _scrollController = ScrollController();
  GlobalKey _expansionTileKey = GlobalKey();

  String accountId = '';
  String accountName = '';
  String subAccountId = '';
  String subAccountName = '';

  @override
  void initState() {
    super.initState();

    // Initialize the JobMonitoringProvider and fetch the company IDs
    Provider.of<JobMonitoringProvider>(context, listen: false)
        .fetchCompanyIds()
        .then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (widget.initialProcessId != null) {
          _scrollToProcess(widget.initialProcessId!);
          var provider =
              Provider.of<JobMonitoringProvider>(context, listen: false);
          Map<String, dynamic>? summaryData =
              await provider.fetchSummary(widget.initialProcessId!);

          if (mounted) {
            // Always check if the widget is still mounted
            setState(() {
              if (summaryData != null) {
                jobSummaryData = summaryData;
              } else {
                //SnackBar(content: Text('Failed to fetch summary', style: typography.Body1.copyWith(color: Colors.white)));

                isProcessSummaryOpen = false; // Close summary if API fails
              }
            });
          }
        }
      });
    });
  }

  void _scrollToProcess(String processId) {
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        selectedProcessId = processId;
        isProcessSummaryOpen = true;
      });

      RenderBox? box =
          expansionTileKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        _scrollController.animateTo(
          _scrollController.offset + box.localToGlobal(Offset.zero).dy - 100,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
                opacity: 0.3,
                // Change this value to set the desired opacity (0.0 to 1.0)
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
                      stream: jobMonitoringProvider.getJobMonitoringData( accountId,subAccountId),
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
                            jobData =
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
    required dynamic jobData,
  }) {
    print('Job data: $jobData');
    var typography = CustomTypography(context);

    // Define color variations for hover effect
    final Color collapsedColor =
        Theme.of(context).hoverColor.withOpacity(0.1); // Main card hover color
    final Color expandedColor = Theme.of(context).hoverColor;
    final Color expandedColor2 =
        Theme.of(context).hoverColor; // Darker hover color for expanded section

    // If the summary is open, replace the card with summary UI
    if (isProcessSummaryOpen && selectedProcessId == jobId) {
      return _buildProcessSummary(jobSummaryData ?? {});
    }
    // If the summary is open, replace the card with summary UI
    if (isSubProcessSummaryOpen && selectedProcessId == jobId) {
      return _buildSubProcessSummary(jobSummaryData ?? {}, selectedProcessId);
    }

    if (isTaskSummaryOpen && selectedProcessId == jobId) {
      return _buildTaskSummary(taskSummaryData ?? {}, selectedTaskType);
    }

    return Card(
      key: jobId == widget.initialProcessId ? expansionTileKey : null,
      color: collapsedColor,
      // Main card hover color
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
                      Tooltip(
                        message: jobId,
                        child:
                        Text(
                          (jobData["process_name"] is Map)
                              ? jobData["process_name"]["filename"].toString()
                              : jobData["process_name"]?.toString() ?? "Process",
                          style: typography.Body1.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Text(
                        //   jobData["process_name"]?["filename"].toString() ?? "Process",
                        //   style: typography.Body1.copyWith(
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
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
                IconButton(
                  icon: SvgPicture.asset('assets/images/contract.svg'),
                  onPressed: () async {
                    setState(() {
                      selectedProcessId = jobId;
                      isProcessSummaryOpen = true; // Open summary view
                    });
                    var provider = Provider.of<JobMonitoringProvider>(context,
                        listen: false);
                    Map<String, dynamic>? summaryData =
                        await provider.fetchSummary(selectedProcessId);

                    if (mounted) {
                      // Always check if the widget is still mounted
                      setState(() {
                        if (summaryData != null) {
                          jobSummaryData = summaryData;
                        } else {
                          SnackBar(
                              content: Text('Failed to fetch summary',
                                  style: typography.Body1.copyWith(
                                      color: Colors.white)));

                          isProcessSummaryOpen =
                              false; // Close summary if API fails
                        }
                      });
                    }
                  },
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
                        _buildFormattedDate(jobData['created_at']),
                        SizedBox(height: 4),
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

  Widget _buildFormattedDate(dynamic timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    // Convert Timestamp to DateTime
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      dateTime = timestamp.toDate(); // Firestore Timestamp -> DateTime
    }

    // Format the date in your desired style
    String formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    var typography = CustomTypography(context);
    return Text(formattedDate,
        style: typography.Body2.copyWith(
          color: AppColors.primaryMain,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end);
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
    var unsortedSubprocesses =
        jobData['subprocesses'] as Map<String, dynamic>? ?? {};
    print('Unsorted subprocesses are: $unsortedSubprocesses');
    var subprocesses =
        Map<String, dynamic>.fromEntries(unsortedSubprocesses.entries.toList()
          ..sort((a, b) {
            // Ensure a.value and b.value are maps and contain the key 'sub_process_name'
            if (a.value is Map &&
                b.value is Map &&
                a.value.containsKey('sub_process_name') &&
                b.value.containsKey('sub_process_name')) {
              var subProcessNameA =
                  getSubProcessName(a.value['sub_process_name']);
              var subProcessNameB =
                  getSubProcessName(b.value['sub_process_name']);

              // Extract the numerical part from the 'sub_process_name'
              RegExp regex = RegExp(r'(\d+)$');
              var matchA = regex.firstMatch(subProcessNameA);
              var matchB = regex.firstMatch(subProcessNameB);

              // Convert the numerical part to an integer for comparison
              int numberA = matchA != null ? int.parse(matchA.group(0)!) : 0;
              int numberB = matchB != null ? int.parse(matchB.group(0)!) : 0;

              // First compare the base part of the name (without numbers), then compare the numbers
              int stringCompare = subProcessNameA
                  .replaceAll(RegExp(r'\d+$'), '')
                  .compareTo(subProcessNameB.replaceAll(RegExp(r'\d+$'), ''));

              // If the base names are the same, compare the numerical part
              if (stringCompare == 0) {
                return numberA.compareTo(numberB);
              }
              return stringCompare;
            }

            // If the structure doesn't match the expected type, just return 0 (no sorting change)
            return 0;
          }));

    print('Subprocesses are: $subprocesses');

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
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
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
                      SizedBox(width: 8), // Space between the line and content

                      // Main Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Tooltip(
                              message: subprocessId,
                              child: Text(
                                subprocessName,
                                style: typography.Body1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                                SizedBox(width: 22),
                                Text(
                                  '$completedTasks/$totalTasks',
                                  style: typography.Subtitle2.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                /*Chip(
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
                                ),*/
                                Row(
                                  children: [
                                    _buildIconWithCount(Icons.check_circle,
                                        Colors.green, successCount),
                                    SizedBox(width: 4),
                                    _buildIconWithCount(Icons.error_outline,
                                        Colors.red, totalTasks - successCount),
                                  ],
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                IconButton(
                                  icon: SvgPicture.asset(
                                      'assets/images/contract.svg'),
                                  onPressed: () async {
                                    setState(() {
                                      isSubProcessSummaryOpen =
                                          true; // Open summary view
                                      selectedSubProcessId = subprocessId;
                                      selectedProcessId = jobData['id'];
                                    });

                                    /* var provider = Provider.of<JobMonitoringProvider>(context, listen: false);
                                    print('Job id: ${jobData['id']}');
                                    Map<String, dynamic>? summaryDataLocal = await provider.fetchSummary(jobData['id']);
                                    print('Summary data: $summaryDataLocal');

                                    if (mounted) { // Always check if the widget is still mounted
                                      setState(() {
                                        if (summaryDataLocal != null) {
                                          jobData = summaryDataLocal;
                                          debugPrint('Selected subprocessId: $subprocessId');
                                          debugPrint('Available subprocess keys: ${summaryDataLocal['result']['subprocesses']?.keys}');

                                        } else {
                                          SnackBar(content: Text('Failed to fetch summary', style: typography.Body1.copyWith(color: Colors.white)));

                                          isProcessSummaryOpen = false; // Close summary if API fails
                                        }
                                      });
                                    }*/

                                    var provider =
                                        Provider.of<JobMonitoringProvider>(
                                            context,
                                            listen: false);
                                    Map<String, dynamic>? summaryData =
                                        await provider
                                            .fetchSummary(jobData['id']);

                                    if (mounted) {
                                      // Always check if the widget is still mounted
                                      setState(() {
                                        if (summaryData != null) {
                                          jobSummaryData = summaryData;
                                        } else {
                                          SnackBar(
                                              content: Text(
                                                  'Failed to fetch summary',
                                                  style:
                                                      typography.Body1.copyWith(
                                                          color:
                                                              Colors.white)));

                                          isSubProcessSummaryOpen =
                                              false; // Close summary if API fails
                                        }
                                      });
                                    }
                                  },
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
                      child: _buildTasks(
                          subprocessData, jobData['id'], subprocessId),
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

  String getSubProcessName(dynamic value) {
    if (value is String) return value;
    print('Unexpected type for sub_process_name: ${value.runtimeType}');
    return 'Location Set 0';
  }

  Widget _buildTasks(Map<String, dynamic> subprocessData, String processId,
      String subprocessId) {
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
          geeTaskID: 'GEE-TaskID: ' + (assetUploadData?['task_id'] ?? ""),
          taskName: "Geocoding",
          description: "",
          successCount:
              subprocessData['result']?['counts']?['processed_counts'] ?? 0,
          failureCount:
              subprocessData['result']?['counts']?['processed_counts'] ?? 0,
          typography: typography,
          status: subprocessData['status'] ?? '',
          processId: processId ?? "",
          subProcessId: subprocessId ?? "",
        ),

        // Asset Upload Task
        if (assetUploadData != null)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: ' + (assetUploadData['task_id'] ?? ""),
            taskName: "Asset Upload",
            description: "",
            successCount: assetUploadData['processed'] ?? 0,
            failureCount: assetUploadData['unprocessed'] ?? 0,
            typography: typography,
            scoreData: scoreData,
            status: (subprocessData['asset_upload_status'] ?? false)
                ? 'completed'
                : 'in progress',
            processId: processId ?? "",
            subProcessId: subprocessId ?? "",
          ),

        // Boundary Intersection Tasks
        for (var entry in boundaryData.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: ' + entry.key,
            taskName: "Boundary Intersection",
            description:
                "${entry.value['vendor_name']}/${entry.value['hazard_name']}",
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
            processId: processId ?? "",
            subProcessId: subprocessId ?? "",
          ),

        // Hazard Tasks
        for (var entry in hazardData.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: ' + entry.key,
            taskName: "Hazard",
            description:
                "${entry.value['vendor_name']}/${entry.value['hazard_name']}",
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
            processId: processId ?? "",
            subProcessId: subprocessId ?? "",
          ),

        // Hazard Score Tasks
        for (var entry in hazardScore.entries)
          _buildTaskCard(
            geeTaskID: 'GEE-TaskID: ' + entry.key.toString(),
            taskName: "Hazard Score",
            description: (entry.value['vendor_name'] is String
                    ? entry.value['vendor_name']
                    : entry.value['vendor_name'] is List &&
                            entry.value['vendor_name'].isNotEmpty
                        ? entry.value['vendor_name'][0]
                        : 'Unknown Vendor') +
                '/' +
                (entry.value['hazard_name'] ?? ''),
            successCount: entry.value['processed'] ?? 0,
            failureCount: entry.value['unprocessed'] ?? 0,
            typography: typography,
            status: entry.value['status'],
            processId: processId ?? "",
            subProcessId: subprocessId ?? "",
          ),

        // Overall Task
        if (overallData != null)
          _buildTaskCard(
            geeTaskID: subprocessData['payload']?['subtask_id'] ?? "",
            taskName: "Overall Score",
            description: "",
            successCount: overallData['processed'] ?? 0,
            failureCount: overallData['unprocessed'] ?? 0,
            typography: typography,
            scoreData: scoreData,
            status: overallData['score']['status'] ?? 'READY',
            processId: processId ?? "",
            subProcessId: subprocessId ?? "",
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
    required String processId,
    required String subProcessId,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                        style: typography.Body2.copyWith(
                            color: getStatusColor(context, status))),
                    Text(
                      'Status: ${_getStatusText(status)}',
                      style: typography.Body2.copyWith(
                          color: getStatusColor(context, status)),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
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
                          Lottie.asset(
                            'assets/lottie/loading.json',
                            height: 24,
                            width: 24,
                          ),
                        if (taskName.toLowerCase() == 'geocoding')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildIconWithCount(Icons.check_circle,
                                  Colors.green, successCount),
                              SizedBox(width: 2),
                              _buildIconWithCount(Icons.error_outline,
                                  Colors.red, failureCount),
                            ],
                          ),
                        IconButton(
                          icon: SvgPicture.asset('assets/images/contract.svg'),
                          onPressed: () async {
                            setState(() {
                              isTaskSummaryOpen = true;
                              selectedTaskId =
                                  geeTaskID.replaceAll('GEE-TaskID: ', '');
                              selectedProcessId = processId;
                              selectedSubProcessId = subProcessId;
                              selectedTaskType = taskName;
                            });

                            var provider = Provider.of<JobMonitoringProvider>(
                                context,
                                listen: false);
                            Map<String, dynamic>? summaryData =
                                await provider.fetchSummary(selectedProcessId);

                            if (mounted) {
                              setState(() {
                                if (summaryData != null) {
                                  taskSummaryData = summaryData;
                                } else {
                                  isTaskSummaryOpen = false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to fetch task summary')),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded(
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.end,
                //     children: [
                //       Expanded(
                //         child: Text(
                //           description,
                //           style: typography.Body2.copyWith(
                //               color: Colors.grey[500]),
                //           textAlign: TextAlign.end,
                //         ),
                //       ),
                //       if (taskName.toLowerCase() != 'geocoding')
                //         if (status.toLowerCase() == 'completed')
                //           Padding(
                //             padding: const EdgeInsets.only(left: 8.0),
                //             child:
                //                 Icon(Icons.check_circle, color: Colors.green),
                //           ),
                //       if (status.toLowerCase() != 'completed')
                //         Lottie.asset('assets/lottie/loading.json',
                //             height: 24, width: 24),
                //       if (taskName.toLowerCase() == 'geocoding')
                //         Row(
                //           mainAxisAlignment: MainAxisAlignment.end,
                //           children: [
                //             _buildIconWithCount(
                //                 Icons.check_circle, Colors.green, successCount),
                //             SizedBox(width: 2),
                //             _buildIconWithCount(
                //                 Icons.error_outline, Colors.red, failureCount),
                //           ],
                //         ),
                //       // Summary icon for task (contract)
                //       IconButton(
                //         icon: SvgPicture.asset('assets/images/contract.svg'),
                //         onPressed: () async {
                //           setState(() {
                //             isTaskSummaryOpen = true;
                //             selectedTaskId = geeTaskID.replaceAll('GEE-TaskID: ', '');
                //             selectedProcessId = processId;
                //             selectedSubProcessId = subProcessId;
                //             selectedTaskType = taskName;
                //           });
                //
                //           var provider = Provider.of<JobMonitoringProvider>(context, listen: false);
                //           Map<String, dynamic>? summaryData = await provider.fetchSummary(selectedProcessId);
                //
                //           if (mounted) {
                //             setState(() {
                //               if (summaryData != null) {
                //                 taskSummaryData = summaryData;
                //               } else {
                //                 isTaskSummaryOpen = false;
                //                 ScaffoldMessenger.of(context).showSnackBar(
                //                   SnackBar(content: Text('Failed to fetch task summary')),
                //                 );
                //               }
                //             });
                //           }
                //         },
                //       ),
                //
                //
                //
                //
                //     ],
                //   ),
                // ),
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

  /// Summary
  Widget _buildProcessSummary(Map<String, dynamic>? summaryData) {
    if (summaryData == null || summaryData.isEmpty) {
      return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.all(16.0),
          padding: EdgeInsets.all(16.0),
          height: 200,
          child: Center(child: CircularProgressIndicator())); // Show loader
    }

    var typography = CustomTypography(context);
    final hazardVendorData =
        summaryData['result']?['hazard_vendor_score_summary'] ?? {};
    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child:
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Header
            ListTile(
              contentPadding: EdgeInsets.all(0),
              title: Row(
                children: [
                  SizedBox(width: 8),
                  Tooltip(
                    message: selectedProcessId,
                    child: Text(
                      "",
                      // summaryData?["result"]?['process_name'] ?? "Process",
                      style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Symbols.cancel, color: Colors.red),
                onPressed: () {
                  setState(() {
                    isProcessSummaryOpen = false; // Close summary view
                    jobSummaryData = null; // Clear data
                  });
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
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
                        Text('Total Locations', style: typography.Caption),
                        Text(
                          summaryData['result']?['total_locations']
                                  ?.toString() ??
                              '0',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildGeocodingStatus(
              totalLocations: summaryData['result']?['total_locations'] ?? 0,
              successfulLocations:
                  summaryData['result']?['location_processed'] ?? 0,
              failedLocations:
                  summaryData['result']?['location_unprocessed'] ?? 0,
              typography: CustomTypography(context),
              onDownloadPressed: () {
                // Handle download logic here
                print("Download link clicked!");
              },
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              child: Divider(),
            ),
            SizedBox(height: 8),

            _buildRunTimeSummary(summaryData['result']),
            SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              child: Divider(),
            ),
            SizedBox(height: 8),
            _buildDynamicGeoRatingSummary(summaryData),
            SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              child: Divider(),
            ),
            //_buildHazardSummary(summaryData),
            _buildHazardVendorSummary(hazardVendorData, typography),
            SizedBox(height: 8),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              child: Divider(),
            ),
            _buildUsageAndGEESummary(summaryData, typography, type: "process"),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Subprocess Summary
  Widget _buildSubProcessSummary(
      Map<String, dynamic>? summaryData, String subprocessId) {
    if (summaryData == null || summaryData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(16.0),
        padding: EdgeInsets.all(16.0),
        height: 200,
        child: Center(child: CircularProgressIndicator()), // Show loader
      );
    }

    var typography = CustomTypography(context);

    // Extract the subprocess data dynamically
    final subprocessData = summaryData['result']?['subprocesses']
        ?[selectedSubProcessId] as Map<String, dynamic>?;

    final hazardVendorData = Map<String, dynamic>.from(
        summaryData['result']?['hazard_vendor_score_summary'] ?? {});

    if (subprocessData == null) {
      return Container(
        margin: EdgeInsets.all(16.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Subprocess data not found.",
              style: typography.Body2.copyWith(color: Colors.red),
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                setState(() {
                  isSubProcessSummaryOpen = false; // Close summary view
                  jobSummaryData = null; // Clear data
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          ListTile(
            contentPadding: EdgeInsets.all(0),
            title: Row(
              children: [
                SizedBox(width: 8),
                Tooltip(
                  message: subprocessData['subtask_id'] ?? 'Subprocess ID',
                  child: Text(
                    subprocessData['sub_process_name'] ?? "Sub Process",
                    style: typography.Body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                setState(() {
                  isSubProcessSummaryOpen = false; // Close summary view
                  jobSummaryData = null; // Clear data
                });
              },
            ),
          ),

          // Chip Section: Sub Process
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text("Sub Process"),
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
                      Text('Total Locations', style: typography.Caption),
                      Text(
                        subprocessData['result']?['summary']?['total_locations']
                                ?.toString() ??
                            '0',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Geocoding Status
          _buildGeocodingStatus(
            totalLocations:
                subprocessData['result']?['summary']?['total_locations'] ?? 0,
            successfulLocations:
                subprocessData['result']?['counts']?['processed_counts'] ?? 0,
            failedLocations: 0,
            // Adjust as needed
            typography: typography,
            onDownloadPressed: () {
              print("Download link clicked for Sub Process!");
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),
          SizedBox(height: 8),

          // Runtime Summary
          if (subprocessData['result'] != null)
            _buildRunTimeSummary(subprocessData['result']),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),
          SizedBox(height: 8),

          // Dynamic Geo Rating Summary
          if (subprocessData['result'] != null)
            _buildDynamicGeoRatingSummary(subprocessData, isSubProcess: true),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),

          // Hazard Summary
          _buildHazardVendorSummary(hazardVendorData, typography),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(),
          ),

          // Usage and GEE Summary
          if (subprocessData['result'] != null)
            _buildUsageAndGEESummary(subprocessData, typography,
                type: "subprocess"),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGeocodingStatus({
    required int totalLocations,
    required int successfulLocations,
    required int failedLocations,
    required CustomTypography typography,
    required VoidCallback onDownloadPressed, // Callback for download link
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Section
        SizedBox(height: 8),
        InkWell(
          onTap: () {
            if (isProcessSummaryOpen) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MyLocationList(
                          accountID: accountId,
                          subAccountID: subAccountId,
                          accountName: accountName,
                          subAccountName: subAccountName,
                          initialProcessId: selectedProcessId,
                        )),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildStatusSection(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              message:
                  '$successfulLocations out of $totalLocations locations have been successfully geocoded.',
              typography: typography,
              hasTrailingArrow: true,
            ),
          ),
        ),
        SizedBox(height: 8),
        // Failure Section

        failedLocations != 0
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSection(
                      icon: Icons.error,
                      iconColor: Colors.red,
                      message:
                          '$failedLocations locations could not be processed by Geocoding.',
                      typography: typography,
                      hasTrailingArrow: false,
                    ),
                    _buildDownloadLink(
                      "Download and verify these locations",
                      typography,
                      onDownloadPressed,
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildStatusSection({
    required IconData icon,
    required Color iconColor,
    required String message,
    required CustomTypography typography,
    bool hasTrailingArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: typography.Body1,
            ),
          ),
          if (hasTrailingArrow)
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryMain,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadLink(
    String text,
    CustomTypography typography,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Text(
              text,
              style: typography.Body2.copyWith(
                color: AppColors.primaryMain,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryMain,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunTimeSummary(Map<String, dynamic> processData) {
    // Extract time data
    if (processData == null ||
        processData.isEmpty ||
        processData['geocode_starting_time'] == null ||
        processData['geocode_ending_time'] == null) {
      return const SizedBox.shrink();
    }
    String startedAt = _formatTimestamp(processData['geocode_starting_time']);
    String finishedAt = _formatTimestamp(processData['geocode_ending_time']);
    Duration totalRunTime =
        Duration(seconds: processData['total_time_taken'] ?? 0);
    Duration geocodingRunTime = Duration(
        seconds: processData['geocode_ending_time']['_seconds'] -
            processData['geocode_starting_time']['_seconds']);
    Duration hazardRunTime = totalRunTime - geocodingRunTime;

    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Start and End Times
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn('Started at', startedAt, typography),
                _buildTimeColumn('Finished at', finishedAt, typography),
              ],
            ),
          ),
          Divider(color: Colors.white12),
          SizedBox(height: 8),
          // Run Time Details
          _buildRunTimeRow(
              'Total Run Time', _formatDuration(totalRunTime), typography),
          _buildRunTimeRow('Geocoding Run Time',
              _formatDuration(geocodingRunTime), typography),
          _buildRunTimeRow(
              'Hazard Run Time', _formatDuration(hazardRunTime), typography),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
      String label, String time, CustomTypography typography) {
    return Column(
      crossAxisAlignment: label == 'Started at'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end, // Align 'Finished at' to the right
      children: [
        Text(label, style: typography.Caption),
        SizedBox(height: 4),
        Text(
          time,
          style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRunTimeRow(
      String label, String duration, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typography.Body2),
          Text(
            duration,
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Map<String, dynamic> timestamp) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    return "${dateTime.day.toString().padLeft(2, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-"
        "${dateTime.year.toString().substring(2)} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, '0');
  }

  Widget _buildDynamicGeoRatingSummary(Map<String, dynamic> apiData,
      {bool isSubProcess = false}) {
    Map<String, int> aggregatedScores = {
      "5": 0,
      "4": 0,
      "3": 0,
      "2": 0,
      "1": 0,
    };

    final result = apiData['result'];
    print('Result section: $result');

    if (result == null) {
      print('No "result" key found in apiData.');
      return _buildGeoRatingSummary(aggregatedScores);
    }

    if (isSubProcess) {
      final subprocesses = result['subprocesses'];
      print('Subprocesses: $subprocesses');

      if (subprocesses != null && subprocesses.isNotEmpty) {
        subprocesses.forEach((key, process) {
          final subScore = process['result']?['total_score_counts'];
          if (subScore != null) {
            subScore.forEach((rating, count) {
              aggregatedScores[rating] =
                  (aggregatedScores[rating] ?? 0) + (count as int);
            });
          }
        });
      } else {
        // Fallback to use direct result scores if no subprocesses are present
        print('No subprocess data, using direct scores from result.');
        final Map<String, dynamic> directScores =
            result['total_score_counts'] ?? {};
        directScores.forEach((rating, count) {
          aggregatedScores[rating] =
              (aggregatedScores[rating] ?? 0) + (count as int);
        });
      }
    } else {
      final Map<String, dynamic> topLevelScore =
          result['summary']?['score'] ?? {};
      topLevelScore.forEach((rating, count) {
        aggregatedScores[rating] = (count ?? 0).toInt();
      });
    }

    print('Final aggregated scores: $aggregatedScores');
    return _buildGeoRatingSummary(aggregatedScores);
  }

  Widget _buildGeoRatingSummary(Map<String, dynamic> ratings) {
    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Geo Rating Summary",
              style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Grid Layout for Star Ratings
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row for 5 Star and 4 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(
                          "5 Star Locations", ratings['5'] ?? 0, typography)),
                  SizedBox(width: 8), // Spacing between the two cards
                  Expanded(
                      child: _buildRatingCard(
                          "4 Star Locations", ratings['4'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8), // Spacing between rows

              // Row for 3 Star and 2 Star Locations
              Row(
                children: [
                  Expanded(
                      child: _buildRatingCard(
                          "3 Star Locations", ratings['3'] ?? 0, typography)),
                  SizedBox(width: 8),
                  Expanded(
                      child: _buildRatingCard(
                          "2 Star Locations", ratings['2'] ?? 0, typography)),
                ],
              ),
              SizedBox(height: 8),

              // Single expanded row for 1 Star Locations
              _buildRatingCard(
                  "1 Star Locations", ratings['1'] ?? 0, typography),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard(
      String title, int count, CustomTypography typography) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.4,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.Body2,
          ),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: typography.Body1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardVendorSummary(
      Map<dynamic, dynamic> hazardVendorData, CustomTypography typography) {
    if (hazardVendorData.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Hazard Rating Summary",
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ...hazardVendorData.keys.map((hazard) {
          final vendors = hazardVendorData[hazard] as Map<String, dynamic>;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).hoverColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    hazard,
                    style: typography.Body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),*/
                ...vendors.keys.map((vendor) {
                  final scores = vendors[vendor] as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          "$hazard ($vendor)",
                          style: typography.Body2.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _buildHazardDetailRow(
                          "Locations with Score",
                          scores.entries
                              .where((entry) => entry.key != "None")
                              .map((entry) {
                                final value = entry.value;
                                if (value is int) {
                                  return value;
                                } else if (value is Map<String, dynamic>) {
                                  return value.values.fold(
                                      0, (prev, next) => prev + (next as int));
                                } else {
                                  return 0; // Fallback to 0 if neither int nor map
                                }
                              })
                              .fold(0, (prev, next) => prev + next)
                              .toString(),
                          typography,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _buildHazardDetailRow(
                          "Locations without Score",
                          scores['None']?.toString() ?? "0",
                          typography,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(),
                      ),
                      ExpansionTile(
                        tilePadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        trailing: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).disabledColor,
                        ),
                        initiallyExpanded: false,
                        title: Text(
                          "Hazard Risk Score Wise Locations",
                          style: typography.Body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: _buildHazardRiskScores(scores, typography),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHazardDetailRow(
      String label, String value, CustomTypography typography) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: typography.Body2),
        Text(
          value,
          style: typography.Body1.copyWith(
            color: AppColors.primaryMain,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildHazardRiskScores(Map<String, dynamic> scores, typography) {
    final riskScores = [
      {"label": "No impact", "key": "5", "color": Colors.green, "star": "★"},
      {
        "label": "Low impact",
        "key": "4",
        "color": Colors.lightGreen,
        "star": "★"
      },
      {
        "label": "Medium impact",
        "key": "3",
        "color": Colors.yellow,
        "star": "★"
      },
      {"label": "High impact", "key": "2", "color": Colors.orange, "star": "★"},
      {"label": "Severe impact", "key": "1", "color": Colors.red, "star": "★"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: riskScores.map((score) {
        final count = scores[score['key']]?.toString() ?? "0";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${score['key']}   ",
                      style: typography.Body2,
                    ),
                    TextSpan(
                      text: "${score['star']!}",
                      style: typography.Body2.copyWith(
                        color: score['color'] as Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: score['key'] == 1
                          ? " (${score['label']})"
                          : " (${score['label']})",
                      style: typography.Body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                count,
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w300,
                  color: AppColors.primaryMain,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// Helper function to return color based on score
  Color _getScoreColor(String scoreKey) {
    switch (scoreKey) {
      case "5":
        return Colors.green;
      case "4":
        return Colors.lightGreen;
      case "3":
        return Colors.yellow;
      case "2":
        return Colors.orange;
      case "1":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUsageAndGEESummary(
      Map<String, dynamic> apiData, CustomTypography typography,
      {required String type}) {
    if (apiData.isEmpty || apiData['result'] == null) {
      return const SizedBox.shrink();
    }

    final result = type == "process"
        ? apiData['result']
        : apiData['result']?['subprocesses'];
    if (result == null) return const SizedBox.shrink();

    // Extract dynamic keys and data
    final totalProcessesCompleted =
        result['total_processes_completed']?.toString() ?? "0";
    final totalTimeElapsed =
        result['total_time_elapsed_in_earth_engine']?.toString() ?? "0";
    final assetIngestionTime =
        _formatTime(result['asset_upload_summary']?['time_taken'] ?? 0.0);

    // Fetch hazard file summary dynamically
    final hazardFileKey = result['hazard_file_summary']?.keys?.first ?? "";
    final hazardProcessingTime = _formatTime(
        result['hazard_file_summary']?[hazardFileKey]?['time_taken'] ?? 0.0);

    // Calculate Wait Time
    final totalWaitTime = _formatTime(
      (result['total_time_taken'] ?? 0.0) -
          (result['asset_upload_summary']?['time_taken'] ?? 0.0) -
          (result['hazard_file_summary']?[hazardFileKey]?['time_taken'] ?? 0.0),
    );

    final usageSummary = {
      "Number of Batch Process": totalProcessesCompleted,
      "Number of GEE Process": totalTimeElapsed,
    };

    final geeSummary = {
      "Asset Ingestion Time": assetIngestionTime,
      "Hazard Processing Time": hazardProcessingTime,
      "Wait Time": totalWaitTime,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              _buildSummarySection("Usage Summary", usageSummary, typography),
        ),
        const SizedBox(height: 8),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildSummarySection("GEE Summary", geeSummary, typography),
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, Map<String, String> summaryData,
      CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: summaryData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: typography.Body2),
                    Text(entry.value,
                        style: typography.Body1.copyWith(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w300,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Utility function to convert seconds into HH:MM:SS format
  String _formatTime(double seconds) {
    int hours = (seconds ~/ 3600);
    int minutes = ((seconds % 3600) ~/ 60);
    int secs = (seconds % 60).toInt();
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Widget _buildTaskSummary(Map<String, dynamic> taskData, String taskType) {
    var typography = CustomTypography(context);

    if (taskSummaryData == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.all(16.0),
        padding: EdgeInsets.all(16.0),
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (taskSummaryData!.isEmpty) {
      return _buildEmptyTaskMessage(typography);
    }

    log('Task Data: ${jsonEncode(taskData)}');
    var selectedTaskData =
        taskData['result']?['subprocesses']?[selectedSubProcessId] ?? taskData;

    String taskName = selectedTaskData['sub_process_name'] ?? 'Task';
    String taskID = selectedTaskData['subtaskid'] ?? 'Task ID';
    int totalLocations = selectedTaskData['total_location_to_process'] ?? 0;
    int processedLocations =
        selectedTaskData['result']?['counts']?['processed_counts'] ?? 0;

    Widget taskSpecificSection =
        _buildTaskSpecificSection(taskType, selectedTaskData, typography);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskHeader(
              taskName, taskID, typography, totalLocations, taskType),
          taskSpecificSection,
          Divider(),
          _buildRunTimeSummary(selectedTaskData),
        ],
      ),
    );
  }

  Widget _buildEmptyTaskMessage(CustomTypography typography) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Task data not found.",
            style: typography.Body2.copyWith(color: Colors.red),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              setState(() {
                isTaskSummaryOpen = false;
                taskSummaryData = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSpecificSection(String taskType,
      Map<String, dynamic> taskData, CustomTypography typography) {
    switch (taskType.toLowerCase()) {
      case 'geocoding':
        int totalLocations = taskData['total_location_to_process'] ?? 0;
        int processedLocations =
            taskData['result']?['counts']?['processed_counts'] ?? 0;
        int failedLocations = totalLocations - processedLocations;

        DateTime? startTime = taskData['start_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                taskData['start_time']['_seconds'] * 1000)
            : null;

        DateTime? endTime = taskData['end_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                taskData['end_time']['_seconds'] * 1000)
            : null;

        Duration runTime = (startTime != null && endTime != null)
            ? endTime.difference(startTime)
            : Duration.zero;

        double avgTimePerLoc = totalLocations > 0
            ? (runTime.inSeconds / totalLocations).toDouble()
            : 0;

        Map<String, dynamic> ratings = taskData['result']
                ?['total_score_counts'] ??
            {"5": 0, "4": 0, "3": 0, "2": 0, "1": 0};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geocoding Status Section
            _buildGeocodingStatus(
              totalLocations: totalLocations,
              successfulLocations: processedLocations,
              failedLocations: failedLocations,
              typography: typography,
              onDownloadPressed: () {
                // Handle download
              },
            ),
            Divider(),

            _buildRunTimeSummaryGeocodingTask(taskData),
            Divider(),
            SizedBox(height: 16),

            // Rating Summary
            _buildGeoRatingSummary(ratings),
          ],
        );

      case 'asset upload':
        return _buildAssetUploadStatus(taskData, typography);

      case 'boundary intersection':
        return _buildBoundaryIntersectionStatus(taskData, typography);

      case 'hazard':
        return _buildHazardProcessingStatus(
            taskData, selectedTaskId, typography);

      case 'hazard score':
        return _buildHazardScoreStatus(taskData, typography);

      default:
        return Text('Unknown Task Type', style: typography.Body2);
    }
  }

  Widget _buildTaskHeader(String taskName, String taskID,
      CustomTypography typography, int totalLocations, String type) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.all(0),
          title: Row(
            children: [
              SizedBox(width: 4),
              Tooltip(
                message: taskID,
                child: Text(
                  taskName,
                  style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                isTaskSummaryOpen = false;
                taskSummaryData = null;
              });
            },
          ),
        ),
        // Chip Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // work case in name
            Chip(
              label: Text(type),
              backgroundColor: AppColors.primaryMain,
              labelStyle: typography.Body1.copyWith(color: AppColors.black),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Locations', style: typography.Caption),
                Text(
                  totalLocations.toString(),
                  style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssetUploadStatus(
      Map<String, dynamic> taskData, CustomTypography typography) {
    // Extract necessary data from asset_upload
    final assetUpload = taskData['asset_upload'] ?? {};
    String assetID =
        assetUpload['payload']?['properties']?['Name'] ?? 'Unknown';
    String status =
        assetUpload['status']?.toString().toLowerCase() ?? 'unknown';

    // Timestamps
    DateTime? createdAt = assetUpload['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            assetUpload['created_at']['_seconds'] * 1000)
        : null;

    DateTime? updatedAt = assetUpload['updated_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            assetUpload['updated_at']['_seconds'] * 1000)
        : null;

    DateTime? geeStartTime = assetUpload['usage']?['gee_starttime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            assetUpload['usage']?['gee_starttime'])
        : null;

    DateTime? geeUpdateTime = assetUpload['usage']?['gee_updatetime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            assetUpload['usage']?['gee_updatetime'])
        : null;

    // Calculate Run Time (if completed)
    Duration? runTime =
        (status == 'completed' && geeStartTime != null && geeUpdateTime != null)
            ? geeUpdateTime.difference(geeStartTime)
            : null;

    // Ingestion and Wait Time
    String geeIngestionTime =
        assetUpload['usage']?['gee_runtime']?.toStringAsFixed(1) ?? '---';
    String geeWaitTime =
        assetUpload['usage']?['gee_waittime']?.toStringAsFixed(1) ?? '---';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GEE Asset ID Section
        SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GEE Asset ID:",
                style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                assetID,
                style: typography.Body2.copyWith(color: AppColors.primaryMain),
              ),
            ],
          ),
        ),
        Divider(),

        // Started At and Finished At Section (Columns)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Started at',
                  _formatTimestamp(assetUpload['created_at']), typography),
              if (status == 'completed' && updatedAt != null)
                _buildTimeColumn('Finished at',
                    _formatTimestamp(assetUpload['updated_at']), typography),
            ],
          ),
        ),
        SizedBox(height: 8),
        Divider(),

        // Run Time Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildRunTimeRow(
            'Total Run Time',
            runTime != null ? _formatDuration(runTime) : "---",
            typography,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildRunTimeRow(
              'GEE Ingestion Time', '$geeIngestionTime sec', typography),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              _buildRunTimeRow('GEE Wait Time', '$geeWaitTime sec', typography),
        ),
      ],
    );
  }

  Widget _buildBoundaryIntersectionStatus(
      Map<String, dynamic> taskData, CustomTypography typography) {
    // Extract necessary data
    String assetID = taskData['boundary_processing_asset_id'] ?? 'Unknown';

    DateTime? startTime = taskData['boundary_process_start_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            taskData['boundary_process_start_time']['_seconds'] * 1000)
        : null;

    DateTime? endTime = taskData['boundary_process_end_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            taskData['boundary_process_end_time']['_seconds'] * 1000)
        : null;

    // Calculate Total Run Time
    Duration? runTime = (startTime != null && endTime != null)
        ? endTime.difference(startTime)
        : null;

    // Boundary Intersections
    List<String> foundLocations =
        List<String>.from(taskData['foundlocations'] ?? []);
    List<String> notFoundLocations =
        List<String>.from(taskData['nolocations'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GEE Asset ID Section
        SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GEE Asset ID:",
                style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                assetID,
                style: typography.Body2.copyWith(color: AppColors.primaryMain),
              ),
            ],
          ),
        ),
        Divider(),

        // Started At and Finished At Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn(
                  'Started at',
                  _formatTimestamp(taskData['boundary_process_start_time'] ?? "1561093593"),
                  typography),
              if (endTime != null)
                _buildTimeColumn(
                    'Finished at',
                    _formatTimestamp(taskData['boundary_process_end_time']?? "1561093593"),
                    typography),
            ],
          ),
        ),
        SizedBox(height: 8),
        Divider(),

        // Total Run Time Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildRunTimeRow(
            'Total Run Time',
            runTime != null ? _formatDuration(runTime) : "---",
            typography,
          ),
        ),

        SizedBox(height: 8),
        Divider(),

        // Boundary Intersections Found
        _buildBoundaryListSection(
            "Boundary Intersections Found", foundLocations, typography),

        // Boundary Intersections Not Found
        if (notFoundLocations.isNotEmpty)
          _buildBoundaryListSection("Boundary Intersections Not Found",
              notFoundLocations, typography),
      ],
    );
  }

// Helper Widget for Boundary Lists
  Widget _buildBoundaryListSection(
      String title, List<String> items, CustomTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: typography.Body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((location) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Text(location, style: typography.Body2),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRunTimeSummaryGeocodingTask(Map<String, dynamic> taskData) {
    if (taskData == null || taskData.isEmpty) {
      return const SizedBox.shrink();
    }

    log('RunTime Task Data: ${jsonEncode(taskData)}');

    // Fetch subprocess-specific data if available
    var selectedTaskData =
        taskData['result']?['subprocesses']?[selectedSubProcessId] ?? taskData;

    // Check for geocode_starting_time and geocode_ending_time within the subprocess
    if (selectedTaskData['start_time'] == null ||
        selectedTaskData['end_time'] == null) {
      print(
          "Geocoding start or end time not found for subprocess: $selectedSubProcessId");
      return const SizedBox.shrink();
    }

    // Extract times from subprocess block
    String startedAt = _formatTimestamp(selectedTaskData['start_time']);
    String finishedAt = _formatTimestamp(selectedTaskData['end_time']);

    // Calculate durations
    int startSeconds = selectedTaskData['start_time']['_seconds'] ?? 0;
    int endSeconds = selectedTaskData['end_time']['_seconds'] ?? 0;
    Duration geocodingRunTime = Duration(seconds: endSeconds - startSeconds);
    Duration totalRunTime = Duration(
        seconds: selectedTaskData['result']?['usage']?['runtime'] ?? 0);
    Duration averageTimePerLocation =
        totalRunTime ~/ (selectedTaskData['total_location_to_process'] ?? 1);

    var typography = CustomTypography(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Start and End Times
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn('Started at', startedAt, typography),
                _buildTimeColumn('Finished at', finishedAt, typography),
              ],
            ),
          ),
          Divider(color: Colors.white12),
          SizedBox(height: 8),
          // Run Time Details
          _buildRunTimeRow(
              'Total Run Time', _formatDuration(totalRunTime), typography),
          _buildTimeRow('Average Time Per Location',
              _formatDuration(averageTimePerLocation), typography),
        ],
      ),
    );
  }

  Widget _buildHazardProcessingStatus(Map<String, dynamic> taskData,
      String selectedTaskId, CustomTypography typography) {
    // Extract the selected hazard task
    final hazardTask = taskData['hazard_file']?[selectedTaskId] ?? {};

    String vendorName = hazardTask['vendor_name'] ?? 'Unknown';
    String hazardName = hazardTask['hazard_name'] ?? 'Unknown';
    String fileUrl =
        "https://storage.googleapis.com/project-green-f4d78.appspot.com/${hazardTask['csv_file_name'] ?? ''}";

    String status = hazardTask['status']?.toString().toLowerCase() ?? 'unknown';

    // Timestamps
    DateTime? createdAt = hazardTask['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            hazardTask['created_at']['_seconds'] * 1000)
        : null;

    DateTime? updatedAt = hazardTask['updated_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            hazardTask['updated_at']['_seconds'] * 1000)
        : null;

    // Calculate Total Run Time
    Duration? runTime =
        (status == 'completed' && createdAt != null && updatedAt != null)
            ? updatedAt.difference(createdAt)
            : null;

    // GEE Usage
    String geeRunTime =
        hazardTask['usage']?['gee_runtime']?.toStringAsFixed(1) ?? '---';
    String geeWaitTime =
        hazardTask['usage']?['gee_waittime']?.toStringAsFixed(1) ?? '---';

    //String fileSize = '5 mb'; // Assuming size for now, can add dynamically if available

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor and Hazard Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Vendor Name", style: typography.Caption),
              Text(
                vendorName,
                style: typography.Body1.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text("Hazard Name", style: typography.Caption),
              Text(
                hazardName,
                style: typography.Body1.copyWith(
                    color: AppColors.primaryMain, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text("Hazard Exported File URL:", style: typography.Caption),
              InkWell(
                onTap: () {
                  _launchURL(fileUrl);
                },
                child: Text(
                  fileUrl,
                  style: typography.Body2.copyWith(color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Divider(),

        // Started At and Finished At Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Started at',
                  _formatTimestamp(hazardTask['created_at']), typography),
              if (status == 'completed' && updatedAt != null)
                _buildTimeColumn('Finished at',
                    _formatTimestamp(hazardTask['updated_at']), typography),
            ],
          ),
        ),
        SizedBox(height: 8),
        Divider(),

        // Total Run Time Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildRunTimeRow(
            'Total Run Time',
            runTime != null ? _formatDuration(runTime) : "---",
            typography,
          ),
        ),

        // File Size, GEE Run, and Wait Time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              _buildRunTimeRow('GEE Run Time', '$geeRunTime sec', typography),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              _buildRunTimeRow('GEE Wait Time', '$geeWaitTime sec', typography),
        ),
      ],
    );
  }

  Widget _buildHazardScoreStatus(
      Map<String, dynamic> taskData, CustomTypography typography) {
    // Extract necessary data
    final hazardData = taskData['hazard_file']?[selectedTaskId] ?? {};
    String vendorName = hazardData['vendor_name'] ?? 'Unknown';
    String hazardName = hazardData['hazard_name'] ?? 'Unknown';
    String csvFileName = hazardData['csv_file_name'] ?? '';

    String fileUrl =
        'https://storage.googleapis.com/project-green-f4d78.appspot.com/$csvFileName';
    String status = hazardData['status']?.toString().toLowerCase() ?? 'unknown';

    // Timestamps
    DateTime? createdAt = hazardData['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            hazardData['created_at']['_seconds'] * 1000)
        : null;

    DateTime? updatedAt = hazardData['updated_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            hazardData['updated_at']['_seconds'] * 1000)
        : null;

    // Calculate Run Time
    Duration? runTime =
        (status == 'completed' && createdAt != null && updatedAt != null)
            ? updatedAt.difference(createdAt)
            : null;

    // Extract usage details
    String geeIngestionTime =
        hazardData['usage']?['gee_runtime']?.toStringAsFixed(1) ?? '---';
    String geeWaitTime =
        hazardData['usage']?['gee_waittime']?.toStringAsFixed(1) ?? '---';

    // Hazard score data
    final hazardScore =
        taskData['hazard_score']?[selectedTaskId]?['summary']?['rating'] ?? {};

    // Check if hazardScore has valid data
    bool hasValidScores = hazardScore.entries
        .where((entry) => entry.key != 'None')
        .map((entry) => entry.value)
        .whereType<int>()
        .any((value) => value > 0);

    bool allZeroScores = hazardScore.entries
        .where((entry) => ['1', '2', '3', '4', '5'].contains(entry.key))
        .map((entry) => entry.value)
        .whereType<int>()
        .every((value) => value == 0);

    // If no valid scores and all entries are zero, hide the expansion tile
    if (!hasValidScores || allZeroScores) {
      return _buildHazardProcessingStatus(taskData, selectedTaskId, typography);
    }

    // Build the UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHazardProcessingStatus(taskData, selectedTaskId, typography),

        // Hazard Score Section with Expansion Tile
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                child: Text(
                  "$hazardName ($vendorName)",
                  style: typography.Body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _buildHazardDetailRow(
                  "Locations with Score",
                  hazardScore.entries
                      .where((entry) => entry.key != "None")
                      .map((entry) => entry.value)
                      .fold(0, (prev, next) => prev + (next as int))
                      .toString(),
                  typography,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _buildHazardDetailRow(
                  "Locations without Score",
                  hazardScore['None']?.toString() ?? "0",
                  typography,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              ExpansionTile(
                initiallyExpanded: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Text(
                  "Hazard Risk Score Wise Locations",
                  style: typography.Body2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                children: [
                  _buildHazardRiskScores(hazardScore, typography),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(
      String label, String value, CustomTypography typography) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typography.Body2),
          Text(value,
              style: typography.Body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
