import '../../utils/global_imports.dart';
import 'package:RiskSphere/models/PricingModel.dart';
import 'package:RiskSphere/screens/payments/pricing_summary.dart';
import '../../utils/readmoreWidget.dart';

class PurchaseLicensePage extends StatefulWidget {
  static const String routeName = '/pricingList';

  const PurchaseLicensePage({
    super.key,
  });

  @override
  State<PurchaseLicensePage> createState() => _PurchaseLicensePageState();
}

class _PurchaseLicensePageState extends State<PurchaseLicensePage>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  bool isEventCost = true;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController mobileController = TextEditingController();
  bool isLoading = false;
  bool isExpanded = false;
  String selectedUserCount = '0';
  String selectedPlanType = '';
  String planId = '';
  String? selectedHazard;
  bool showMissingDataDropdown1 = false;
  int? totalPrice;
  Map<int, SelectedPlanState> subscriptionSelections = {};

  final TextEditingController _filePathController = TextEditingController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showCheckbox = false;

  Timer? deBouncer;

  Timer? autoCompleteDeBouncer;
  int? expandedCardIndex;
  Map<int, SelectedPlanState> cardSelections = {};

  late File files;
  List<dynamic> vendorList = [];

  String? selectedVendor;
  String? hazardName = "";
  String? vendorName = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  @override
  void dispose() {
    _filePathController.dispose();
    super.dispose();
  }

  _getData() async {
    final accountListProvider =
        Provider.of<AccountListProvider>(context, listen: false);
    final configurationProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    await accountListProvider.fetchPricingList(context, "", 1, 5);
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        Map<String, dynamic> getSummary() {
          dynamic total = 0;
          List<String> titles = [];
          List<String> planId = [];
          List<String> planTypes = [];
          List<String> licensePrice = [];
          List<String> userCounts = [];
          List<String> selectedPlanType = [];
          List<String> priceperuser = [];

          // selection.selectedPlanType
          for (var selection in cardSelections.values) {
            if (selection.totalPrice != null) {
              // total += num.parse(selection.totalPrice.toString());
              total +=
                  num.tryParse(selection.totalPrice?.toString() ?? '0') ?? 0;

              if (selection.title != null && selection.title!.isNotEmpty) {
                titles.add(selection.title!);
              }
              if (selection.planId != null && selection.planId!.isNotEmpty) {
                planId.add(selection.planId!);
              }

              if (selection.userCount != null &&
                  selection.userCount!.isNotEmpty) {
                userCounts.add(selection.userCount!);
              }

              if (selection.selectedPlanType != null &&
                  selection.selectedPlanType!.isNotEmpty) {
                selectedPlanType.add(selection.selectedPlanType!);
              }
              if (selection.priceperuser != null &&
                  selection.priceperuser!.isNotEmpty) {
                priceperuser.add(selection.priceperuser!);
              }
              if (selection.planType == "event_cost") {
                licensePrice.add(selection.licensePrice!);
              } else if (selection.licensePrice != null &&
                  selection.licensePrice!.isNotEmpty) {
                licensePrice.add(selection.licensePrice!);
              }

              if (selection.planType != null &&
                  selection.planType!.isNotEmpty) {
                planTypes.add(selection.planType!);
              }
            }
          }

          return {
            'total': total,
            'planId': planId,
            'titles': titles,
            'descriptions': "descriptions",
            'priceperuser': priceperuser,
            'licenseprice': licensePrice,
            'usercount': userCounts,
            'selectedPlanType': selectedPlanType,
            'planType': planTypes,
          };
        }

        return PopScope(
          onPopInvokedWithResult: (canPop, result) {
            Provider.of<DrawerSelectionProvider>(context, listen: false)
                .setSelectedItem("dashboard");
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: themeProvider.getTheme.colorScheme.background,
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
            bottomNavigationBar: Consumer<AccountListProvider>(
                builder: (context, pricingProvider, child) {
              return pricingProvider.isLoading ||
                      pricingProvider.pricingList.isEmpty
                  ? Container(
                      height: 10,
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(),
                      child:
                      Platform.isIOS
                          ? Container(height: 10)
                          :
                      Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 10),
                                getSummary()['total'] == 0
                                    ? Container(height: 0)
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Pricing',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '\$${getSummary()['total'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    final summary = getSummary();
                                    final titles = List<String>.from(
                                        summary['titles'] ?? []);
                                    if (titles.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                          "Please select at least one subscription plan.",
                                        )),
                                      );
                                      return;
                                    }
                                    print(summary);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PricingSummary(
                                          title: titles,
                                          summary: summary,
                                          hazardName: hazardName ?? "",
                                          vendorName: vendorName ?? "",
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == false) {
                                      } else {
                                        _getData();
                                        setState(() {
                                          cardSelections.clear();
                                          expandedCardIndex = null;
                                        });
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF99CCFF),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios,
                                          color: Colors.black, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    );
            }),
            body: Consumer<AccountListProvider>(
              builder: (context, pricingProvider, child) {
                var typography = CustomTypography(context);
                return pricingProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : pricingProvider.pricingList.isEmpty
                        ? Center(
                            child: Text(
                              "No Pricing Plans Available",
                              style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(0), // optional for spacing
                            child: Column(
                              children: [
                                SizedBox(height: CustomSpacing.three),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                        12), // Rounded corners
                                  ),
                                  child: Text(
                                    "Bring your business to the safest at scale",
                                    style: typography.Body1.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        letterSpacing: 0.4,
                                        color: Colors.white),
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                Text(
                                  "Uncover What RiskSphere Can Do for You",
                                  textAlign: TextAlign.center,
                                  style: typography.Body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 26,
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                Text(
                                  "Activate your platform license for a tailored experience.",
                                  textAlign: TextAlign.center,
                                  style: typography.Body1.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: CustomSpacing.three),
                                Expanded(
                                  child: Card(
                                    margin:
                                        EdgeInsets.only(right: 18, left: 20),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: Color(0xFF8A3A75),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: pricingProvider.isLoading
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : ListView.builder(
                                              itemCount: pricingProvider
                                                  .pricingList.length,
                                              itemBuilder: (context, index) {
                                                Result item = pricingProvider
                                                    .pricingList[index];
                                                return Column(
                                                  children: [
                                                    index == 0
                                                        ? _buildSubscriptionHeaderCard()
                                                        : SizedBox(),
                                                    index == 0
                                                        ? SizedBox(
                                                            height:
                                                                CustomSpacing
                                                                    .four)
                                                        : Container(),
                                                    Consumer<
                                                        UserProfileProvider>(
                                                      builder: (context,
                                                          userProfileProvider,
                                                          child) {
                                                        bool isNotIndividual =
                                                            (userProfileProvider
                                                                    .userData
                                                                    .isIndividual ??
                                                                true);

                                                        if (item.planName ==
                                                                "User License" &&
                                                            isNotIndividual) {
                                                          return AbsorbPointer(
                                                              absorbing: true,
                                                              child:
                                                                  Container());
                                                        }
                                                        return _buildSubscriptionCard(
                                                            item, index);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubscriptionCard(Result item, int index) {
    var typography = CustomTypography(context);
    bool isExpanded = expandedCardIndex == index;

    cardSelections.putIfAbsent(index, () => SelectedPlanState());

    final selection = cardSelections[index]!;

    List<String> userCountOptions = [];
    List<RangeYear> selectedRangeList = [];

    if (selection.selectedPlanType == 'Monthly' && item.rangeMonth != null) {
      selectedRangeList = item.rangeMonth!;
      userCountOptions = selectedRangeList
          .map((range) => '${range.startCount!}-${range.endCount!}')
          .toList();
    } else if (selection.selectedPlanType == 'Yearly' &&
        item.rangeYear != null) {
      selectedRangeList = item.rangeYear!;
      userCountOptions = selectedRangeList
          .map((range) => '${range.startCount}-${range.endCount}')
          .toList();
    }

    if (selection.selectedUserCount.isNotEmpty) {
      final selectedRange = selectedRangeList.firstWhere(
        (range) =>
            '${range.startCount}-${range.endCount}' ==
            selection.selectedUserCount,
        orElse: () => RangeYear(
          startCount: '0',
          endCount: '0',
          pricePerUser: "0",
          rangePrice: 0,
        ),
      );
      int start = selectedRange.startCount is int
          ? selectedRange.startCount
          : int.tryParse(selectedRange.startCount.toString()) ?? 0;

      int end = selectedRange.endCount is int
          ? selectedRange.endCount
          : int.tryParse(selectedRange.endCount.toString()) ?? 0;

      int numberOfUsers = end - 0;
      print(numberOfUsers);

      int pricePerUser = selectedRange.pricePerUser is int
          ? selectedRange.pricePerUser
          : int.tryParse(selectedRange.pricePerUser.toString()) ?? 0;
      print(pricePerUser);

      // selection.totalPrice = numberOfUsers * pricePerUser;
      // print(selection.totalPrice);
      print("selection.totalPrice");
    }
    final filteredRanges = selectedRangeList
        .where((range) => range.vendorNameLabel == vendorName)
        .toList();
    // Helper function to get price based on plan type
    Map<String, dynamic> getPriceData(
        Map<String, dynamic> vendor, String planType) {
      final rangePrice = vendor['range_price'] ?? 0;

      if (planType == 'Monthly') {
        return {
          'range_month': rangePrice,
          'range_year': rangePrice * 12,
        };
      } else {
        return {
          'range_month': (rangePrice / 12).round(),
          'range_year': rangePrice,
        };
      }
    }

// Check if dropdown should be enabled
    bool isDropdownEnabled = filteredRanges.isNotEmpty;
    return GestureDetector(
      onTap: () {
        setState(() {
          expandedCardIndex = expandedCardIndex == index ? null : index;
        });
      },
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 1,
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.planName ?? "Location Count (Hazard)",
                      maxLines: 2,
                      style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF99CCFF),
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down_circle_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReadMoreText(
                      text: item.description ?? "Default description...",
                      trimLines: 10,
                      colorClickableText: Colors.blueAccent,
                      trimCollapsedText: 'Read more',
                      trimExpandedText: 'Show less',
                      style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (Platform.isIOS) ...[
                SizedBox(height: 16),
                Container(
                  child: Text(
                    "Requires an active license. Please sign in with your licensed account to use this feature.",
                    style: typography.Body1.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFFFDBE71)),
                  ),
                )
              ] else if (isExpanded) ...[
                const SizedBox(height: 16),
                item.planName == "Event Count Cost"
                    ? DropdownButtonFormField<String>(
                        value: selection.selectedPlanType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: "Subscription Type",
                        ),
                        hint: const Text("Subscription Type"),
                        items: [
                          if (item.rangeMonth != null &&
                              item.rangeMonth!.isNotEmpty)
                            DropdownMenuItem<String>(
                              value: 'Monthly',
                              child: Text('Monthly'),
                            ),
                          if (item.rangeYear != null &&
                              item.rangeYear!.isNotEmpty)
                            DropdownMenuItem<String>(
                              value: 'Yearly',
                              child: Text('Yearly'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            print(value);
                            print("value");
                            setState(() {
                              selection.selectedPlanType = value;

                              item.planName == "Event Count Cost"
                                  ? selection.title = "Event Count Cost"
                                  : "";
                              item.planName == "Event Count Cost"
                                  ? selection.planId = item.planId!
                                  : '';
                              item.planName == "Event Count Cost"
                                  ? selection.planType = item.planType!
                                  : '';
                              // item.planName == "Event Count Cost"
                              //     ? value == 'Monthly'
                              //         ? selection.priceperuser =
                              //             item.rangeMonth![0].pricePerUser
                              //         : selection.priceperuser =
                              //             item.rangeYear![0].pricePerUser
                              //     : "";
                              // item.planName == "Event Count Cost"
                              //     ? value == 'Monthly'
                              //         ? selection.licensePrice =
                              //             item.rangeMonth![0].pricePerUser
                              //         : selection.priceperuser =
                              //             item.rangeYear![0].pricePerUser
                              //     : "";
                              // selection.userCount = item.planName ==
                              //         "Event Count Cost"
                              //     ? (value == 'Monthly'
                              //         ? '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}'
                              //         : '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}')
                              //     : selection.userCount;
                            });
                          }
                        },
                      )
                    : DropdownButtonFormField<String>(
                        value: selection.selectedPlanType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: "Subscription Type",
                        ),
                        hint: const Text("Subscription Type"),
                        items: [
                          if (item.rangeMonth != null &&
                              item.rangeMonth!.isNotEmpty)
                            DropdownMenuItem<String>(
                              value: 'Monthly',
                              child: Text('Monthly'),
                            ),
                          if (item.rangeYear != null &&
                              item.rangeYear!.isNotEmpty)
                            DropdownMenuItem<String>(
                              value: 'Yearly',
                              child: Text('Yearly'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            print(value);
                            print("value");
                            setState(() {
                              selection.selectedPlanType = value;
                              selection.selectedUserCount = '1-1';
                              selection.totalPrice = null;

                              item.planName == "Event Count Cost"
                                  ? value == 'Monthly'
                                      ? selection.totalPrice =
                                          item.rangeMonth![0].rangePrice
                                      : selection.totalPrice =
                                          item.rangeYear![0].rangePrice
                                  : "";
                              item.planName == "Event Count Cost"
                                  ? selection.title = "Event Count Cost"
                                  : "";
                              item.planName == "Event Count Cost"
                                  ? selection.planId = item.planId!
                                  : '';
                              item.planName == "Event Count Cost"
                                  ? selection.planType = item.planType!
                                  : '';
                              item.planName == "Event Count Cost"
                                  ? value == 'Monthly'
                                      ? selection.priceperuser =
                                          item.rangeMonth![0].pricePerUser
                                      : selection.priceperuser =
                                          item.rangeYear![0].pricePerUser
                                  : "";
                              item.planName == "Event Count Cost"
                                  ? value == 'Monthly'
                                      ? selection.licensePrice =
                                          item.rangeMonth![0].pricePerUser
                                      : selection.priceperuser =
                                          item.rangeYear![0].pricePerUser
                                  : "";
                              selection.userCount = item.planName ==
                                      "Event Count Cost"
                                  ? (value == 'Monthly'
                                      ? '${item.rangeMonth![0].startCount}-${item.rangeMonth![0].endCount}'
                                      : '${item.rangeYear![0].startCount}-${item.rangeYear![0].endCount}')
                                  : selection.userCount;
                            });
                          }
                        },
                      ),
                const SizedBox(height: 16),
                item.planName == "Event Count Cost"
                    ? SizedBox()
                    : DropdownButtonFormField<String>(
                        value: userCountOptions
                                .contains(selection.selectedUserCount)
                            ? selection.selectedUserCount
                            : null,
                        decoration: InputDecoration(
                          labelText: item.planName == "User License"
                              ? "Select User"
                              : "Select Locations",
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        items: userCountOptions.map((rangeLabel) {
                          return DropdownMenuItem<String>(
                              value: rangeLabel,
                              child: Text(
                                  '$rangeLabel ${item.planName == "User License" ? "User" : "Locations"}'));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              // Set the selected user count from dropdown value
                              selection.selectedUserCount = value;

                              // Set title from the item
                              selection.title =
                                  item.planName ?? "Location Count (Hazard)";

                              // Find the selected range from the list
                              final selectedRange =
                                  selectedRangeList.firstWhere(
                                (range) =>
                                    '${range.startCount}-${range.endCount}' ==
                                    value,
                                orElse: () => RangeYear(
                                  startCount: '0',
                                  endCount: '0',
                                  pricePerUser: "0",
                                  rangePrice: 0,
                                ),
                              );
                              // Reformat selected user count (for consistency)
                              selection.selectedUserCount =
                                  '${selectedRange.endCount}-${selectedRange.startCount}';
                              selection.planId = item.planId ?? '';
                              selection.planType = item.planType ?? '';

                              // Parse start and end counts
                              int start = int.tryParse(
                                      selectedRange.startCount.toString()) ??
                                  0;
                              int end = int.tryParse(
                                      selectedRange.endCount.toString()) ??
                                  0;
                              int numberOfUsers = end - 0;
                              selection.userCount =
                                  start.toString() + '-' + end.toString();

                              print(
                                  'Selected Range → Start: $start, End: $end');
                              print(selection.planType.toString());
                              print(selection.priceperuser.toString());
                              print(selectedRange.rangePrice.toString());

                              int pricePerUser = int.tryParse(
                                      selectedRange.pricePerUser.toString()) ??
                                  0;
                              print(pricePerUser.toString());
                              selection.totalPrice =
                                  selectedRange.rangePrice.toString();
                              print(totalPrice.toString());
                              selection.licensePrice =
                                  selectedRange.rangePrice.toString();
                              selection.priceperuser =
                                  selection.licensePrice.toString();
                            });
                          }
                        },
                      ),


                SizedBox(height: 2),
                if (item.planName == "Event Count Cost" ||
                    item.planName!.contains('event')) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: DropdownButtonFormField<String>(
                      value: (selection.selectedPlanType.toString() == "Yearly"
                                      ? item.rangeYear
                                      : item.rangeMonth)
                                  ?.any((rangeItem) =>
                                      rangeItem.vendorId == selectedVendor) ==
                              true
                          ? selectedVendor
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        labelText: 'Select Vendor',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      dropdownColor: Colors.grey[850],
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      items: (selection.selectedPlanType.toString() == "Yearly"
                              ? item.rangeYear
                              : item.rangeMonth)!
                          .fold<List<DropdownMenuItem<String>>>([],
                              (prev, rangeItem) {
                        if (!prev.any((e) => e.value == rangeItem.vendorId)) {
                          prev.add(DropdownMenuItem<String>(
                            value: rangeItem.vendorId,
                            child: Text(
                              rangeItem.vendorNameLabel ?? 'Unknown',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ));
                        }
                        return prev;
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedVendor = value;
                          selectedHazard = null;
                          // hazardName = '';

                          final rangeList =
                              selection.selectedPlanType.toString() == "Yearly"
                                  ? item.rangeYear
                                  : item.rangeMonth;

                          final selected =
                              (rangeList?.any((r) => r.vendorId == value) ??
                                      false)
                                  ? rangeList!
                                      .firstWhere((r) => r.vendorId == value)
                                  : null;

                          vendorName = selected?.vendorNameLabel ?? 'Unknown';
                          hazardName = selected?.hazardNameLabel ?? '';
                          item.planName == "Event Count Cost"
                              ? selection.title = "Event Count Cost"
                              : "";

                          print(
                              "Selected Hazard: $selectedHazard, Name: $hazardName");
                          // Automatically set hazardName if vendor has only 1 hazard
                          if (selectedVendor != null) {
                            final vendorData = vendorList.firstWhere(
                              (v) => v['vendor_id'] == selectedVendor,
                              orElse: () => {},
                            );

                            final hazards =
                                (vendorData['hazard_commercials'] as List?) ??
                                    [];

                            if (hazards.length == 1) {
                              selectedHazard = hazards[0]['hazard_id'];
                              // hazardName = hazards[0]['hazard_name_label'] ?? '';
                            }
                          }
                        });
                      },
                      validator: (value) {
                        if (isEventCost && (value == null || value.isEmpty)) {
                          return 'Vendor is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  hazardName.toString().isEmpty
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: DropdownButtonFormField<String>(
                            value: (selection.selectedPlanType.toString() ==
                                                "Yearly"
                                            ? item.rangeYear
                                            : item.rangeMonth)
                                        ?.any((rangeItem) =>
                                            rangeItem.hazardNameLabel ==
                                            hazardName) ==
                                    true
                                ? selectedHazard
                                : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[800],
                              labelText: 'Select Hazard',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            dropdownColor: Colors.grey[850],
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            items: (selection.selectedPlanType.toString() ==
                                        "Yearly"
                                    ? item.rangeYear
                                    : item.rangeMonth)!
                                .where((rangeItem) =>
                                    rangeItem.hazardNameLabel ==
                                    hazardName) // Filter here
                                .fold<List<DropdownMenuItem<String>>>([],
                                    (prev, rangeItem) {
                              if (!prev
                                  .any((e) => e.value == rangeItem.hazardId)) {
                                prev.add(DropdownMenuItem<String>(
                                  value: rangeItem.hazardId,
                                  child: Text(
                                    rangeItem.hazardNameLabel ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ));
                              }
                              return prev;
                            }),
                            onChanged: (value) {
                              setState(() {
                                selectedHazard = value;
                                final rangeList =
                                    selection.selectedPlanType.toString() ==
                                            "Yearly"
                                        ? item.rangeYear
                                        : item.rangeMonth;

                                final selected = (rangeList?.any((r) =>
                                            r.hazardId == value &&
                                            r.hazardNameLabel == hazardName) ??
                                        false)
                                    ? rangeList!.firstWhere((r) =>
                                        r.hazardId == value &&
                                        r.hazardNameLabel == hazardName)
                                    : null;

                                vendorName =
                                    selected?.vendorNameLabel ?? 'Unknown';
                                hazardName = selected?.hazardNameLabel ?? '';
                                item.planName == "Event Count Cost"
                                    ? selection.title = "Event Count Cost"
                                    : "";

                                print(
                                    "Selected Hazard: $selectedHazard, Name: $hazardName");

                                if (selectedVendor != null) {
                                  final vendorData = vendorList.firstWhere(
                                    (v) => v['vendor_id'] == selectedVendor,
                                    orElse: () => {},
                                  );

                                  final hazards =
                                      (vendorData['hazard_commercials']
                                              as List?) ??
                                          [];

                                  if (hazards.length == 1) {
                                    selectedHazard = hazards[0]['hazard_id'];
                                  }
                                }
                              });
                            },
                            validator: (value) {
                              if (isEventCost &&
                                  (value == null || value.isEmpty)) {
                                return 'Hazard is required';
                              }
                              return null;
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  hazardName.toString().isEmpty
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: DropdownButtonFormField<String>(
                            value: selection.selectedUserCount != null &&
                                    userCountOptions
                                        .contains(selection.selectedUserCount)
                                ? selection.selectedUserCount
                                : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[800],
                              labelText: 'Select Locations',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            dropdownColor: Colors.grey[850],
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            items: (selection.selectedPlanType.toString() ==
                                        "Yearly"
                                    ? item.rangeYear
                                    : item.rangeMonth)!
                                .where((rangeItem) =>
                                        rangeItem.hazardNameLabel ==
                                        hazardName // filter by hazardName
                                    )
                                .map((rangeItem) {
                              return DropdownMenuItem<String>(
                                value:
                                    '${rangeItem.startCount}-${rangeItem.endCount}',
                                // Use this as value
                                child: Text(
                                  '${rangeItem.startCount}-${rangeItem.endCount} Locations',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selection.selectedUserCount = value!;
                                final selectedRange =
                                    (selection.selectedPlanType.toString() ==
                                                "Yearly"
                                            ? item.rangeYear
                                            : item.rangeMonth)!
                                        .firstWhere(
                                  (range) =>
                                      '${range.startCount}-${range.endCount}' ==
                                          value &&
                                      range.hazardNameLabel == hazardName,
                                  // ensure hazardName match
                                  orElse: () => RangeYear(
                                    startCount: '0',
                                    endCount: '0',
                                    pricePerUser: "0",
                                    rangePrice: 0,
                                  ),
                                );

                                selection.selectedUserCount =
                                    '${selectedRange.startCount}-${selectedRange.endCount}';

                                selection.planId = item.planId ?? '';
                                selection.planType = item.planType ?? '';
                                selection.title =
                                    item.planName ?? "Location Count (Hazard)";

                                int start =
                                    int.tryParse(selectedRange.startCount) ?? 0;
                                int end =
                                    int.tryParse(selectedRange.endCount) ?? 0;
                                int pricePerUser =
                                    int.tryParse(selectedRange.pricePerUser) ??
                                        0;

                                selection.userCount = '${start}-${end}';
                                selection.totalPrice =
                                    selectedRange.rangePrice.toString();
                                selection.licensePrice =
                                    selectedRange.rangePrice.toString();
                                selection.priceperuser =
                                    selectedRange.pricePerUser.toString();

                                print(
                                    'Selected Range → Start: $start, End: $end');
                                print('Price per user → $pricePerUser');
                                print(
                                    'Total price → ${selectedRange.rangePrice}');
                                print('Total price → ${selection.totalPrice}');
                                print(
                                    'Total price1 → ${selectedRange.pricePerUser}');
                              });
                            },
                            validator: (value) {
                              if (isEventCost &&
                                  (value == null || value.isEmpty)) {
                                return 'Location is required';
                              }
                              return null;
                            },
                          ),
                        ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionHeaderCard() {
    var typography = CustomTypography(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.amber,
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(120, 100, 117, 0.16),
            Color.fromRGBO(236, 118, 116, 0.07),
            Color.fromRGBO(253, 195, 123, 0.12),
          ],
        ),
      ),
      child: Card(
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Risksphere Global License ",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: Color(0xFFFDBE71),
                  ),
                ),
              ),
              SizedBox(height: CustomSpacing.three),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Risksphere Global License is applicable for the following",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
