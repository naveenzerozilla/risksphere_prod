import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../design_system/components/custom_appbar.dart';
import '../../design_system/components/custom_drawer.dart';
import '../../design_system/primitives/custom_typography.dart';
import '../../providers/payment_provider.dart';

class PricingInvoice extends StatefulWidget {
  final String sessionId;

  PricingInvoice({super.key, required this.sessionId});

  @override
  State<PricingInvoice> createState() => _PricingInvoiceState();
}

class _PricingInvoiceState extends State<PricingInvoice> {
  bool _isExpanded = false;
  bool _showNotificationDot = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  _getData() async {
    final paymentListProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    await paymentListProvider.makePaymentsuccess(sessionId: widget.sessionId);
  }

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
        body: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, _) {
            if (paymentProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final typography = CustomTypography(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/success.svg',
                      width: 110,
                      height: 110,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thank you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your license has been successfully purchased.',
                    textAlign: TextAlign.center,
                    style: typography.Body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _OrderSummaryCard(
                    invoiceNo: paymentProvider.invoiceId?.toString() ?? '',
                    transactionNo:
                        paymentProvider.paymentIntent?.toString() ?? '—',
                    paymentMethod: paymentProvider
                            .sessionData?.paymentMethodTypes?.first ??
                        '—',
                    totalPayment: paymentProvider.sessionData?.amountTotal
                            ?.toStringAsFixed(2) ??
                        '0.00',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Subscription summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentProvider.plan.length,
                    itemBuilder: (context, index) {
                      final item = paymentProvider.plan[index];
                      final isLast = index == paymentProvider.plan.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.planName ?? 'N/A',
                            style: typography.Body1.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20),
                          _KeyValueRow(
                              label: 'User count',
                              value: item.selectedPlan ?? '—'),
                          const SizedBox(height: 15),
                          _KeyValueRow(
                              label: 'Billing', value: item.planType ?? '—'),
                          const SizedBox(height: 15),
                          _KeyValueRow(
                            label: 'License pricing',
                            value: '\$${item.price?.toString() ?? '0'} / user',
                          ),
                          const SizedBox(height: 24),
                          if (!isLast) const Divider(thickness: 1, height: 1),
                          if (!isLast) const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total pricing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '\$${paymentProvider.sessionData?.amountTotal?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String invoiceNo;
  final String transactionNo;
  final String paymentMethod;
  final String totalPayment;

  _OrderSummaryCard({
    super.key,
    required this.invoiceNo,
    required this.transactionNo,
    required this.paymentMethod,
    required this.totalPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              )),
          const SizedBox(height: 20),
          _KeyValueRow(label: 'Invoice no ', value: invoiceNo, underline: true),
          const SizedBox(height: 13),
          _KeyValueRow(
              label: 'Transaction no', value: transactionNo, underline: true),
          const SizedBox(height: 13),
          _KeyValueRow(label: 'Payment method', value: paymentMethod),
          const SizedBox(height: 13),
          _KeyValueRow(
            label: 'Total Payment',
            value: '\$${totalPayment}',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.underline = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final typography = CustomTypography(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: typography.Body2.copyWith(color: Colors.grey.shade400)),
        Text(value,
            style: typography.Body2.copyWith(
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              decoration:
                  underline ? TextDecoration.underline : TextDecoration.none,
            )),
      ],
    );
  }
}
