import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final String successUrlPattern;
  final Function(String) onSuccess;
  final VoidCallback onCancel;

  const PaymentWebView({
    Key? key,
    required this.url,
    required this.successUrlPattern,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // Check if we reached the success URL
            if (url.contains(widget.successUrlPattern)) {
              widget.onSuccess(url);
            }
          },
          onNavigationRequest: (request) {
            if (request.url.contains(widget.successUrlPattern)) {
              widget.onSuccess(request.url);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('payment-failure') || request.url.contains('cancel')) {
              widget.onCancel();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('If you leave now, your registration won\'t be completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onCancel();
            },
            child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
