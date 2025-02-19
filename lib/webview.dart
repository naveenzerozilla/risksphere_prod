import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  int selectedIndex = 0;
  final List<String> webViewList = [
    "https://pluto.projectzerozilla.com/",
    "https://yahoo.com",
    "https://baidu.com"
  ];
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(webViewList[selectedIndex]));
  }

  Future<bool> _handleBackNavigation(BuildContext context) async {
// Check if the WebView can navigate back
    if (await controller.canGoBack()) {
// If so, go back to the previous page
      controller.goBack();
      return false; // Prevent exiting the app
    } else {
// If no more pages in WebView stack, go back to the parent
      Navigator.of(context).pop();
      return true; // Exit the current widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBackNavigation(context),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Accueil",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: "Exemple",
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.cyan,
          onTap: (i) {
            setState(() {
              selectedIndex = i;
            });
            controller.loadRequest(Uri.parse(webViewList[i]));
          },
        ),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(255, 255, 255, 01),
          toolbarHeight: 5,
          elevation: 0,
        ),
        body: GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
// Swiping right to left
              _handleBackNavigation(context);
            }
          },
          child: WebViewContainer(
            controller: controller,
          ),
        ),
      ),
    );
  }
}

class WebViewContainer extends StatelessWidget {
  final WebViewController controller;

  const WebViewContainer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: controller,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class WebViewExample extends StatefulWidget {
//   const WebViewExample({super.key});
//
//   @override
//   _WebViewExampleState createState() => _WebViewExampleState();
// }
//
// class _WebViewExampleState extends State<WebViewExample> {
//   int selectedIndex = 0;
//   final List<String> webViewList = [
//     "https://pluto.projectzerozilla.com/",
//     "https://yahoo.com",
//     "https://baidu.com"
//   ];
//   late WebViewController controller;
//
//   @override
//   void initState() {
//     super.initState();
//     controller = WebViewController()
//     ..canGoForward()
//       ..canGoBack()
//
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//
//
//
//       ..loadRequest(Uri.parse(webViewList[selectedIndex]));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Accueil",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.business),
//             label: "Exemple",
//           ),
//         ],
//         currentIndex: selectedIndex,
//         selectedItemColor: Colors.cyan,
//         onTap: (i) {
//           setState(() {
//             selectedIndex = i;
//           });
//           controller.loadRequest(Uri.parse(webViewList[i]));
//         },
//       ),
//       appBar: AppBar(
//         backgroundColor: const Color.fromRGBO(255, 255, 255, 01),
//         toolbarHeight: 5,
//         elevation: 0,
//       ),
//       body: WebViewContainer(
//         controller: controller,
//       ),
//     );
//   }
// }
//
// class WebViewContainer extends StatelessWidget {
//   final WebViewController controller;
//
//   const WebViewContainer({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return WebViewWidget(
//       controller: controller,
//     );
//   }
// }
