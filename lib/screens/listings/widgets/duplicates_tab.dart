import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/upload_sov_provider.dart';

class DuplicatesTab extends StatefulWidget {
  final String processId;
  final String accountId;
  final String subAccountId;

  const DuplicatesTab({super.key, required this.processId, required this.accountId, required this.subAccountId});

  @override
  DuplicatesTabState createState() => DuplicatesTabState();
}

class DuplicatesTabState extends State<DuplicatesTab> {
  Map<String, dynamic> response = {};
  int currentIndex = 0; // For pagination

  List<Map<String, dynamic>> _duplicateLocations = [];
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();

  Future<void> _getData() async {
    response = await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchDuplicates(context, widget.processId);
    List<dynamic> data = response['result'] ?? [];
    setState(() {
      _duplicateLocations = data.map((item) {
        return {
          'formatted_address': item['formatted_address'],
          'id': item['id'],
          'top_duplicate': item['duplicates']?.isNotEmpty == true
              ? item['duplicates'][0] // Pick the first duplicate
              : null
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _navigateNext() {
    if (currentIndex < _duplicateLocations.length - 1) {
      setState(() {
        currentIndex++;
      });
      _updateMap();
    }
  }

  void _navigatePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _updateMap();
    }
  }

  void _updateMap() {
    final currentLocation = _duplicateLocations[currentIndex];
    final topDuplicate = currentLocation['top_duplicate'];
    if (topDuplicate != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(topDuplicate['latitude']??10.0202, topDuplicate['longitude']??102.0229),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDuplicates = _duplicateLocations.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _getData();
        },
        child: hasDuplicates
            ? Stack(
          alignment: Alignment.bottomCenter,
          children: [
            GoogleMap(
              key: _mapKey,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _duplicateLocations.isNotEmpty &&
                    _duplicateLocations[currentIndex]
                    ['top_duplicate'] !=
                        null
                    ? LatLng(
                    _duplicateLocations[currentIndex]
                    ['top_duplicate']['latitude'],
                    _duplicateLocations[currentIndex]
                    ['top_duplicate']['longitude'])
                    : LatLng(0, 0),
                zoom: 14,
              ),
              markers: {
                // Main address marker
                Marker(
                  markerId: MarkerId('mainAddress'),
                  position: LatLng(
                    _duplicateLocations[currentIndex]
                    ['top_duplicate']?['latitude']??0,
                    _duplicateLocations[currentIndex]
                    ['top_duplicate']?['longitude']??0,
                  ),
                  infoWindow: InfoWindow(
                    title: '',
                    snippet: _duplicateLocations[currentIndex]
                    ['top_duplicate']?['geocode_input_address']?['formatted_address']??"",
                  ),
                ),
              },
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHigh,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(width: 8),
                            FloatingActionButton(
                              shape: CircleBorder(),
                              mini: true,
                              elevation: 0,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              onPressed: _navigatePrevious,
                              child: Icon(
                                Icons.chevron_left,
                                size: 24,
                                color: AppColors.primaryMain,
                              ),
                            ),
                            Spacer(),
                            Row(
                              children: [
                                Text(
                                  'Duplicates',
                                  style: CustomTypography(context)
                                      .Body1
                                      .copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Chip(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(24),
                                    side: BorderSide(
                                        color: Colors.transparent),
                                  ),
                                  label: Text(
                                    '${currentIndex + 1} of ${_duplicateLocations.length}',
                                    style: CustomTypography(context)
                                        .Caption
                                        .copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              ],
                            ),
                            Spacer(),
                            FloatingActionButton(
                              shape: CircleBorder(),
                              mini: true,
                              elevation: 0,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              onPressed: _navigateNext,
                              child: Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: AppColors.primaryMain,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                        Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          thickness: 2,
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: Text(
                            _duplicateLocations[currentIndex]
                            ['formatted_address'],
                            style: CustomTypography(context).H7.copyWith(
                              color: AppColors.primaryMain,
                              height: 1,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _duplicateLocations[currentIndex]['top_duplicate']
                      ?['address']??"",
                      style: CustomTypography(context).Body1.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color,
                      ),
                    ),
                  ),
                  // Add text If this isn't a duplicate, please click here.
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "If this isn't a duplicate, please click here.",
                      style: CustomTypography(context).Caption,
                    ),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: CustomButton(
                            type: ButtonType.elevated,
                            onPressed: () async {
                              // Get the current duplicate row
                              final currentDuplicate = _duplicateLocations[currentIndex];

                              // Call the method to mark as not duplicate
                              bool success = await Provider.of<UploadSovProvider>(
                                context,
                                listen: false,
                              ).markAsNotDuplicate(
                                context,
                                widget.accountId, // Replace with actual account_id
                                widget.subAccountId, // Replace with actual sub_account_id
                                  widget.processId,
                                [currentDuplicate],
                                  _duplicateLocations[currentIndex]['id']??""// Pass the current duplicate
                              );

                              if (success) {
                                // Refresh the data if successful
                                await _getData();
                              }
                            },
                            child: Text(
                              "It's not duplicate!",
                              style: CustomTypography(context).ButtonLarge.copyWith(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        )
            : Center(
          child: Text(
            "Looks like there are no duplicates!",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
