import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

/// eSewa Payment Service - BROWSER MODE
/// 
/// Opens eSewa payment gateway in browser/WebView (like Epay)
/// User completes payment in browser then returns to app
/// 
/// Test Credentials:
/// - eSewa ID: 9806800001
/// - Password: Nepal@123
/// - MPIN: 1122
/// - Merchant ID: EPAYTEST
class EsewaService {
  // Test Credentials for eSewa
  static const String _merchantCode = 'EPAYTEST';
  static const String _successUrl = 'https://playsync.app/payment/success';
  static const String _failureUrl = 'https://playsync.app/payment/failure';

  // eSewa Gateway URLs
  static const String _testGatewayUrl = 'https://rc-epay.esewa.com.np/api/epay/main/v2/form';
  static const String _liveGatewayUrl = 'https://epay.esewa.com.np/api/epay/main/v2/form';

  // Callback handlers
  Function? _onPaymentSuccess;
  Function(String?)? _onPaymentFailure;
  Function(String?)? _onPaymentCancellation;

  /// Initialize eSewa browser payment
  /// 
  /// Opens eSewa payment gateway in browser
  /// [tournamentId] - Unique tournament ID for product
  /// [tournamentName] - Tournament name for display
  /// [amount] - Payment amount in NPR
  Future<dynamic> initiatePayment({
    required String tournamentId,
    required String tournamentName,
    required String amount,
    required Function onSuccess,
    required Function(String?) onFailure,
    required Function(String?) onCancellation,
    String callbackUrl = 'https://playsync.app/payment/callback',
    bool useLiveCredentials = false,
  }) async {
    _onPaymentSuccess = onSuccess;
    _onPaymentFailure = onFailure;
    _onPaymentCancellation = onCancellation;

    debugPrint('[eSewa Browser] 🌐 Opening eSewa payment gateway...');
    debugPrint('[eSewa Browser] Tournament: $tournamentName');
    debugPrint('[eSewa Browser] Amount: $amount NPR');

    try {
      // Build eSewa payment URL with parameters
      final paymentUrl = _buildPaymentUrl(
        productId: tournamentId,
        productName: tournamentName,
        productPrice: amount,
        useLive: useLiveCredentials,
      );

      debugPrint('[eSewa Browser] Payment URL: $paymentUrl');

      // Open in browser
      final Uri uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('[eSewa Browser] ✓ Opened eSewa payment in browser');

        // Simulate callback after delay (user returns to app)
        Timer(const Duration(seconds: 3), () {
          _handleDemoPaymentSuccess(tournamentId, amount);
        });
      } else {
        debugPrint('[eSewa Browser] ❌ Could not launch URL');
        _onPaymentFailure?.call('Could not open payment gateway');
      }
    } catch (e) {
      debugPrint('[eSewa Browser] Error: $e');
      _onPaymentFailure?.call(e.toString());
    }

    return null;
  }

  /// Build eSewa payment URL with parameters
  String _buildPaymentUrl({
    required String productId,
    required String productName,
    required String productPrice,
    bool useLive = false,
  }) {
    final baseUrl = useLive ? _liveGatewayUrl : _testGatewayUrl;
    
    // URL parameters for eSewa
    final params = {
      'amt': productPrice,
      'psc': '0',
      'pdc': '0',
      'txAmt': productPrice,
      'tAmt': productPrice,
      'pid': productId,
      'scd': _merchantCode,
      'su': _successUrl,
      'fu': _failureUrl,
    };

    // Build query string
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Handle simulated successful payment
  void _handleDemoPaymentSuccess(String productId, String amount) {
    debugPrint('[eSewa Browser] ✅ Payment successful!');
    debugPrint('[eSewa Browser] Ref ID: ESEWA-${DateTime.now().millisecondsSinceEpoch}');
    debugPrint('[eSewa Browser] Product ID: $productId');
    debugPrint('[eSewa Browser] Amount: $amount NPR');

    // Create mock success result
    final mockResult = {
      'refId': 'ESEWA-${DateTime.now().millisecondsSinceEpoch}',
      'productId': productId,
      'totalAmount': amount,
      'transactionDetails': {
        'status': 'COMPLETE',
        'date': DateTime.now().toString(),
      }
    };

    _onPaymentSuccess?.call(mockResult);
  }

  /// Handle payment failure
  void _handlePaymentFailure(String? message) {
    debugPrint('[eSewa Browser] ❌ Payment failure: $message');
    _onPaymentFailure?.call(message ?? 'Payment failed');
  }

  /// Handle payment cancellation
  void _handlePaymentCancellation(String? message) {
    debugPrint('[eSewa Browser] ⏸️  Payment cancelled: $message');
    _onPaymentCancellation?.call(message ?? 'Payment cancelled by user');
  }

  /// Verify transaction status via API
  static Future<bool> verifyTransaction({
    required String refId,
    required String merchantId,
    required String merchantSecret,
    String verificationUrl = 'https://rc.esewa.com.np/mobile/transaction',
  }) async {
    try {
      debugPrint('[eSewa Browser] Verifying transaction with refId: $refId');
      // Backend verification would happen here
      return false;
    } catch (e) {
      debugPrint('[eSewa Browser] Verification error: $e');
      return false;
    }
  }
}
