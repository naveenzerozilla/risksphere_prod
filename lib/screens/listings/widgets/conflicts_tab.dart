import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:provider/provider.dart';
import '../../../constants/enums.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/upload_sov_provider.dart';

class ConflictsTab extends StatefulWidget {
  final String processId;
  final String accountId;
  final String subAccountId;

  const ConflictsTab({
    super.key,
    required this.processId,
    required this.accountId,
    required this.subAccountId,
  });

  @override
  ConflictsTabState createState() => ConflictsTabState();
}

class ConflictsTabState extends State<ConflictsTab> {
  Map<String, dynamic> response = {};
  int currentIndex = 0; // For pagination

  List<Map<String, dynamic>> _conflictLocations = [];
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  String? selectedOption; // To store the selected conflict resolution option

  Future<void> _getData() async {
    response = await Provider.of<UploadSovProvider>(context, listen: false)
        .fetchConflicts(context, widget.processId);
    List<dynamic> data = response['result'] ?? [];
    setState(() {
      _conflictLocations = data.map((item) {
        return {
          'formatted_address': item['formatted_address'],
          'id': item['id'],
          'conflicts': item['similar'] ?? [],
        };
      }).toList();
    });
    if (_conflictLocations.isNotEmpty) {
      _updateMap();
    }
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _navigateToMarker(double latitude, double longitude) {
    const double offset = 0.005; // Offset to move the marker slightly upward
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(latitude + offset, longitude),
      ),
    );
  }

  void _navigateNext() {
    if (currentIndex < _conflictLocations.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null; // Reset the selection for the next conflict
      });
      _updateMap();
    }
  }

  void _navigatePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedOption = null; // Reset the selection for the previous conflict
      });
      _updateMap();
    }
  }

  void _updateMap() {
    final currentLocation = _conflictLocations[currentIndex];
    if (currentLocation['conflicts'].isNotEmpty) {
      final firstConflict = currentLocation['conflicts'][0];
      _navigateToMarker(
        firstConflict['latitude'] ?? 10.0202,
        firstConflict['longitude'] ?? 102.0229,
      );
    }
  }

  void _resolveConflict() async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an option to resolve the conflict.")),
      );
      return;
    }

    final currentConflict = _conflictLocations[currentIndex];
    final selectedData = [{
      'account_id': widget.accountId,
      'sub_account_id': widget.subAccountId,
      'unique_object_id': currentConflict['id'],
      'process_id': widget.processId,
      'location_id': selectedOption=='none'?null:selectedOption,
    }];

    bool success = await Provider.of<UploadSovProvider>(
      context,
      listen: false,
    ).resolveConflict(context, selectedData);

    if (success) {
      await _getData();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasConflicts = _conflictLocations.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _getData();
        },
        child: hasConflicts
            ? Stack(
          alignment: Alignment.bottomCenter,
          children: [
            GoogleMap(
              key: _mapKey,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _conflictLocations.isNotEmpty &&
                    _conflictLocations[currentIndex]['conflicts']
                        .isNotEmpty
                    ? LatLng(
                  _conflictLocations[currentIndex]['conflicts'][0]
                  ['latitude'],
                  _conflictLocations[currentIndex]['conflicts'][0]
                  ['longitude'],
                )
                    : LatLng(0, 0),
                zoom: 14,
              ),
              markers: {
                // Main marker
                Marker(
                  markerId: MarkerId('mainMarker'),
                  position: LatLng(
                    _conflictLocations[currentIndex]
                    ['latitude']??0,
                    _conflictLocations[currentIndex]
                    ['longitude']??0,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: 'Main Location',
                    snippet: _conflictLocations[currentIndex]
                    ['formatted_address'],
                  ),
                ),
                // Conflict location markers
                ..._conflictLocations[currentIndex]['conflicts']
                    .map<Marker>((conflict) {
                  return Marker(
                    markerId: MarkerId(conflict['location_id']),
                    position: LatLng(
                      conflict['latitude'] ?? 0.0,
                      conflict['longitude'] ?? 0.0,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue), // Blue marker
                    infoWindow: InfoWindow(
                      title: conflict['address'],
                    ),
                  );
                }).toSet(),
              },
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
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
                                        'Resolve Conflicts',
                                        style: CustomTypography(context)
                                            .Body1
                                            .copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Chip(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(24),
                                          side: BorderSide(
                                              color: Colors.transparent),
                                        ),
                                        label: Text(
                                          '${_conflictLocations.length}',
                                          style: CustomTypography(context)
                                              .Caption
                                              .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
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
                                  _conflictLocations[currentIndex]
                                  ['formatted_address'],
                                  style: CustomTypography(context)
                                      .H7
                                      .copyWith(
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
                        // Conflict Options
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _conflictLocations[currentIndex]
                          ['conflicts']
                              .length >
                              3
                              ? 3
                              : _conflictLocations[currentIndex]
                          ['conflicts']
                              .length,
                          itemBuilder: (context, index) {
                            final conflict =
                            _conflictLocations[currentIndex]
                            ['conflicts'][index];
                            return GestureDetector(
                              onTap: () {
                                _navigateToMarker(
                                  conflict['latitude'] ?? 0.0,
                                  conflict['longitude'] ?? 0.0,
                                );
                              },
                              child: RadioListTile<String>(
                                title: Text(conflict['address']),
                                value: conflict['location_id'],
                                groupValue: selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOption = value;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        RadioListTile<String>(
                          title: Text("None of these"),
                          value: "none",
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: CustomButton(
                                  type: ButtonType.elevated,
                                  onPressed: _resolveConflict,
                                  child: Text(
                                    "Resolve",
                                    style: CustomTypography(context)
                                        .ButtonLarge
                                        .copyWith(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        )
            : Center(
          child: Text(
            "Looks like there are no conflicts to resolve!",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
