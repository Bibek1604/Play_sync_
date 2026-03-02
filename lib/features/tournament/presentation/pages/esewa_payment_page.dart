import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app WebView page for eSewa payment.
///
/// Arguments:
/// - [paymentUrl] — eSewa form URL
/// - [params] — form parameters (amount, product_code, etc.)
/// - [tournamentId] — tournament being paid for (informational)
///
/// Returns the base64-encoded data query param from the eSewa success callback URL.
/// Returns null if payment was cancelled or failed.
class EsewaPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final Map<String, dynamic> params;
  final String tournamentId;

  const EsewaPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.params,
    required this.tournamentId,
  });

  @override
  State<EsewaPaymentPage> createState() => _EsewaPaymentPageState();
}

class _EsewaPaymentPageState extends State<EsewaPaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (progress == 100 && mounted) {
            setState(() => _isLoading = false);
          }
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          }
        },
        onNavigationRequest: (request) {
          return _handleNavigation(request.url);
        },
      ));

    // Build the eSewa payment form URL with query parameters
    _loadPaymentPage();
  }

  void _loadPaymentPage() {
    // eSewa expects a POST form submission. We'll create an HTML form
    // and submit it automatically.
    final formFields = widget.params.entries
        .map((e) =>
            '<input type="hidden" name="${_htmlEscape(e.key)}" value="${_htmlEscape(e.value.toString())}" />')
        .join('\n');

    final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          background: #f5f5f5;
        }
        .loader { 
          text-align: center; 
          color: #666;
        }
        .spinner {
          border: 3px solid #f3f3f3;
          border-top: 3px solid #60BB46;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 0 auto 16px;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
    </head>
    <body>
      <div class="loader">
        <div class="spinner"></div>
        <p>Redirecting to eSewa...</p>
      </div>
      <form id="esewaForm" method="POST" action="${_htmlEscape(widget.paymentUrl)}">
        $formFields
      </form>
      <script>
        document.getElementById('esewaForm').submit();
      </script>
    </body>
    </html>
    ''';

    _controller.loadHtmlString(html);
  }

  NavigationDecision _handleNavigation(String url) {
    // eSewa redirects to success/failure URL with `data` query param
    // Success URL pattern: .../success?data=<base64>
    // Failure URL pattern: .../failure?data=<base64>

    final uri = Uri.tryParse(url);
    if (uri == null) return NavigationDecision.navigate;

    // Check for success callback
    if (url.contains('/success') || url.contains('/payment/verify')) {
      final data = uri.queryParameters['data'];
      if (data != null && data.isNotEmpty && !_paymentHandled) {
        _paymentHandled = true;
        // Validate it's valid base64
        try {
          base64Decode(data);
        } catch (_) {
          // Not valid base64, pass it anyway — backend will handle
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, data);
        });
        return NavigationDecision.prevent;
      }
    }

    // Check for failure/cancel callback
    if (url.contains('/failure') || url.contains('/cancel')) {
      if (!_paymentHandled) {
        _paymentHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, null);
        });
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  String _htmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSewa Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmCancel(),
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Payment Error: $_error',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _loadPaymentPage();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
            'Are you sure you want to cancel the payment? You can try again later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Payment')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (cancel == true && mounted) Navigator.pop(context, null);
  }
}
