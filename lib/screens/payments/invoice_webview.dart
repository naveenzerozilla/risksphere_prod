import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InvoiceWebViewPage extends StatefulWidget {
  final String url;

  const InvoiceWebViewPage({super.key, required this.url});

  @override
  State<InvoiceWebViewPage> createState() => _InvoiceWebViewPageState();
}

class _InvoiceWebViewPageState extends State<InvoiceWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
