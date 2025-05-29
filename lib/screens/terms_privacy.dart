import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsPage extends StatefulWidget {
  final String title;
  final String url;

  TermsPage({required this.title, required this.url});

  @override
  _TermsPageState createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class TermsPage extends StatelessWidget {
//   final String title;
//   final String url;
//
//   TermsPage({required this.title, required this.url});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title.toString()),
//       ),
//       body: WebViewWidget(
//           controller: WebViewController()..loadRequest(Uri.parse(url))),
//     );
//   }
// }
