import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green/constants/enums.dart';
import 'package:green/design_system/components/custom_button.dart';
import 'package:green/design_system/primitives/app_colors.dart';
import 'package:green/design_system/primitives/utilities/custom_spacing.dart';
import 'package:green/screens/listings/account_list.dart';
import 'package:green/screens/listings/widgets/duplicates_tab.dart';
import '../../../design_system/primitives/custom_typography.dart';
import '../../../service/language_service.dart';
import 'conflicts_tab.dart';
import 'location_headers.dart';
import '../../../providers/upload_sov_provider.dart';
import 'package:provider/provider.dart';

class LocationDataScreen extends StatefulWidget {
  final String tempId;
  final String processId;
  final String accountId;
  final String accountName;
  final String subAccountId;

  const LocationDataScreen({
    Key? key,
    required this.tempId,
    required this.processId,
    //required this.targetHeaders,
    this.accountId = '',
    this.accountName = '',
    this.subAccountId = '',
  }) : super(key: key);

  @override
  _LocationDataScreenState createState() => _LocationDataScreenState();
}

class _LocationDataScreenState extends State<LocationDataScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> locations = [];
  String _searchQuery = '';
  bool _selectAll = false;
  bool _isLoading = false;
  bool _isCancelLoading = false;

  Map<String, dynamic> response = {};


  TabController? _masterTabController;
  int selectedMasterTab = 0;
  ScrollController _scrollController = ScrollController();
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _masterTabController = TabController(length: 3, vsync: this);
    _masterTabController?.addListener(() {
      setState(() {
        selectedMasterTab = _masterTabController?.index ?? 0;
      });
      if (selectedMasterTab == 0 && !_isLoading) {
        _getData();
      }
    });
    //_getData(); // Initial data fetch
  }

  @override
  void dispose() {
    _masterTabController?.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100, // Scroll left by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100, // Scroll right by 100 pixels
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _getData() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    setState(() {
      _isLoading = true;
    });

    try {
      response = await Provider.of<UploadSovProvider>(context, listen: false)
          .fetchLocations(context, widget.processId);
      List<dynamic> data = response['result'] ?? [];

      setState(() {
        locations = data.map((item) {
          return {
            'isChecked': false,
            'formatted_address': item['formatted_address'] ?? 'No address available',
            'line_no': item['line_no'] ?? '',
            'city': item['property City'] ?? '',
            'location_name': item['Location Name'] ?? '',
            'state': item['State'] ?? '',
            'country': item['Country'] ?? '',
            'duplicates': item['duplicates'] ?? [],
            'is_duplicate': item['is_duplicate'] ?? false,
            'id': item['id'] ?? '',
            'type': item['type'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching locations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching locations. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset the loading flag
      });
    }
  }


  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var location in locations) {
        location['isChecked'] = _selectAll;
      }
    });
  }

  void _toggleCheckbox(bool? value, int index) {
    setState(() {
      locations[index]['isChecked'] = value!;
      if (!value) {
        _selectAll = false;
      }
    });
  }

  List<Map<String, dynamic>> _getSelectedLocations() {
    //if nothing is checked then return all locations else return only checked locations
    if (locations.every((element) => element['isChecked'] == false)) {
      return locations;
    } else {
      return locations.where((element) => element['isChecked'] == true).toList();
    }
  }

  void _commitSelectedLocations() {
    List<Map<String, dynamic>> selectedLocations = _getSelectedLocations();
   /* if (selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.getTranslated(context, "app_no_locations_selected")),
        ),
      );
      return;
    }*/
    _submitLocations(selectedLocations, "use_sov_data");
  }

  void _commitAllLocations() {
    _submitLocations(locations, "refresh_all_data");
  }

  void _submitLocations(List<Map<String, dynamic>> locationsToSubmit, String formatType) async {
    final provider = Provider.of<UploadSovProvider>(context, listen: false);
    if(widget.accountId.isNotEmpty) {
      await provider.submitLocationsSubAccounts(context, widget.tempId, locationsToSubmit, formatType, widget.accountId, widget.accountName);
      return;
    } else {
      await provider.submitLocationsAccounts(
          context, widget.tempId, locationsToSubmit, formatType,);
    }
  }
  void _showOptionsDialog() {
    var typography = CustomTypography(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _selectedOption = 'Use SOV Data';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C1C1E), // Dark background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Column(
                children: [
                  Text(
                    'Just one more step before\nsubmitting the locations!',
                    style: typography.Body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      'Use Locations Data',
                      style: typography.Body1,
                    ),
                    subtitle: Text(
                      'Only missing data will be processed!',
                      style: typography.Caption,
                    ),
                    value: "Use SOV Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Refresh All Data',
                      style: typography.Body1,
                    ),
                    value: "Refresh All Data",
                    groupValue: _selectedOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _commitSelectedLocations();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Commit Selected Locations',
                            style: typography.Body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _commitAllLocations();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Commit All Locations',
                            style: typography.Body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    final isSubmitLoading = Provider.of<UploadSovProvider>(context).isSubmitLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.getTranslated(context, "app_upload_preview"),
          style: typography.Body1.copyWith(fontWeight: FontWeight.w300),
        ),
      ),
      body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    // Master TabBar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        borderRadius:
                        BorderRadius.circular(0), // Rounded edges
                      ),
                      margin: EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      child: DefaultTabController(
                        length: 4,
                        child: Column(
                          children: <Widget>[
                            // Container for the TabBar with arrows
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                              ),
                              height: 50,
                              child: Row(
                                children: <Widget>[
                                  // Left arrow button
                                  /*IconButton(
                                    icon: Icon(Icons.arrow_left,
                                        color: Colors.grey),
                                    onPressed: _scrollLeft,
                                  ),*/
                                  // Scrollable TabBar
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: TabBar(
                                        controller: _masterTabController,
                                        tabAlignment: TabAlignment.start,
                                        labelStyle: typography.Subtitle2,
                                        isScrollable: true,
                                        indicatorColor:
                                        AppColors.primaryMain,
                                        labelColor:
                                        AppColors.primaryMain,
                                        unselectedLabelColor: Colors.grey,
                                        tabs: [
                                          Tab(
                                            text: 'Geocoding List',
                                          ),
                                          Tab(
                                            text: 'Duplicates',
                                          ),
                                          Tab(text: 'Conflicts'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Right arrow button
                                 /* IconButton(
                                    icon: Icon(Icons.arrow_right,
                                        color: Colors.grey),
                                    onPressed: _scrollRight,
                                  ),*/
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Master TabBarView for the Tab Content
                    Expanded(
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _masterTabController,
                        children: [

                          Column(
                            children: [

                              SizedBox(height: CustomSpacing.four,),
                              StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('processes_status')
                                      .doc(widget.processId??"")
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox(
                                    );
                                  }
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  final duplicationCheckStatus = data['duplication_check_status']?.toLowerCase();
                                  print("Duplication Check Status: $duplicationCheckStatus");

                                  if (duplicationCheckStatus != "completed") {
                                    // Show animated loader if duplication check is not completed
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Add your animated loader here
                                          SizedBox(
height: MediaQuery.sizeOf(context).height*0.1,                                          ),
                                          SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 6,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "We're currently reviewing your addresses.\nJust hang tight for a few minutes, and we'll have it ready for you shortly!",
                                            textAlign: TextAlign.center,
                                            style: typography.Subtitle1,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return Expanded(child: RefreshIndicator(
                                      onRefresh: _getData,
                                      child: _locationListBody(typography, context)));
                                }
                              ),
                            ],
                          ),
                          DuplicatesTab(
                            processId: widget.processId,
                            accountId: widget.accountId,
                            subAccountId: widget.subAccountId,
                          ),
                          ConflictsTab(
                            processId: widget.processId,
                            accountId: widget.accountId,
                            subAccountId: widget.subAccountId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSubmitLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              Consumer<UploadSovProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
      ),
    );
  }

  Widget _locationListBody(var typography, BuildContext context) {
    return PopScope(
      canPop: !_isCancelLoading,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 60,
              child: TextField(
                controller: _textEditingController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _textEditingController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: "Search Locations",
                  hintStyle: typography.Body2,
                ),
              ),
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          // Select all checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                ),
                Text(
                  "Select All",
                  style: typography.Body1,
                ),
              ],
            ),
          ),
          SizedBox(height: CustomSpacing.two),
          locations.isEmpty
              ? Expanded(
            child: Center(
              child: Text(
                "No locations.",
                style: typography.Body1,
              ),
            ),
          )
              :
          Expanded(
            child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                if (_searchQuery.isNotEmpty &&
                    !(location['formatted_address']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                        location['city']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))) {
                  return Container();
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          value: location['isChecked'],
                          onChanged: (bool? value) {
                            setState(() {
                              locations[index]['isChecked'] = value!;
                              if (!value) {
                                _selectAll = false;
                              }
                            });
                          },
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                location['formatted_address'],
                                style: typography.Body1,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${location['city'] != null && location['city'].isNotEmpty ? location['city'] : ''}"
                                    "${location['state'] != null && location['state'].isNotEmpty ? (location['city'] != null && location['city'].isNotEmpty ? ', ' : '') + location['state'] : ''}"
                                    "${location['country'] != null && location['country'].isNotEmpty ? ((location['city'] != null && location['city'].isNotEmpty) || (location['state'] != null && location['state'].isNotEmpty) ? ', ' : '') + location['country'] : ''}",
                                style: typography.Caption,
                                overflow: TextOverflow.ellipsis,
                              ),


                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                          ),
                          width: 50,
                          height: double.infinity,
                          child: IconButton(
                            icon: Icon(Icons.info,
                                color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationHeadersScreen(
                                      location: location),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomButton(
                    type: ButtonType.text,
                    onPressed: () {
                      // Show model dialog with text like On click give a model of warning, that this will cancel the process and the data uploaded will be purged. it cannot be recover, you will have to restart by upload the file again.
                      showDialog(
                        context: context,
                        barrierDismissible: false, // Disable dismissal while loading
                        builder: (context) {
                          return StatefulBuilder(
                              builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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

                                      var result = await Provider.of<UploadSovProvider>(context, listen: false)
                                          .cancelSovUploadProcess(context, widget.processId);

                                      if (result) {
                                        Navigator.pop(context); // Close the dialog
                                        Navigator.pop(context); // Navigate back
                                        Navigator.pop(context); // Navigate back
                                      } else {
                                        setState(() {
                                          _isCancelLoading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Error cancelling the process. Please try again."),
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
                            }
                          );
                        },
                      );
                      },
                    child: Text(
                      "Cancel",
                      style: typography.Body1,
                    ),
                  ),
                ),
                Expanded(
                  child: CustomButton(
                    type: ButtonType.elevated,
                    onPressed: _commitSelectedLocations,
                    child: Text(
                      "Submit",
                      style: typography.Body1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
