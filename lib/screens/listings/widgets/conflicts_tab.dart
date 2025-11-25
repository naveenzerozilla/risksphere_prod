import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/my_location_list_provider.dart';
import '../../../providers/upload_sov_provider.dart';
import '../add_location_screen.dart';
import 'message_card.dart';

class ConflictsTab extends StatefulWidget {
  final String? subAccountName;
  final String processId;
  final String accountId;
  final String subAccountId;
  final String sovId;
  final String accountName;
  final String tempId;
  final String? lat;
  final String? long;
  final String? geocodingAddress;
  final List<Conflicts>? conflict;
  final List<MyLocation>? location;
  bool? startHazard;

  ConflictsTab({
    super.key,
    this.subAccountName,
    required this.processId,
    required this.accountId,
    required this.subAccountId,
    required this.sovId,
    required this.accountName,
    required this.tempId,
    this.lat,
    this.long,
    this.geocodingAddress,
    this.conflict,
    this.location,
    this.startHazard,
  });

  @override
  State<ConflictsTab> createState() => ConflictsTabState();
}

class ConflictsTabState extends State<ConflictsTab> {
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  int currentIndex = 0;
  String? selectedOption = 'none';
  String? selectedValue;
  int? selectedIndex;
  bool isLoading = false;
  bool isResolving = false;
  bool conflictResolved = false;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMap());
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
    if (widget.location != null && currentIndex < widget.location!.length - 1) {
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
    final conflictData = widget.location != null && widget.location!.isNotEmpty
        ? widget.location!
        : widget.conflict!;

    if (conflictData.isNotEmpty && currentIndex < conflictData.length) {
      final currentItem = conflictData[currentIndex];
      final lat = currentItem is MyLocation
          ? currentItem.finalAddress!.latitude ?? 0.0
          : (currentItem as Conflicts).latitude ?? 0.0;
      final lng = currentItem is MyLocation
          ? currentItem.finalAddress!.longitude
          : (currentItem as Conflicts).longitude ?? 0.0;

      _navigateToMarker(lat, lng!);
    }
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final conflictData = widget.location != null && widget.location!.isNotEmpty
        ? widget.location!
        : widget.conflict!;

    for (int i = 0; i < conflictData.length; i++) {
      final item = conflictData[i];
      final lat = item is MyLocation
          ? item.finalAddress!.latitude ?? 0.0
          : (item as Conflicts).latitude ?? 0.0;
      final lng = item is MyLocation
          ? item.finalAddress!.longitude ?? 0.0
          : (item as Conflicts).longitude ?? 0.0;
      final address = item is MyLocation
          ? item.geocodedAddress
          : (item as Conflicts).address ?? '';

      markers.add(Marker(
        markerId: MarkerId('marker_$i'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(i == currentIndex
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: address),
      ));
    }

    return markers;
  }

  void _resolveConflict() async {
    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an option to resolve the conflict."),
        ),
      );
      return;
    }
    final provider = Provider.of<UploadSovProvider>(context, listen: false);

    // if (widget.location == null || widget.location!.isEmpty) return;

    final isLastItem =
        widget.location == null ? true : widget.location!.length == 1;

    setState(() {
      // if (isLastItem)
      isResolving = true;
    });

    final currentConflictId = widget.location == null
        ? widget.conflict![0].locationId
        : widget.location![currentIndex].id;

    final selectedData = [
      {
        'conflict_index': selectedIndex == null ? "0" : selectedIndex,
        'location_id': currentConflictId,
      }
    ];
    print(selectedData);
    final success = await provider.resolveConflict(selectedData);

    if (!mounted) return;

    if (success) {
      if (widget.location == null) {
        setState(() {
          isResolving = false;
          widget.startHazard = true;
        });
        Navigator.pop(context, true);
      } else {
        setState(() {
          widget.location!.removeAt(currentIndex);
          widget.startHazard = true;
          selectedOption = 'none';
          selectedValue = null;
          selectedIndex = null;

          if (currentIndex >= widget.location!.length) {
            currentIndex =
                widget.location!.isNotEmpty ? widget.location!.length - 1 : 0;
          }

          if (widget.location!.isEmpty) {
            Navigator.pop(context, true);
          }
          isResolving = false;
        });

        _updateMap();
        if (conflictResolved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("All conflicts resolved.")),
          );
        }
      }
    } else {
      if (!mounted) return;

      setState(() {
        isResolving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to resolve conflict. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);
    final conflictData = widget.location != null && widget.location!.isNotEmpty
        ? widget.location!
        : widget.conflict!;

    final currentItem =
        conflictData.isNotEmpty && currentIndex < conflictData.length
            ? conflictData[currentIndex]
            : null;

    final hasMultipleLocations =
        widget.location != null && widget.location!.length > 1;

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            iconSize: 25,
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: const Text("Resolve Conflict",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
        ),
        bottomNavigationBar: conflictResolved
            ? null
            : BottomAppBar(
                color: Theme.of(context).primaryColor,
                shape:
                    CircularNotchedRectangle(), // Optional, for a rounded edge look
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
                            Navigator.pop(context, true);
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
                                color: widget.startHazard == true
                                    ? AppColors.primaryMain
                                    : Colors.grey, // Disable border color
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.transparent,
                            // Or your preferred background
                            foregroundColor: widget.startHazard == true
                                ? AppColors.primaryMain
                                : Colors.grey, // Controls text color
                          ),
                          onPressed: widget.startHazard == true
                              ? () async {
                                  if (conflictResolved == true) {
                                    Navigator.pop(context, true);
                                  } else {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    await Future.delayed(Duration(seconds: 2));
                                    Navigator.pop(context, true);

                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              : null, // disables the button if startHazard is false
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
                                      : 'Start Hazard Score',
                                  style: typography.ButtonLarge.copyWith(
                                    color: widget.startHazard == true
                                        ? AppColors.primaryMain
                                        : Colors.grey, // Disable text color
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        body: Stack(alignment: Alignment.center, children: [
          GoogleMap(
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
            myLocationButtonEnabled: false,
          ),
          DraggableScrollableSheet(
              initialChildSize: 0.53,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: isRefreshing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FloatingActionButton(
                                    shape: const CircleBorder(),
                                    mini: true,
                                    elevation: 0,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    onPressed: currentIndex > 0
                                        ? _navigatePrevious
                                        : null,
                                    child: Icon(Icons.chevron_left,
                                        size: 24,
                                        color: currentIndex > 0
                                            ? AppColors.primaryMain
                                            : Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              setState(() {
                                                isRefreshing = true;
                                              });

                                              await Future.delayed(
                                                  const Duration(seconds: 1));

                                              setState(() {
                                                selectedOption = 'none';
                                                selectedValue = null;
                                                selectedIndex = null;
                                                isRefreshing = false;
                                              });
                                            },
                                            child: const Icon(Icons.refresh,
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            hasMultipleLocations
                                                ? "Resolve Locations "
                                                : "Resolve Conflicts ",
                                            style: typography.Body1.copyWith(
                                                color: Colors.white),
                                          ),
                                          if (widget.location != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                widget.location!.length
                                                    .toString(),
                                                style:
                                                    typography.Body1.copyWith(
                                                        color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  FloatingActionButton(
                                    shape: const CircleBorder(),
                                    mini: true,
                                    elevation: 0,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    onPressed: hasMultipleLocations &&
                                            currentIndex <
                                                widget.location!.length - 1
                                        ? _navigateNext
                                        : null,
                                    child: Icon(Icons.chevron_right,
                                        size: 24,
                                        color: hasMultipleLocations &&
                                                currentIndex <
                                                    widget.location!.length - 1
                                            ? AppColors.primaryMain
                                            : Colors.grey),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(),
                            const SizedBox(height: 10),

                            // Address and edit icon
                            if (currentItem != null)
                              // Address and edit icon
                              if (currentItem != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${currentIndex + 1} -",
                                        style: typography.H4.copyWith(
                                          color: Colors.lightBlueAccent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                        child: Text(
                                          currentItem is MyLocation
                                              ? currentItem.geocodedAddress ??
                                                  ''
                                              : currentItem is Conflicts
                                                  ? currentItem.address ??
                                                      widget.geocodingAddress ??
                                                      ''
                                                  : widget.geocodingAddress ??
                                                      '',
                                          maxLines: 3,
                                          style: typography.H4.copyWith(
                                            color: Colors.lightBlueAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          final locationId = currentItem
                                                  is MyLocation
                                              ? currentItem.id ?? ''
                                              : currentItem is Conflicts
                                                  ? currentItem.locationId ?? ''
                                                  : '';

                                          final address =
                                              currentItem is MyLocation
                                                  ? currentItem.geocodedAddress
                                                  : widget.geocodingAddress;

                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            builder: (_) => AddLocationScreen(
                                              accountId: widget.accountId,
                                              subAccountId: widget.subAccountId,
                                              sovId: "null",
                                              accountName: widget.accountName,
                                              subAccountName:
                                                  widget.subAccountName!,
                                              sovName: "widget.sovName!",
                                              locationId: locationId,
                                              locationName: address,
                                              locationIdForRef: locationId,
                                              searchQuery: address!,
                                              is_conflict: true,
                                            ),
                                          ))
                                              .then((_) {
                                            setState(() {
                                              widget.location!
                                                  .removeAt(currentIndex);
                                              selectedOption = 'none';
                                              selectedValue = null;
                                              selectedIndex = null;
                                            });
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          child: Icon(Icons.edit,
                                              size: 25,
                                              color: Colors.lightBlueAccent),
                                        ),
                                      )
                                    ],
                                  ),
                                ),


                            const SizedBox(height: 10),

                            // Conflict List
                            if (!hasMultipleLocations)
                              Column(
                                key: ValueKey(selectedOption), // Force rebuild
                                children: widget.conflict!
                                    .take(
                                        3) // 👈 only take first 2 items safely
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final option = entry.value;
                                  final value = option.address ?? 'Unknown';

                                  // Auto-select first item if selectedOption is "none"
                                  if (index == 0 && selectedOption == "none") {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        selectedOption = value;
                                        selectedValue = value;
                                      });
                                    });
                                  }

                                  return RadioListTile<String>(
                                    title: Text(value),
                                    value: value,
                                    groupValue: selectedOption,
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedOption = newValue;
                                        selectedValue = newValue;
                                      });
                                      print(
                                          "Selected Conflict Option: $newValue");
                                    },
                                  );
                                }).toList(),
                              )
                            else if (currentItem != null)
                              Builder(
                                builder: (context) {
                                  final conflicts =
                                      (currentItem as MyLocation).conflicts ??
                                          [];
                                  final defaultId =
                                      "${currentItem.id}_conflict_0";

                                  // Always reset selectedValue if it's not matching currentItem
                                  if (conflicts.isNotEmpty &&
                                      (selectedValue == null ||
                                          !selectedValue!
                                              .startsWith(currentItem.id!))) {
                                    Future.microtask(() {
                                      if (mounted) {
                                        setState(() {
                                          selectedValue = defaultId;
                                          selectedIndex = 0;
                                        });
                                      }
                                    });
                                  }
                                  return Column(
                                    key: ValueKey(currentItem.id),
                                    // forces rebuild on item change
                                    children: conflicts
                                        .take(3) // 👈 only take first 2 items
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final conflict = entry.value;
                                      final address = conflict.address;
                                      final locationId =
                                          "${(currentItem).id}_conflict_$index";

                                      return RadioListTile<String>(
                                        activeColor: Colors.white,
                                        title: Text(
                                          address ?? 'Unknown',
                                          style: typography.Body2.copyWith(
                                              color: Colors.white),
                                        ),
                                        value: locationId,
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedValue = value;
                                            selectedIndex = index;
                                          });
                                          print(
                                              "Selected Conflict Option: $selectedIndex");
                                          if (address != null) {
                                            _navigateToMarker(
                                              conflict.latitude ?? 0.0,
                                              conflict.longitude ?? 0.0,
                                            );
                                          }
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                            const SizedBox(height: 25),


                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          isResolving ? null : _resolveConflict,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.lightBlueAccent,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      child: isResolving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              "Resolve",
                                              style: CustomTypography(context)
                                                  .ButtonLarge
                                                  .copyWith(
                                                      color: Colors.black),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                );
              }),
        ]));
  }
}

