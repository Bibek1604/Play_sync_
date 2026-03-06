import 'package:flutter/foundation.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

/// eSewa Payment Service
/// 
/// Handles native eSewa Mobile SDK integration for tournament payments
/// Uses eSewa Flutter SDK v2.5.4_24
/// Supports both TEST and LIVE environments
class EsewaService {
  // Test Environment Credentials
  static const String _testClientId = 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R';
  static const String _testSecretKey = 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==';

  // Callback handlers
  Function(EsewaPaymentSuccessResult)? _onPaymentSuccess;
  Function(String?)? _onPaymentFailure;
  Function(String?)? _onPaymentCancellation;

  /// Initialize eSewa payment with native SDK
  /// 
  /// [tournamentId] - Unique tournament ID for product
  /// [tournamentName] - Tournament name for display
  /// [amount] - Payment amount in NPR
  /// [callbackUrl] - URL to redirect after payment (for mobile, can be any URL)
  /// [environment] - Payment environment (test or live)
  /// [useLiveCredentials] - Whether to use live credentials (requires real credentials)
  Future<dynamic> initiatePayment({
    required String tournamentId,
    required String tournamentName,
    required String amount,
    required Function(EsewaPaymentSuccessResult) onSuccess,
    required Function(String?) onFailure,
    required Function(String?) onCancellation,
    String callbackUrl = 'https://playsync.app/payment/callback',
    bool useLiveCredentials = false,
  }) async {
    _onPaymentSuccess = onSuccess;
    _onPaymentFailure = onFailure;
    _onPaymentCancellation = onCancellation;

    try {
      debugPrint('[eSewa] Initiating payment for tournament: $tournamentId, amount: $amount');

      // Prepare eSewa configuration
      final esewaConfig = EsewaConfig(
        environment: useLiveCredentials ? Environment.live : Environment.test,
        clientId: _testClientId,
        secretId: _testSecretKey,
      );

      // Prepare payment details
      final esewaPayment = EsewaPayment(
        productId: tournamentId,
        productName: tournamentName,
        productPrice: amount,
        callbackUrl: callbackUrl,
      );

      // Initiate payment with native SDK (void method, no await)
      EsewaFlutterSdk.initPayment(
        esewaConfig: esewaConfig,
        esewaPayment: esewaPayment,
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint('[eSewa] SUCCESS: $data');
          _handlePaymentSuccess(data);
        },
        onPaymentFailure: (data) {
          debugPrint('[eSewa] FAILURE: $data');
          _handlePaymentFailure(data?.toString());
        },
        onPaymentCancellation: (data) {
          debugPrint('[eSewa] CANCELLATION: $data');
          _handlePaymentCancellation(data?.toString());
        },
      );

      return null; // Payment handled through callbacks
    } on Exception catch (e) {
      debugPrint('[eSewa] EXCEPTION: ${e.toString()}');
      _onPaymentFailure?.call(e.toString());
      return null;
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(EsewaPaymentSuccessResult result) {
    debugPrint('[eSewa] Payment success callback triggered');
    debugPrint('[eSewa] Ref ID: ${result.refId}');
    debugPrint('[eSewa] Product ID: ${result.productId}');
    debugPrint('[eSewa] Total Amount: ${result.totalAmount}');
    
    _onPaymentSuccess?.call(result);
  }

  /// Handle payment failure
  void _handlePaymentFailure(String? message) {
    debugPrint('[eSewa] Payment failure: $message');
    _onPaymentFailure?.call(message ?? 'Payment failed');
  }

  /// Handle payment cancellation
  void _handlePaymentCancellation(String? message) {
    debugPrint('[eSewa] Payment cancelled: $message');
    _onPaymentCancellation?.call(message ?? 'Payment cancelled by user');
  }

  /// Verify transaction status via API
  /// 
  /// Recommended method for mobile - uses refId or productId+amount
  /// Returns true if status is 'COMPLETE'
  static Future<bool> verifyTransaction({
    required String refId,
    required String merchantId,
    required String merchantSecret,
    String verificationUrl = 'https://rc.esewa.com.np/mobile/transaction', // Remove 'rc' for live
  }) async {
    try {
      debugPrint('[eSewa] Verifying transaction with refId: $refId');

      // TODO: Call your backend API to verify transaction
      // Backend should make the verification request with proper authentication
      // Example endpoint: POST /api/tournaments/verify-esewa-payment
      // With body: { refId, tournamentId, amount }
      
      // This is typically done server-side for security
      return false;
    } catch (e) {
      debugPrint('[eSewa] Verification error: $e');
      return false;
    }
  }
}
