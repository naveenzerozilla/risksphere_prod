import 'dart:async';
import 'dart:io';
import 'package:RiskSphere/models/PricingModel.dart';
import 'package:RiskSphere/screens/listings/pricing_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:RiskSphere/providers/account_list_provider.dart';
import 'package:provider/provider.dart';
import '../../constants/enums.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';
import '../../providers/drawer_selection_provider.dart';
import '../../providers/theme_provider.dart';

class PricingListScreen extends StatefulWidget {
  static const String routeName = '/pricingList';

  const PricingListScreen({
    super.key,
  });

  @override
  State<PricingListScreen> createState() => _PricingListScreenState();
}

class _PricingListScreenState extends State<PricingListScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showNotificationDot = true;
  Screens _selectedScreen = Screens.accountList;
  TextEditingController mobileController = TextEditingController();
  bool isLoading = false;
  bool isExpanded = false;
  String selectedUserCount = '0';
  String selectedPlanType = '';
  String planId = '';

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
    await accountListProvider.fetchPricingList(context, "", 1, 5);
  }

  @override
  Widget build(BuildContext context1) {
    var typography = CustomTypography(context);
    return SafeArea(
      child: Consumer<ThemeProvider>(
          builder: (buildContext, themeProvider, child) {
        Map<String, dynamic> getSummary() {
          int total = 0;
          List<String> titles = [];
          List<String> planId = [];
          List<String> licensePrice = [];
          List<String> userCounts = [];
          List<String> selectedPlanType = [];
          List<String> priceperuser = [];

          // selection.selectedPlanType
          for (var selection in cardSelections.values) {
            if (selection.totalPrice != null) {
              total += selection.totalPrice!;

              if (selection.title != null && selection.title!.isNotEmpty) {
                titles.add(selection.title!);
              }
              if (selection.planId != null && selection.planId!.isNotEmpty) {
                planId.add(selection.planId!);
              }
              if (selection.licensePrice != null &&
                  selection.licensePrice!.isNotEmpty) {
                licensePrice.add(selection.licensePrice!);
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
            'selectedPlanType': selectedPlanType
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
              showDropdown: true,
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
            bottomNavigationBar: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        '\$${getSummary()['total'] ?? 0}',
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
                      final titles = List<String>.from(summary['titles'] ?? []);
                      if (titles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                            "Please select at least one subscription plan.",
                          )),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PricingSummary(
                            title: titles,
                            summary: summary,
                          ),
                        ),
                      ).then((value) {
                        _getData();
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
            ),
            body: Consumer<AccountListProvider>(
              builder: (context, pricingProvider, child) {
                var typography = CustomTypography(context);
                return Padding(
                  padding: EdgeInsets.all(0), // optional for spacing
                  child: Column(
                    children: [
                      SizedBox(height: CustomSpacing.six),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
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
                          fontWeight: FontWeight.w400,
                          fontSize: 28,
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
                            child: ListView(
                              children: [
                                _buildSubscriptionHeaderCard(),
                                SizedBox(height: CustomSpacing.three),
                                pricingProvider.isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : Container(
                                        height: 203,
                                        width: 400,
                                        child: ListView.builder(
                                          itemCount: pricingProvider
                                              .pricingList.length,
                                          itemBuilder: (context, index) {
                                            Result item = pricingProvider
                                                .pricingList[index];
                                            return Column(
                                              children: [
                                                _buildSubscriptionCard(
                                                    item, index),
                                              ],
                                            ); // pass item if needed
                                          },
                                        ),
                                      )
                              ],
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

      int numberOfUsers = end - start;

      int pricePerUser = selectedRange.pricePerUser is int
          ? selectedRange.pricePerUser
          : int.tryParse(selectedRange.pricePerUser.toString()) ?? 0;

      selection.totalPrice = numberOfUsers * pricePerUser;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedCardIndex = expandedCardIndex == index ? null : index;
        });
      },
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 1,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                  Text(
                    item.planName ?? "Location Count (Hazard)",
                    style: typography.Body1.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down_circle_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description ?? "Default description...",
                style: typography.Body1.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selection.selectedPlanType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    labelText: "Subscription Type",
                  ),
                  hint: const Text("Select"),
                  items: ['Monthly', 'Yearly'].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selection.selectedPlanType = value;
                        selection.selectedUserCount = '';
                        selection.totalPrice = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                /// User Count Dropdown
                DropdownButtonFormField<String>(
                  value: userCountOptions.contains(selection.selectedUserCount)
                      ? selection.selectedUserCount
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Select",
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  items: userCountOptions.map((rangeLabel) {
                    return DropdownMenuItem<String>(
                      value: rangeLabel,
                      child: Text('$rangeLabel Locations'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        // Set the selected user count from dropdown value
                        selection.selectedUserCount = value;

                        // Set title from the item
                        selection.title =
                            item.planType ?? "Location Count (Hazard)";

                        // Find the selected range from the list
                        final selectedRange = selectedRangeList.firstWhere(
                          (range) =>
                              '${range.startCount}-${range.endCount}' == value,
                          orElse: () => RangeYear(
                            startCount: '0',
                            endCount: '0',
                            pricePerUser: "0",
                            rangePrice: 0,
                          ),
                        );
                        // Reformat selected user count (for consistency)
                        selection.selectedUserCount =
                            '${selectedRange.startCount}-${selectedRange.endCount}';
                        selection.planId = item.planId ?? '';
                        // Parse start and end counts
                        int start =
                            int.tryParse(selectedRange.startCount.toString()) ??
                                0;
                        int end =
                            int.tryParse(selectedRange.endCount.toString()) ??
                                0;
                        int numberOfUsers = end - start;
                        selection.userCount =
                            start.toString() + '-' + end.toString();

                        print('Selected Range → Start: $start, End: $end');

                        // Calculate total price
                        int pricePerUser = int.tryParse(
                                selectedRange.pricePerUser.toString()) ??
                            0;
                        selection.totalPrice = numberOfUsers * pricePerUser;
                        selection.licensePrice =
                            selection.totalPrice!.toString();
                        selection.priceperuser = pricePerUser.toString();
                        // Store total price as license price  ;
                      });
                    }
                  },
                ),
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
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color.fromRGBO(112, 46, 117, 0.16),
            Color.fromRGBO(236, 118, 116, 0.07),
            Color.fromRGBO(253, 195, 123, 0.12),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Risksphere Global License ",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w600,
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
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: CustomSpacing.three),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "Companies : All",
                  style: typography.Body1.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white70,
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
