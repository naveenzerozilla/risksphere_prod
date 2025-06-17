import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Paymentscreen extends StatefulWidget {
  final String paymentUrl;

  const Paymentscreen({super.key, required this.paymentUrl});

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
            print("🔄 Started loading: $url");
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            print("✅ Finished loading: $url");
            setState(() {
              isLoading = false;
            });

            // Debug print to check what URL we land on
            debugPrint(" Current URL: $url");

            // You can change this match to your actual Stripe success page
            if (url.contains("success") || url.contains("payment_success")) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context);
                  _navigateToSuccessScreen();
                }
              });
            }

            if (url.contains("cancel") || url.contains("payment_cancel")) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context);
                  _showCancelSnackBar();
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _navigateToSuccessScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Payment successful!")),
    );
    // Navigate to your success screen here, for example:
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessPage()));
  }

  void _showCancelSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Payment cancelled.")),
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
