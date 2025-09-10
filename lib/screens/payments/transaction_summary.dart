import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../../utils/global_imports.dart';
import 'package:RiskSphere/providers/invoice_provider.dart';
import 'package:RiskSphere/screens/payments/purchase_license.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/invoice_model.dart';
import '../../providers/payment_provider.dart';
import 'invoice_webview.dart';

class PaymentTransactionsPage extends StatefulWidget {
  const PaymentTransactionsPage({super.key});

  @override
  State<PaymentTransactionsPage> createState() =>
      _PaymentTransactionsPageState();
}

class _PaymentTransactionsPageState extends State<PaymentTransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _tabIndex;
  String filterItem = "";
  bool isHasAnyPlan = false;

  PaymentProvider get paymentProvider =>
      Provider.of<PaymentProvider>(context, listen: false);

  InvoiceProvider get invoiceProvider =>
      Provider.of<InvoiceProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
      _setClaims();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Only run when tab has changed
        _tabIndex = _tabController.index;

        print("Current Tab Index: $_tabIndex");

        if (_tabIndex == 0) {
          paymentProvider.fetchTransactionList(
            context,
            filterItem ?? '',
            '',
          );
        } else if (_tabIndex == 1) {
          invoiceProvider.fetchInvoiceList(
            context,
            filterItem ?? '',
          );
        }
      }
    });
  }

  Future<void> _setClaims() async {
    isHasAnyPlan = await SharedPreferenceService.getHasAnyPlan();
  }

  Future<void> _getData() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final provider1 = Provider.of<InvoiceProvider>(context, listen: false);
    await Future.wait([
      provider1.fetchInvoiceList(context, ''),
      provider.fetchTransactionList(context, '', ''),
    ]);
  }

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  DateTime? startDate;
  DateTime? endDate;
  String _selectedValue = 'All License';

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var typography = CustomTypography(context);
    String dateText = startDate != null && endDate != null
        ? "${DateFormat('MM/dd/yyyy').format(startDate!)} \n- ${DateFormat('MM/dd/yyyy').format(endDate!)}"
        : "This Month";
    bool _isExpanded = false;
    bool _showNotificationDot = true;

    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: SafeArea(
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
          body: Consumer<UserProfileProvider>(
              builder: (context, userProfile, child) {
            final trialStatus = userProfile.trialInfo['status'] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Center(
                  child: TabBar(
                    onTap: (value) {
                      setState(() {
                        value == _tabIndex;
                        filterItem = "";
                        _selectedValue = 'All License';
                      });
                      print(_tabIndex);
                      print(value);
                      print(_tabController.index);
                    },
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: Colors.lightBlueAccent,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: Colors.lightBlueAccent,
                    indicatorWeight: 1,
                    tabs: [
                      Tab(text: 'Payment Transactions'),
                      Tab(text: 'Invoice History'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (trialStatus.contains('Expired') &&
                    isHasAnyPlan == false) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.95),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: CustomSpacing.four),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MessageCard(
                            messageTextSpans: [
                              TextSpan(
                                text:
                                    'We hope you\'ve enjoyed your trial period! To continue accessing your account and keep your data safe, please upgrade before December 24, 2025. After this date, we will need to delete your data. Thank you for being with us!',
                                style: typography.Body1,
                              ),
                              // tappable
                              TextSpan(
                                text: ' Upgrade Now!',
                                style: typography.Body1.copyWith(
                                  color: AppColors.primaryMain,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                PurchaseLicensePage()));
                                  },
                              ),
                            ],
                            isError: true,
                          ),
                        ),
                      ],
                    ),
                  )
                ] else ...[
                  Consumer2<PaymentProvider, InvoiceProvider>(
                    builder:
                        (context, paymentProvider, invoiceProvider, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.only(right: 3, left: 10),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 1.0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedValue,
                                style: const TextStyle(color: Colors.white),
                                items: [
                                  'All License',
                                  'Event Count Cost',
                                  'Location Count(Geocoding)',
                                  'Location Count(Hazard)',
                                  'Location Improvement Cost',
                                  'User License'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedValue = newValue;
                                    });

                                    final valueMap = {
                                      'All License': '',
                                      'Event Count Cost': 'event_cost',
                                      'Location Count(Geocoding)':
                                          'location_geocoding',
                                      'Location Count(Hazard)':
                                          'location_hazard',
                                      'Location Improvement Cost':
                                          'location_improvement_cost',
                                      'User License': 'user_cost',
                                    };
                                    setState(() {
                                      filterItem = valueMap[newValue] ?? '';
                                    });

                                    // Find the selected index
                                    int selectedIndex = [
                                      'All License',
                                      'Event Count Cost',
                                      'Location Count(Geocoding)',
                                      'Location Count(Hazard)',
                                      'Location Improvement Cost',
                                      'User License'
                                    ].indexOf(newValue);

                                    if (_tabController.index == 0) {
                                      print(_tabController.indexIsChanging
                                          .toString());

                                      paymentProvider.fetchTransactionList(
                                        context,
                                        valueMap[newValue] ?? '',
                                        '',
                                      );
                                    } else if (_tabController.index == 1) {
                                      print(_tabController.indexIsChanging
                                          .toString());

                                      invoiceProvider.fetchInvoiceList(
                                        context,
                                        valueMap[newValue] ?? '',
                                      );
                                    } else {
                                      invoiceProvider.fetchInvoiceList(
                                        context,
                                        valueMap[newValue] ?? '',
                                      );
                                    }
                                  }
                                },

                                underline: const SizedBox(),
                                // Removes the default underline
                                dropdownColor: const Color(
                                    0xFF1E1E1E), // Optional: Matches the theme
                              ),
                            ),
                            SizedBox(width: 10),
                            Container(
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.blue,
                                    width: 1.0), // Blue border
                              ),
                              child: TextButton(
                                onPressed: () => _selectDateRange(context),
                                child: Text(
                                  dateText,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  // style: typography.Body2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        _buildTransactionsHistoryList(),
                        _buildInvoiceHistoryList(),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      var date =
          '?start_date=${formatDateOnly(picked.start)}&end_date=${formatDateOnly(picked.end)}';

      await Provider.of<PaymentProvider>(context, listen: false)
          .fetchTransactionList(context, '', date);
    }
  }

  String formatDateOnly(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _buildTransactionsHistoryList() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final transactions = paymentProvider.transactions;
        return paymentProvider.isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : paymentProvider.transactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await paymentProvider.fetchTransactionList(
                          context, filterItem, '');
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, outerIndex) {
                        const double inrToUsdRate = 1 / 100;
                        final transaction = transactions[outerIndex];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(
                                  DateTime.parse('${transaction.month}-01')),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              itemCount: transaction.invoices?.length ?? 0,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, innerIndex) {
                                final invoice =
                                    transaction.invoices![innerIndex];
                                DateTime date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        invoice.createdAt!.iSeconds! * 1000);
                                String formattedDate =
                                    "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.70,
                                              child: InkWell(
                                                onTap: () {
                                                  // Navigate to invoice details
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          InvoiceWebViewPage(
                                                        url: invoice
                                                                .stripeInvoice
                                                                ?.hostedInvoiceUrl ??
                                                            '',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                    "Inv# ${invoice.invoiceId ?? 'N/A'}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                      locale: 'en_US',
                                                      symbol: '\$')
                                                  .format(
                                                (double.tryParse(invoice.amount
                                                            .toString()) ??
                                                        0.0) *
                                                    inrToUsdRate,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          invoice.plans != null &&
                                                  invoice.plans!.isNotEmpty
                                              ? invoice.plans!
                                                  .map((e) =>
                                                      _capitalizeFirstLetter(
                                                          e.planType ?? "N/A"))
                                                  .join(", ")
                                              : "No plans",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          invoice.plans != null &&
                                                  invoice.plans!.isNotEmpty
                                              ? invoice.plans!
                                                  .map((e) =>
                                                      e.planName ??
                                                      "License Info")
                                                  .join(", ")
                                              : "License Info",
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    formattedDate,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: invoice.status ==
                                                              "paid"
                                                          ? Colors.green
                                                              .withOpacity(0.2)
                                                          : Colors.red
                                                              .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      invoice.status == "paid"
                                                          ? "Success"
                                                          : "Failed",
                                                      style: TextStyle(
                                                        color: invoice.status ==
                                                                "paid"
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (Platform.isIOS)
                                              IconButton(
                                                icon: Icon(Icons.download,
                                                    size: 16),
                                                onPressed: () async {
                                                  final url =
                                                      invoice.invoicePdfUrl ??
                                                          '';
                                                  if (url.isEmpty) {
                                                    debugPrint(
                                                        "Empty invoice URL.");
                                                    return;
                                                  }

                                                  debugPrint(
                                                      "Invoice URL: $url");

                                                  try {
                                                    Directory? directory;

                                                    // if (Platform.isAndroid) {
                                                    //   if (await Permission
                                                    //           .manageExternalStorage
                                                    //           .request()
                                                    //           .isGranted ||
                                                    //       await Permission.storage
                                                    //           .request()
                                                    //           .isGranted) {
                                                    //     if (Platform.version
                                                    //         .contains('30')) {
                                                    //       directory =
                                                    //           await getExternalStorageDirectory(); // Scoped
                                                    //     } else {
                                                    //       directory = Directory(
                                                    //           '/storage/emulated/0/Download'); // Legacy
                                                    //     }
                                                    //   } else {
                                                    //     ScaffoldMessenger.of(
                                                    //             context)
                                                    //         .showSnackBar(
                                                    //       SnackBar(
                                                    //           content: Text(
                                                    //               'Storage permission denied')),
                                                    //     );
                                                    //     return;
                                                    //   }
                                                    // } else
                                                    if (Platform.isIOS) {
                                                      directory =
                                                          await getApplicationDocumentsDirectory();
                                                    }

                                                    if (directory == null) {
                                                      throw Exception(
                                                          "❌ Cannot determine save directory.");
                                                    }

                                                    final filename =
                                                        'invoice_${invoice.invoiceId ?? DateTime.now().millisecondsSinceEpoch}.pdf';
                                                    final filePath = path.join(
                                                        directory.path,
                                                        filename);

                                                    debugPrint(
                                                        "📁 Will save file to: $filePath");

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Row(
                                                          children: [
                                                            CircularProgressIndicator(),
                                                            SizedBox(width: 10),
                                                            Text(
                                                                'Downloading invoice...'),
                                                          ],
                                                        ),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );

                                                    final dio = Dio();
                                                    await dio.download(
                                                      url,
                                                      filePath,
                                                      onReceiveProgress:
                                                          (received, total) {
                                                        if (total != -1) {
                                                          debugPrint(
                                                              '⬇️ Progress: ${(received / total * 100).toStringAsFixed(0)}%');
                                                        }
                                                      },
                                                    );

                                                    debugPrint(
                                                        " File downloaded to: $filePath");

                                                    final file = File(filePath);
                                                    if (!await file.exists()) {
                                                      throw Exception(
                                                          "File not found at $filePath after download.");
                                                    }

                                                    final fileSize =
                                                        await file.length();
                                                    debugPrint(
                                                        " File size: $fileSize bytes");

                                                    if (fileSize == 0) {
                                                      throw Exception(
                                                          " File is empty. Invalid or broken download.");
                                                    }
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Invoice downloaded successfully'),
                                                        action: SnackBarAction(
                                                          label: 'OPEN',
                                                          onPressed: () async {
                                                            try {
                                                              final result =
                                                                  await OpenFile
                                                                      .open(
                                                                          filePath);
                                                              debugPrint(
                                                                  " OpenFile result: ${result.message}");
                                                              if (result.type !=
                                                                  ResultType
                                                                      .done) {
                                                                throw Exception(
                                                                    "Failed to open file: ${result.message}");
                                                              }
                                                            } catch (e) {
                                                              debugPrint(
                                                                  " Open file error: $e");
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                    content: Text(
                                                                        'Could not open file: $e')),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        duration: Duration(
                                                            seconds: 4),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    debugPrint(" Error: $e");
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Download failed: ${e.toString()}'),
                                                        duration: Duration(
                                                            seconds: 4),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  );
      },
    );
  }

  Widget _buildInvoiceHistoryList() {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        final transactions = invoiceProvider.transactions;

        if (invoiceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'No invoices found',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await invoiceProvider.fetchInvoiceList(context, filterItem);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, monthIndex) {
              final monthBlock = transactions[monthIndex];

              final entries = monthBlock.plans?.entries.entries.toList() ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy')
                            .format(DateTime.parse('${monthBlock.month}-01')),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    itemCount: entries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, entryIndex) {
                      final planEntry = entries[entryIndex];
                      final planList = planEntry.value;

                      return Column(
                        children: planList.map((invoiceData) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262626),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.lightBlueAccent.withOpacity(.25),
                                width: 1,
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.grey.shade400,
                                iconColor: Colors.grey.shade400,
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoiceData.planName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                        children: [
                                          const TextSpan(
                                              text: 'User count left: '),
                                          TextSpan(
                                            text: invoiceData.availableCredits
                                                .toString(),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _InfoRow(
                                            label: 'Purchased by',
                                            value: invoiceData.userName ?? ''),
                                        _InfoRow(
                                            label: 'Invoice no',
                                            value: invoiceData.invoiceNumber ??
                                                ''),
                                        _InfoRow(
                                            label: 'Count Range',
                                            value: invoiceData
                                                    .plan?.selectedPlan ??
                                                ''),
                                        _InfoRow(
                                          label: 'Subscription Type',
                                          value: invoiceData.plan?.planType !=
                                                  null
                                              ? '${invoiceData.plan!.planType![0].toUpperCase()}${invoiceData.plan!.planType!.substring(1)}'
                                              : '',
                                        ),
                                        _InfoRow(
                                          label: 'Billing Period',
                                          value:
                                              '${_formatDate(invoiceData.transactionDate)} - ${_formatDate(invoiceData.expiresAt)}',
                                        ),
                                        const SizedBox(height: 14),

                                        // ─── Deductions ───
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              invoiceData.deductions?.length ??
                                                  0,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, lineIndex) {
                                            final deduction = invoiceData
                                                .deductions![lineIndex];
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF383838),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _formatDate(deduction
                                                              .deductionDate),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${deduction.counts} New Users',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '\$${double.parse(deduction.totalCost.toString() ?? "0")}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '\$${(deduction.unitCost ?? 0)}/ user',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

String _formatDate(DeductionDate? date) {
  if (date == null || date.iSeconds == null) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(date.iSeconds! * 1000);
  return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
