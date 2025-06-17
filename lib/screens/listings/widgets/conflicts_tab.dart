import 'package:RiskSphere/models/my_location_list_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../design_system/primitives/app_colors.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../providers/my_location_list_provider.dart';
import '../../../providers/upload_sov_provider.dart';
import '../../../utils/api_constants.dart';
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
  final bool? startHazard;

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
  String? selectedOption = "none";
  Map<int, String> selectedOptions = {};
  int? selectedIndex;
  int currentIndex = 0;
  List<String>? conflictIds; // stable IDs
  bool isLoading = false;
  bool isResolving = false;
  bool isSkiped = false;
  bool conflictResolved = false;
  String? selectedValue = "0";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMap();
    });
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
    if (currentIndex < widget.location!.length - 1) {
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
    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an option to resolve the conflict."),
        ),
      );
      return;
    }
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    print(widget.location.toString());
    print(widget.conflict.toString());

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
        'conflict_index': currentIndex,
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
        });
        Navigator.pop(context, true);
      } else {
        setState(() {
          widget.location!.removeAt(currentIndex);

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

    // final success = await provider.resolveConflict(context, selectedData);
    //
    // if (success) {
    //   print("object");
    //   if (widget.location == null) {
    //     setState(() {
    //       conflictResolved = true;
    //       isResolving = false;
    //     });
    //   } else {
    //     setState(() {
    //       widget.location!.removeAt(currentIndex);
    //
    //       // Reset selected state
    //       selectedOption = 'none';
    //       selectedValue = null;
    //       selectedIndex = null;
    //
    //       if (currentIndex >= widget.location!.length) {
    //         currentIndex =
    //             widget.location!.isNotEmpty ? widget.location!.length - 1 : 0;
    //       }
    //
    //       if (widget.location!.isEmpty) {
    //         conflictResolved = true;
    //       }
    //
    //       isResolving = false;
    //     });
    //
    //     _updateMap();
    //
    //     if (conflictResolved) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text("All conflicts resolved.")),
    //       );
    //     }
    //   }
    // } else {
    //   setState(() {
    //     isResolving = false;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Failed to resolve conflict. Try again.")),
    //   );
    // }
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
      bottomNavigationBar: conflictResolved == true
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
                                  print("Hello");
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
      body: conflictResolved == true
          ? Consumer<MyLocationListProvider>(
              builder: (context, locationListProvider, child) {
              final conflictLocations = locationListProvider.myLocationList
                  .where((location) => location.isConflict == true)
                  .toList();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Great news, there are no conflicts to resolve!",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, true);
                          // _StartHazardConflict(
                          //     conflictLocations: conflictLocations);
                        },
                        child: MessageCard1(
                          messageTextSpans: [
                            TextSpan(
                              text: "Click here to ",
                              style: typography.Body2,
                            ),
                            TextSpan(
                              text: "Update Hazard scores",
                              style: typography.Body2.copyWith(
                                color: AppColors.primaryMain,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
          : RefreshIndicator(
              onRefresh: () async {},
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

  bool isRefreshing = false; // Add this to your StatefulWidget

  Widget _buildConflictSheet(CustomTypography typography) {
    final hasMultipleLocations =
        widget.location != null && widget.location!.length > 1;
    final conflictData =
        hasMultipleLocations ? widget.location : widget.conflict;
    final currentItem = conflictData != null &&
            conflictData.isNotEmpty &&
            currentIndex < conflictData.length
        ? conflictData[currentIndex]
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
          child: isRefreshing
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    // Header with navigation
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
                            onPressed:
                                currentIndex > 0 ? _navigatePrevious : null,
                            child: Icon(Icons.chevron_left,
                                size: 24, color: AppColors.primaryMain),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      setState(() {
                                        isRefreshing = true;
                                      });

                                      await Future.delayed(const Duration(
                                          seconds: 1)); // simulate fetch

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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        widget.location!.length.toString(),
                                        style: typography.Body1.copyWith(
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
                                    currentIndex < widget.location!.length - 1
                                ? _navigateNext
                                : null,
                            child: Icon(Icons.chevron_right,
                                size: 24, color: AppColors.primaryMain),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),
                    const SizedBox(height: 10),

                    // Address and edit icon
                    if (currentItem != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              width: MediaQuery.of(context).size.width / 1.4,
                              child: Text(
                                hasMultipleLocations
                                    ? (currentItem as MyLocation)
                                            .geocodedAddress ??
                                        (currentItem as MyLocation)
                                            .geocodedAddress ??
                                        ''
                                    : (currentItem as Conflicts)
                                            .geocodedAddress ??
                                        widget.geocodingAddress ??
                                        '',
                                maxLines: 3,
                                style: typography.H4.copyWith(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                final locationId = hasMultipleLocations
                                    ? (currentItem as MyLocation).id ?? ''
                                    : (currentItem as Conflicts).locationId ??
                                        '';
                                print(widget.geocodingAddress.toString());
                                final address = (currentItem as MyLocation)
                                        .geocodedAddress ??
                                    widget.geocodingAddress;
                                print(address.toString());
                                print("address".toString());

                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (_) => AddLocationScreen(
                                    accountId: widget.accountId,
                                    subAccountId: widget.subAccountId,
                                    sovId: "null",
                                    accountName: widget.accountName,
                                    subAccountName: widget.subAccountName!,
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
                                    widget.location!.removeAt(currentIndex);
                                    selectedOption = 'none';
                                    selectedValue = null;
                                    selectedIndex = null;
                                  });
                                });
                              },
                              child: const Icon(Icons.edit,
                                  size: 20, color: Colors.lightBlueAccent),
                            )
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Conflict List and Resolve button
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          hasMultipleLocations == false
                              ? Column(
                                  children: widget.conflict!
                                      .map((option) => RadioListTile<String>(
                                            title: Text(
                                                option.finalAddress?.address ??
                                                    'Unknown'),
                                            value:
                                                option.finalAddress?.address ??
                                                    '',
                                            groupValue: selectedOption,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedOption = value;
                                                selectedValue = value;
                                                // selectedIndex = index;
                                              });
                                            },
                                          ))
                                      .toList(),
                                )
                              : (currentItem != null
                                  ? Column(
                                      children: ((hasMultipleLocations
                                                  ? (currentItem as MyLocation)
                                                      .conflicts
                                                  : [
                                                      (currentItem as Conflicts)
                                                    ]) ??
                                              [])
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final conflict = entry.value;
                                        final address = conflict.finalAddress;
                                        final locationId = hasMultipleLocations
                                            ? "${(currentItem as MyLocation).id ?? 'loc'}_conflict_$index"
                                            : "${conflict.locationId ?? 'conflict'}_$index";

                                        final conflictsList =
                                            hasMultipleLocations
                                                ? (currentItem as MyLocation)
                                                    .conflicts
                                                : [(currentItem as Conflicts)];
                                        print("locationId: ${locationId}");
                                        print(
                                            "conflictsList length: ${conflictsList?.length}");

                                        return RadioListTile<String>(
                                          activeColor: Colors.white,
                                          title: Text(
                                            address?.address ?? 'Unknown',
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
                                            if (address != null) {
                                              _navigateToMarker(
                                                address.latitude ?? 0.0,
                                                address.longitude ?? 0.0,
                                              );
                                            }
                                            print(selectedValue);
                                          },
                                        );
                                      }).toList(),
                                    )
                                  : const SizedBox.shrink()),
                          const SizedBox(height: 25),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
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
