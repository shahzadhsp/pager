import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShoppingWebViewScreen extends StatefulWidget {
  const ShoppingWebViewScreen({super.key});

  @override
  State<ShoppingWebViewScreen> createState() => _ShoppingWebViewScreenState();
}

class _ShoppingWebViewScreenState extends State<ShoppingWebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://lorapager.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shopping")),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
