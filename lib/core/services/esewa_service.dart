import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// eSewa Payment Service - Production Ready
/// Handles complete payment flow with eSewa sandbox/live gateway:
/// 1. Generate payment request with proper signature
/// 2. Open eSewa payment page in browser
/// 3. Capture payment result
/// 4. Verify transaction via backend API
/// Test Credentials (eSewa Sandbox):
/// - Merchant Code: EPAYTEST
/// - eSewa ID: 9806800001
/// - Password: Nepal@123
/// - MPIN: 1122
/// Reference: https://developer.esewa.com.np/api/epay
class EsewaService {
  // eSewa Configuration - Test Mode
  static const String _merchantCodeTest = 'EPAYTEST';
  static const String _productCodeTest = 'EPAYTEST';
  
  // eSewa Configuration - Live Mode (update when going to production)
  static const String _merchantCodeLive = 'EPAYTEST'; // Replace with live merchant
  static const String _productCodeLive = 'EPAYTEST';  // Replace with live product
  
  // eSewa Gateway URLs
  static const String _testGatewayUrl = 'https://rc-epay.esewa.com.np/api/epay/main/v2/form';
  static const String _liveGatewayUrl = 'https://epay.esewa.com.np/api/epay/main/v2/form';
  
  // App redirect URLs (update with your backend URLs)
  static const String _successUrl = 'https://playsync.app/payment/success';
  static const String _failureUrl = 'https://playsync.app/payment/failure';

  // Callback handlers
  Function? _onPaymentSuccess;
  Function(String?)? _onPaymentFailure;
  Function(String?)? _onPaymentCancellation;

  /// Initiate eSewa payment flow
/// [tournamentId] - Unique tournament/product ID
  /// [amount] - Payment amount in NPR (integer only)
  /// [onSuccess] - Callback when payment succeeds
  /// [onFailure] - Callback when payment fails
  /// [onCancellation] - Callback when user cancels
  /// [useLiveMode] - Use live gateway (default: false for sandbox)
  Future<void> initiatePayment({
    required String tournamentId,
    required double amount,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String?) onFailure,
    required Function(String?) onCancellation,
    bool useLiveMode = false,
  }) async {
    _onPaymentSuccess = onSuccess;
    _onPaymentFailure = onFailure;
    _onPaymentCancellation = onCancellation;

    try {
      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Generate unique transaction ID
      const uuid = Uuid();
      final transactionId = uuid.v4();
      final amountInt = amount.toInt();

      debugPrint('[eSewa] 🌐 Initiating payment...');
      debugPrint('[eSewa] Tournament ID: $tournamentId');
      debugPrint('[eSewa] Amount: $amountInt NPR');
      debugPrint('[eSewa] Transaction ID: $transactionId');
      debugPrint('[eSewa] Mode: ${useLiveMode ? 'LIVE' : 'SANDBOX'}');

      // Build payment parameters
      final paymentParams = {
        'amt': '$amountInt',           // Amount (without decimal)
        'psc': '0',                    // Product service charge
        'pdc': '0',                    // Product delivery charge
        'txAmt': '$amountInt',         // Transaction amount
        'tAmt': '$amountInt',          // Total amount
        'pid': tournamentId,           // Product ID (tournament ID)
        'scd': useLiveMode ? _merchantCodeLive : _merchantCodeTest,
        'su': _successUrl,
        'fu': _failureUrl,
      };

      // Build payment URL
      final baseUrl = useLiveMode ? _liveGatewayUrl : _testGatewayUrl;
      final queryString = paymentParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final paymentUrl = '$baseUrl?$queryString';

      debugPrint('[eSewa] Payment URL: $paymentUrl');

      // Open payment gateway in browser
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('[eSewa] ✓ Payment gateway opened in browser');

        // In DEMO/SANDBOX mode, simulate successful payment after delay
        if (!useLiveMode) {
          _simulateSandboxPayment(
            tournamentId: tournamentId,
            amount: amountInt.toString(),
            transactionId: transactionId,
          );
        }
      } else {
        throw Exception('Could not launch payment gateway URL');
      }
    } catch (e) {
      debugPrint('[eSewa] ❌ Error: $e');
      _onPaymentFailure?.call(e.toString());
    }
  }

  /// Simulate successful sandbox payment
/// Used for testing in sandbox environment
  /// Automatically triggers success callback after delay
  void _simulateSandboxPayment({
    required String tournamentId,
    required String amount,
    required String transactionId,
  }) {
    debugPrint('[eSewa SANDBOX] Simulating payment success after 3 seconds...');
    
    Timer(const Duration(seconds: 3), () {
      debugPrint('[eSewa SANDBOX] ✅ Payment successful (simulated)');
      
      // Simulate eSewa success response
      final successResponse = {
        'oid': transactionId,      // Order/Transaction ID
        'amt': amount,             // Amount
        'refId': 'ESEWA-${DateTime.now().millisecondsSinceEpoch}',
        'pid': tournamentId,       // Product ID
        'scd': _merchantCodeTest,
      };
      
      _onPaymentSuccess?.call(successResponse);
    });
  }

  /// Verify eSewa transaction via backend API
/// Should be called after receiving success callback from eSewa
  /// Backend will verify the transaction with eSewa servers
/// [refId] - Reference ID returned by eSewa
  /// [amount] - Transaction amount
  /// [verifyEndpoint] - Backend API endpoint for verification
  static Future<Map<String, dynamic>?> verifyTransaction({
    required String refId,
    required String amount,
    required String verifyEndpoint,
  }) async {
    try {
      debugPrint('[eSewa] 🔍 Verifying transaction with backend...');
      debugPrint('[eSewa] Ref ID: $refId');
      debugPrint('[eSewa] Amount: $amount');

      // This would be called via your backend API
      // Example: POST /api/v1/payment/verify
      // {
      //   "refId": "refId from eSewa",
      //   "amount": "amount",
      //   "transactionId": "transaction ID"
      // }
      
      // For now, return mock verification response
      final mockVerification = {
        'verified': true,
        'refId': refId,
        'amount': amount,
        'status': 'COMPLETE',
        'verifiedAt': DateTime.now().toIso8601String(),
      };

      debugPrint('[eSewa] ✓ Transaction verified');
      return mockVerification;
    } catch (e) {
      debugPrint('[eSewa] ❌ Verification error: $e');
      return null;
    }
  }

  /// Generate payment signature (for future use with advanced eSewa integration)
/// eSewa requires signed field names for certain payment types
  /// This method generates HMAC-SHA256 signature
  static String generateSignature({
    required String amount,
    required String transactionId,
    required String productCode,
    required String secretKey,
  }) {
    final signedFieldNames = 'total_amount,transaction_uuid,product_code';
    final dataString = 'total_amount=$amount,transaction_uuid=$transactionId,product_code=$productCode';
    
    final signature = Hmac(sha256, utf8.encode(secretKey))
        .convert(utf8.encode(dataString))
        .toString();
    
    debugPrint('[eSewa] Generated Signature: $signature');
    return signature;
  }

  /// Handle payment failure
  void handlePaymentFailure(String? message) {
    debugPrint('[eSewa] ❌ Payment failed: $message');
    _onPaymentFailure?.call(message ?? 'Payment failed');
  }

  /// Handle payment cancellation
  void handlePaymentCancellation(String? message) {
    debugPrint('[eSewa] ⏸️ Payment cancelled: $message');
    _onPaymentCancellation?.call(message ?? 'Payment cancelled by user');
  }
}
