import '../../service/firestore_service.dart';
import '../../utils/global_imports.dart';
import 'package:async/async.dart';
import '../jobMonitoringSystem/job_monitoring_screen.dart';

class ProcessMonitoringScreen extends StatefulWidget {
  final String? accountId;
  final String? subAccountId;

  ProcessMonitoringScreen({super.key, this.accountId, this.subAccountId});

  @override
  State<ProcessMonitoringScreen> createState() =>
      _ProcessMonitoringScreenState();
}

class _ProcessMonitoringScreenState extends State<ProcessMonitoringScreen> {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  int count = 0;

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
                opacity: 0.3,
                // Change this value to set the desired opacity (0.0 to 1.0)
                child: Image.asset(
                  'assets/images/mesh.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Consumer<JobMonitoringProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                Stream<QuerySnapshot<Map<String, dynamic>>> stream;

                // if (provider.isSuperAdmin) {
                //   // Fetch all processes if the user is a super admin
                //   stream = FirebaseFirestore.instance
                //       .collection('processes')
                //       .orderBy('created_at', descending: true)
                //       .where('process_type', isEqualTo: 'hazard')
                //       .snapshots();
                // } else if (provider.docIds.isNotEmpty) {
                //   // Fetch processes filtered by company IDs
                //   print(
                //       'Fetching processes for ${provider.docIds.length} companies with IDs: ${provider.docIds}');
                //   stream = FirebaseFirestore.instance
                //       .collection('processes')
                //       .where('company_id', whereIn: provider.docIds)
                //       .where('process_type', isEqualTo: 'hazard')
                //       .orderBy('created_at', descending: true)
                //       .snapshots();
                // }

                stream = FirestoreService.db
                    .collection('processes')
                    .where('location_data.account_id',
                        isEqualTo: widget.accountId)
                    .where('location_data.sub_account_id',
                        isEqualTo: widget.subAccountId)
                    .where('process_type', isEqualTo: 'hazard')
                    .orderBy('created_at', descending: true)
                    .snapshots();

                // if() {
                //   // If there are no company IDs, show no processes
                //   return Center(child: Text('No processes available'));
                // }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return Center(child: Text('No processes available'));
                    }

                    print(
                        'StreamBuilder received ${snapshot.data!.docs.length} documents');
                    var processes = snapshot.data!.docs;

                    // Debug: Check if specific process exists before filtering
                    final processIds = processes.map((doc) => doc.id).toList();
                    print('Process IDs before filtering: $processIds');

                    // Optional filtering logic (if required)
                    // Uncomment and customize as needed
                    /* processes.removeWhere((element) {
          final data = element.data() as Map<String, dynamic>?;
          final subprocesses = data?['subprocesses'] as Map<String, dynamic>?;
          return subprocesses?.containsKey('heatmap') ?? false;
        }); */

                    // Debug: Check processes after filtering
                    final remainingProcessIds =
                        processes.map((doc) => doc.id).toList();
                    print('Process IDs after filtering: $remainingProcessIds');

                    return ListView.builder(
                      itemCount: processes.length,
                      itemBuilder: (context, index) {
                        var processData =
                            processes[index].data();

                        String processId =
                            processData['process_id'] ?? 'Unknown ID';
                        String companyName =
                            processData['location_data']?['account_name'] ?? '';
                        String ownerName = processData['owner_name'] ?? '';
                        int totalLocations =
                            processData['total_locations'] ?? 0;

                        var subProcesses = (processData['subprocesses'] as Map?)
                                ?.cast<String, dynamic>() ??
                            {};

                        return _buildProcessCard(
                          processId: (processData["process_name"] is Map)
                              ? processData["process_name"]["filename"]
                                  .toString()
                              : processData["process_name"]?.toString() ??
                                  processId,
                          companyName: companyName,
                          ownerName: ownerName,
                          totalLocations: totalLocations,
                          subProcesses: subProcesses,
                          typography: typography,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _fetchBatchedProcesses(
      List<String> docIds, int batchSize) {
    print('Total docIds: ${docIds.length}'); // Debug print
    final List<Stream<QuerySnapshot>> streams = [];

    for (int i = 0; i < docIds.length; i += batchSize) {
      final batch = docIds.sublist(
        i,
        i + batchSize > docIds.length ? docIds.length : i + batchSize,
      );

      print(
          'Processing batch ${i ~/ batchSize + 1} with ${batch.length} IDs'); // Debug print
      print('Batch IDs: $batch'); // Debug print

      streams.add(FirestoreService.db
          .collection('processes')
          .where(FieldPath.documentId, whereIn: batch)
          .snapshots()
          .map((snapshot) {
        print(
            'Batch ${i ~/ batchSize + 1} returned ${snapshot.docs.length} documents'); // Debug print
        return snapshot;
      }));
    }

    // Return merged stream with additional debug info
    return StreamGroup.merge(streams).map((snapshot) {
      print(
          'Merged snapshot has ${snapshot.docs.length} documents'); // Debug print
      return snapshot;
    });
  }

  // Build each process card with subprocesses inside as ExpansionTile
  Widget _buildProcessCard({
    required String processId,
    required String companyName,
    required String ownerName,
    required int totalLocations,
    required Map<String, dynamic> subProcesses,
    required CustomTypography typography,
  }) {
    print('Subprocesses: $subProcesses');
    if (processId == '9oJ02qpIilZJt0gOlr78') {
      print('Building card for process 9oJ02qpIilZJt0gOlr78');
      print(
          'Company Name: $companyName, Owner Name: $ownerName, Locations: $totalLocations');
      print('SubProcesses: $subProcesses');
    }
    // Sort the subprocesses by the 'sub_process_name'
    var sortedSubProcesses = subProcesses.entries.toList()
      ..sort((a, b) {
        // Ensure a.value and b.value are maps and contain the key 'sub_process_name'
        if (a.value is Map &&
            b.value is Map &&
            a.value.containsKey('sub_process_name') &&
            b.value.containsKey('sub_process_name')) {
          var subProcessNameA = getSubProcessName(a.value['sub_process_name']);
          var subProcessNameB = getSubProcessName(b.value['sub_process_name']);

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
      });
    if (processId == '9oJ02qpIilZJt0gOlr78') {
      print('Building card for process 9oJ02qpIilZJt0gOlr78');
      print(
          'Company Name: $companyName, Owner Name: $ownerName, Locations: $totalLocations');
      print('SubProcesses: $subProcesses');
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PID and Location details (displayed once for each process)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                  label: Text(
                    'PID',
                    style: typography.Caption,
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  )),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  processId,
                  style: typography.Body1.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      Text('My Locations', style: typography.Caption),
                      SizedBox(height: 16.0),
                      Text(companyName,
                          style: typography.Body1.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(ownerName, style: typography.Caption),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Chip(
                      label: Text('Locations', style: typography.Caption),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      )),
                  SizedBox(height: 8.0),
                  Text('$totalLocations',
                      style: typography.Body1.copyWith(
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.0),

          // Display subprocesses in the expansion tile

          Column(
            children: sortedSubProcesses.map<Widget>((entry) {
              count++;
              String locationSetId =
                  entry.key; // This is the key of the subprocesses

              // Check if entry.value is a Map<String, dynamic>, if not, skip the entry
              if (entry.value is! Map<String, dynamic>) {
                // Skip this iteration if the entry is not of the expected type
                return SizedBox
                    .shrink(); // You can return an empty widget or handle it accordingly
              }

              var locationSetData = entry.value as Map<String, dynamic>;
              String locationSetName = locationSetData['sub_process_name'] ??
                  'Location Set ${(totalLocations == 1) ? 1 : count}';
              var assetUploadStatus =
                  (locationSetData['asset_upload_status'] ?? false)
                      ? 'completed'
                      : 'in progress';
              var geocodingStatus = locationSetData['status'] ??
                  "pending"; // Placeholder as it is "yet to be made"
              var boundaryCount = locationSetData['boundary']?.length ?? 0;
              var boundaryProcessedCount =
                  _getProcessedCount(locationSetData['boundary']);
              var hazardCount = locationSetData['hazard_file']?.length ?? 0;
              var hazardProcessedCount =
                  _getProcessedCount(locationSetData['hazard_file']);
              var totalScore = convertToStringDynamicMap(
                  locationSetData['total_score_counts'] ?? {});
              var hazardScoreCount =
                  locationSetData['hazard_score']?.length ?? 0;
              var hazardScoreProcessedCount =
                  _getProcessedCount(locationSetData['hazard_score']);
              var overallScore = locationSetData['overall_score']?.length ?? 0;
              print('Overall Score Count: $overallScore');
              var overallScoreProcessedCount =
                  _getProcessedCount(locationSetData['overall']);
              print(
                  'Overall Score Processed Count: $overallScoreProcessedCount');
              var overallScoreStatus = locationSetData['overall_score']
                      ?["score"]?["status"] ??
                  "Pending";

              return _buildLocationSetCard(
                locationSetId: locationSetName,
                locationSetName: locationSetName,
                assetUploadStatus: assetUploadStatus,
                geocodingStatus: geocodingStatus,
                boundaryCount: boundaryCount,
                boundaryProcessedCount: boundaryProcessedCount,
                hazardCount: hazardCount,
                hazardProcessedCount: hazardProcessedCount,
                totalScore: totalScore,
                typography: typography,
                hazardScoreCount: hazardScoreCount,
                hazardScoreProcessedCount: hazardScoreProcessedCount,
                overallScore: overallScore,
                overallScoreStatus: overallScoreStatus,
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  String getSubProcessName(dynamic value) {
    if (value is String) return value;
    print('Unexpected type for sub_process_name: ${value.runtimeType}');
    return 'Location Set 0';
  }

  // Build each Location Set card (Sub-PID) as ExpansionTile
  Widget _buildLocationSetCard({
    required String locationSetId,
    required String locationSetName,
    required String assetUploadStatus,
    required String geocodingStatus,
    required int boundaryCount,
    required int boundaryProcessedCount,
    required int hazardCount,
    required int hazardProcessedCount,
    required int hazardScoreCount,
    required int hazardScoreProcessedCount,
    required Map<String, dynamic> totalScore,
    required CustomTypography typography,
    required overallScore,
    required String overallScoreStatus,
  }) {
    print('Overall Score: $overallScoreStatus');
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        showTrailingIcon: false,
        collapsedBackgroundColor:
            Theme.of(context).hoverColor.withOpacity(0.05),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side:
              BorderSide(color: Theme.of(context).hoverColor.withOpacity(0.1)),
        ),
        backgroundColor: Theme.of(context).hoverColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side:
              BorderSide(color: Theme.of(context).hoverColor.withOpacity(0.1)),
        ),
        key: Key(locationSetId),
        initiallyExpanded: true,
        // Initially collapsed
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Chip(
                    label: Text(
                      'Sub-PID',
                      style: typography.Caption,
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    )),
                SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    locationSetId,
                    style:
                        typography.Body1.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryMain,
                  child: Text(
                    locationSetName.substring(locationSetName.length - 1),
                    style: typography.Body1.copyWith(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    locationSetName,
                    overflow: TextOverflow.ellipsis,
                    style:
                        typography.Body1.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Divider(
              thickness: 2.0,
              color: Theme.of(context).hoverColor.withOpacity(0.1),
            ),
          ),
          _buildSubProcess(
              'Geocoding',
              '${geocodingStatus.toLowerCase() == "completed" ? "1" : "0"}/1',
              geocodingStatus,
              typography),
          _buildSubProcess(
              'Asset Upload',
              '${assetUploadStatus.toLowerCase() == "completed" ? "1" : "0"}/1',
              assetUploadStatus,
              typography),
          if (boundaryCount > 0)
            _buildSubProcess(
                'Boundary Intersection',
                '$boundaryProcessedCount/$boundaryCount',
                boundaryCount - boundaryProcessedCount == 0
                    ? "completed"
                    : "in progress",
                typography),
          if (hazardCount > 0)
            _buildSubProcess(
                'Hazard',
                '$hazardProcessedCount/$hazardCount',
                hazardCount - hazardProcessedCount == 0
                    ? "completed"
                    : "in progress",
                typography),
          if (hazardScoreCount > 0)
            _buildSubProcess(
                'Hazard Score',
                '$hazardScoreProcessedCount/$hazardScoreCount',
                hazardCount - hazardProcessedCount == 0
                    ? "completed"
                    : "in progress",
                typography),
          if (!(overallScoreStatus.toLowerCase() == 'ready'))
            _buildSubProcess(
                'Overall Score',
                '${overallScoreStatus.toLowerCase() == "completed" ? "1" : "0"}/1',
                overallScoreStatus,
                typography),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      // Open Job Monitoring action
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => JobMonitoringDashboard(

                              )));
                    },
                    child: Text(
                      'Open Job Monitoring',
                      style: typography.ButtonLarge.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build subprocess details for each stage
  Widget _buildSubProcess(String name, String progress, String status,
      CustomTypography typography) {
    return ListTile(
      minVerticalPadding: 0.0,
      title: Row(
        children: [
          SizedBox(
            width: 80.0, // Set fixed width for the Chip
            child: Chip(
              label: Container(
                // Wrap label with a Container for alignment control
                width: double.infinity,
                // Make sure the container takes the full width of the Chip
                alignment: Alignment.center,
                // Center the text inside the container
                child: Text(progress, style: typography.Caption),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.all(4.0),
              visualDensity: VisualDensity.adaptivePlatformDensity,
              side: BorderSide(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          status.toLowerCase() == 'Completed'.toLowerCase() && progress != '0/0'
              ? Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                )
              : Lottie.asset(
                  'assets/lottie/loading.json',
                  // Lottie file for 'in-progress' animation
                  width: 24,
                  height: 24,
                ),
          SizedBox(width: 8.0),
          Text(
            name,
            style: typography.Body2.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper function to get processed count
  int _getProcessedCount(Map<String, dynamic>? data) {
    if (data == null) return 0;
    int count = 0;

    data.forEach((key, value) {
      // Ensure that value is a Map and has a 'status' field
      if (value is Map<String, dynamic> && value.containsKey('status')) {
        if (value['status'].toString().toLowerCase() == 'completed') {
          count++;
        }
      }
    });

    return count;
  }
}

// Utility function to safely convert to Map<String, dynamic>
Map<String, dynamic> convertToStringDynamicMap(Map<dynamic, dynamic>? data) {
  if (data == null) {
    return {};
  }
  return data.map((key, value) => MapEntry(key.toString(), value));
}
