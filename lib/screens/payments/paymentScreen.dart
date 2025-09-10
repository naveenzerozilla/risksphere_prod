import 'package:RiskSphere/screens/payments/order_summary.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/global_imports.dart';

class Paymentscreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentSuccessUrl;

  const Paymentscreen(
      {super.key, required this.paymentUrl, required this.paymentSuccessUrl});

  @override
  State<Paymentscreen> createState() => _PaymentscreenState();
}

class _PaymentscreenState extends State<Paymentscreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = false;
            });

            if (url.contains("success") || url.contains("payment_success")) {
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (mounted) {
                  print(widget.paymentSuccessUrl);
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSummary(
                          sessionId: widget.paymentSuccessUrl,
                        ),
                      ),
                      (route) => false);
                }
              });
            }

            if (url.contains("cancel") || url.contains("payment_cancel")) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _showCancelSnackBar();
                }
              });
            }
          },
          onPageFinished: (url) {
            print("Finished loading: $url");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _showCancelSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment cancelled.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Payment"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
