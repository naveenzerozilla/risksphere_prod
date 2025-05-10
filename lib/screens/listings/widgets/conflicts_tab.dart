import 'package:RiskSphare/models/my_location_list_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/upload_sov_provider.dart';
import 'message_card.dart';

class ConflictsTab extends StatefulWidget {
  final String? subAccountName;
  final String processId;
  final String accountId;
  final String subAccountId;
  final String accountName;
  final String tempId;
  final String? lat;
  final String? long;
  final String? geocodingAddress;
  final List<Conflicts>? conflict;

  const ConflictsTab({
    super.key,
    this.subAccountName,
    required this.processId,
    required this.accountId,
    required this.subAccountId,
    required this.accountName,
    required this.tempId,
    this.lat,
    this.long,
    this.geocodingAddress,
    this.conflict,
  });

  @override
  State<ConflictsTab> createState() => ConflictsTabState();
}

class ConflictsTabState extends State<ConflictsTab> {
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  String? selectedOption = "none";
  Map<int, String> selectedOptions = {};
  int? selectedIndex;
  int currentIndex = 0;
  List<String>? conflictIds; // stable IDs
  bool isLoading = false;
  bool isResolving = false;
  bool conflictResolved = false;

  @override
  void initState() {
    super.initState();
    conflictIds = widget.conflict!
        .map((c) => c.locationId ?? UniqueKey().toString())
        .toList();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _navigateToMarker(double latitude, double longitude) {
    const double offset = 0.005;
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude + offset, longitude)),
    );
  }

  void _navigateNext() {
    if (currentIndex < widget.conflict!.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = 'none';
      });
      _updateMap();
    }
  }

  void _navigatePrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedOption = 'none';
      });
      _updateMap();
    }
  }

  void _updateMap() {
    if (widget.conflict!.isNotEmpty && currentIndex < widget.conflict!.length) {
      final currentConflict = widget.conflict![currentIndex];
      final finalAddress = currentConflict.finalAddress;
      if (finalAddress != null) {
        _navigateToMarker(
          finalAddress.latitude ?? 0.0,
          finalAddress.longitude ?? 0.0,
        );
      }
    }
  }

  void _resolveConflict() async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select an option to resolve the conflict.")),
      );
      return;
    }

    setState(() {
      isResolving = true;
    });

    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    final currentConflict = widget.conflict![currentIndex];

    final selectedData = [
      {
        'account_id': widget.accountId,
        'sub_account_id': widget.subAccountId,
        'unique_object_id': '', // Fill from currentConflict if needed
        'process_id': widget.processId,
        'location_id': selectedOption == 'none' ? null : selectedOption,
      }
    ];

    final success = await provider.resolveConflict(context, selectedData);

    setState(() {
      isResolving = false;
    });

    if (success) {
      setState(() {
        conflictResolved = true;
      });

      // Optional: Show a success message or refresh the page
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Resolve Conflict",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: CircularNotchedRectangle(), // Optional, for a rounded edge look
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Your cancel button logic here
                  },
                  child: Text(
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
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: AppColors.primaryMain,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    if (conflictResolved == true) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        isLoading = true;
                      });

                      // Simulate reload or call your actual reload logic here
                      await Future.delayed(Duration(seconds: 2));

                      setState(() {
                        isLoading = false;
                      });

                      // Optional: Add your refresh logic here
                    }
                  },
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,

                          ),
                        )
                      : Text(
                          conflictResolved == true
                              ? "Commit Locations"
                              : 'Refresh Locations',
                          style: typography.ButtonLarge.copyWith(
                            color: AppColors.primaryMain,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: conflictResolved == true
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Great news, there are no conflicts to resolve!",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    MessageCard1(
                      messageTextSpans: [
                        TextSpan(
                          text: "Click here to",
                          style: typography.Body2,
                        ),
                        TextSpan(
                          text: "Update Hazard scores",
                          style: typography.Body2.copyWith(
                            color: AppColors.primaryMain,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh logic
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: GoogleMap(
                      key: _mapKey,
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          double.tryParse(widget.lat ?? '0.0') ?? 0.0,
                          double.tryParse(widget.long ?? '0.0') ?? 0.0,
                        ),
                        zoom: 14,
                      ),
                      markers: _buildMarkers(),
                    ),
                  ),
                  _buildConflictSheet(typography),
                ],
              ),
            ),
    );
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    if (widget.conflict!.isNotEmpty && currentIndex < widget.conflict!.length) {
      final currentConflict = widget.conflict![currentIndex];
      final finalAddress = currentConflict.finalAddress;

      if (finalAddress != null) {
        markers.add(Marker(
          markerId: const MarkerId('mainMarker'),
          position: LatLng(
              finalAddress.latitude ?? 0.0, finalAddress.longitude ?? 0.0),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              InfoWindow(title: 'Main Location', snippet: finalAddress.address),
        ));
      }

      for (final conflict in widget.conflict!) {
        if (conflict.finalAddress != null) {
          final address = conflict.finalAddress!;
          markers.add(Marker(
            markerId:
                MarkerId(conflict.locationId ?? 'conflict_${markers.length}'),
            position: LatLng(address.latitude ?? 0.0, address.longitude ?? 0.0),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: address.address),
          ));
        }
      }
    }

    return markers;
  }

  Widget _buildConflictSheet(CustomTypography typography) {
    final currentConflict =
        widget.conflict != null && widget.conflict!.isNotEmpty
            ? widget.conflict![currentIndex]
            : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.53,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                child: Row(
                  children: [
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      mini: true,
                      elevation: 0,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      onPressed: _navigatePrevious,
                      child: Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: AppColors.primaryMain,
                      ),
                    ),
                    SizedBox(height: 4),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Resolve Conflicts",
                                style: typography.Body1.copyWith(
                                    color: Colors.white)),
                            // const SizedBox(width: 8),
                            //
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 6, vertical: 2),
                            //   decoration: BoxDecoration(
                            //     color: Colors.red,
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: Text(widget.conflict!.length.toString(),
                            //       style: typography.Body2.copyWith(
                            //           color: Colors.white)),
                            // )
                          ],
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      mini: true,
                      elevation: 0,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      onPressed: _navigateNext,
                      child: Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppColors.primaryMain,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SizedBox(height: 10),

              if (currentConflict != null &&
                  currentConflict.finalAddress != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    currentConflict.finalAddress!.address ??
                        widget.geocodingAddress ??
                        '',
                    style: typography.H7.copyWith(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // List of conflict options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    ...widget.conflict!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final conflict = entry.value;
                      final address = conflict.finalAddress;
                      final locationId = conflictIds![index];

                      return RadioListTile<String>(
                        activeColor: Colors.white,
                        title: Text(
                          address?.address ?? 'Unknown',
                          style: typography.Body2.copyWith(color: Colors.white),
                        ),
                        value: locationId,
                        groupValue: selectedIndex == index ? locationId : null,
                        // Only selected if index matches
                        onChanged: (value) {
                          setState(() {
                            selectedIndex = index; // Update the selected index
                          });

                          if (address != null) {
                            _navigateToMarker(
                              address.latitude ?? 0.0,
                              address.longitude ?? 0.0,
                            );
                          }
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed:
                                  // _isCancelLoading  _skipConflict
                                  //     ? null
                                  //     :
                                  () {
                                Navigator.pop(context);
                              },
                              child:
                                  // _isCancelLoading
                                  //     ? Center(
                                  //   child: CircularProgressIndicator(
                                  //     color: AppColors.primaryMain,
                                  //   ),
                                  // )
                                  //     :
                                  Text(
                                'Skip',
                                style: typography.ButtonLarge.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isResolving ? null : _resolveConflict,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.lightBlueAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: isResolving
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.black),
                                      ),
                                    )
                                  : Text(
                                      "Resolve",
                                      style: CustomTypography(context)
                                          .ButtonLarge
                                          .copyWith(color: Colors.black),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
