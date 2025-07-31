import '../../utils/global_imports.dart';
import '../../providers/payment_provider.dart';

class PricingSummary extends StatefulWidget {
  final List<String>? title;
  final Map<String, dynamic> summary;
  final String? hazardName;
  final String? vendorName;

  PricingSummary(
      {super.key,
      this.title,
      required this.summary,
      this.hazardName,
      this.vendorName});

  @override
  State<PricingSummary> createState() => _PricingSummaryState();
}

class _PricingSummaryState extends State<PricingSummary> {
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  Widget build(BuildContext context) {
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
        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    "\$" + widget.summary['total'].toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Consumer<PaymentProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.makePayment(
                              context: context,
                              amount: widget.summary['total'].toString(),
                              currency: 'usd',
                              summary: widget.summary,
                              hazardName: widget.hazardName,
                              vendorName: widget.vendorName,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF99CCFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Subscribe now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                icon: Icon(Icons.arrow_back_ios, size: 20)),
            Expanded(
              child: Card(
                elevation: 2,
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Color(0xFF8A3A75),
                    width: 0.8,
                  ),
                ),
                child: ListView.builder(
                  itemCount: widget.summary['titles'].length,
                  itemBuilder: (context, index) {
                    final item = widget.summary;
                    if (item['cancelled'] != null &&
                        item['cancelled'][index] == true) {
                      return SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Text(
                                  item['titles'][index].toString(),
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  debugPrint(item.toString());
                                  print(item);
                                  setState(() {
                                    // Mark item as cancelled
                                    if (item['cancelled'] == null) {
                                      item['cancelled'] = List.filled(
                                          item['titles'].length, false);
                                    }
                                    item['cancelled'] = List.filled(
                                        item['titles'].length, false,
                                        growable: true);
                                    //hfdshakhfsdkfajvjh Remove license price from total
                                    var total = item['total'].toString();
                                    var licensePrice = "0";
                                    if (item['licenseprice'] != null &&
                                        item['licenseprice'].length > index) {
                                      licensePrice =
                                          item['licenseprice'][index];
                                    }
                                    item['total'] = (int.parse(total) -
                                        int.parse(licensePrice));
                                    // Remove only the selected item from all lists
                                    final keysToRemove = [
                                      'planId',
                                      'titles',
                                      'licenseprice',
                                      'planType',
                                      'priceperuser',
                                      'usercount',
                                      'selectedPlanType',
                                      'cancelled'
                                    ];
                                    for (final key in keysToRemove) {
                                      if (item[key] != null &&
                                          item[key] is List &&
                                          item[key].length > index) {
                                        item[key].removeAt(index);
                                      }
                                    }
                                  });

                                  double updatedTotal = double.tryParse(
                                          item['total'].toString()) ??
                                      0.0;
                                  if (item['total'].toString().isEmpty ||
                                      updatedTotal == 0.0 ||
                                      (item['titles'] != null &&
                                          item['titles'].isEmpty)) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 25,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (item['usercount'] != null &&
                              item['usercount'].length > index)
                            _buildRow("User count", item['usercount'][index]),
                          _buildRow("Billing", item['selectedPlanType'][index]),
                          if (item['licenseprice'] != null &&
                              item['licenseprice'].length > index)
                            _buildRow("License pricing",
                                "\$${item['licenseprice'][index]} / user"),
                          const SizedBox(height: 3),
                          if (item['titles'][index].toString() ==
                                  "Event Count Cost" &&
                              widget.vendorName != "") ...[
                            _buildRow("Vendor", widget.vendorName),
                            const SizedBox(height: 3),
                            _buildRow("Hazard", widget.hazardName),
                          ],
                          Container(
                            padding: EdgeInsets.only(top: 10),
                            child: Divider(),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value ?? "-", style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
