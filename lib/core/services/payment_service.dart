import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tournament/domain/entities/tournament_payment_entity.dart';

/// Service for handling eSewa payment operations and local payment caching.
/// 
/// **eSewa Payment Flow:**
/// 1. User initiates payment → Backend creates payment record
/// 2. Backend returns eSewa payment URL + params (amount, product_code, etc.)
/// 3. App opens WebView with eSewa form
/// 4. User completes payment on eSewa
/// 5. eSewa redirects to success URL with base64-encoded data
/// 6. App captures redirect → sends data to backend for verification
/// 7. Backend validates with eSewa server → confirms payment
/// 8. Payment status updated → User gains access
class PaymentService {
  static const String _paymentBoxName = 'tournament_payments';
  static const String _paymentStatusPrefix = 'payment_status_';

  /// Initialize payment storage
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_paymentBoxName)) {
      await Hive.openBox(_paymentBoxName);
    }
    debugPrint('[PaymentService] Initialized');
  }

  /// Get payment box (opens if needed)
  static Future<Box> get _box async {
    if (!Hive.isBoxOpen(_paymentBoxName)) {
      return await Hive.openBox(_paymentBoxName);
    }
    return Hive.box(_paymentBoxName);
  }

  // ── Payment Status Cache ────────────────────────────────────────────────

  /// Save payment status locally for offline access
  /// 
  /// Stores payment details so users can access tournament features
  /// even when offline (after successful payment verification)
  static Future<void> savePaymentStatus({
    required String tournamentId,
    required TournamentPaymentEntity payment,
  }) async {
    try {
      final box = await _box;
      final key = '$_paymentStatusPrefix$tournamentId';
      await box.put(key, payment.toJson());
      debugPrint('[PaymentService] ✓ Saved payment status for tournament: $tournamentId');
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error saving payment: $e');
    }
  }

  /// Get cached payment status for a tournament
  /// 
  /// Returns null if no payment found or payment failed
  static Future<TournamentPaymentEntity?> getPaymentStatus(
      String tournamentId) async {
    try {
      final box = await _box;
      final key = '$_paymentStatusPrefix$tournamentId';
      final data = box.get(key);

      if (data == null) return null;

      final payment = TournamentPaymentEntity.fromJson(
          Map<String, dynamic>.from(data as Map));
      
      // Only return if payment was successful
      if (payment.status == PaymentStatus.success) {
        return payment;
      }
      return null;
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error reading payment: $e');
      return null;
    }
  }

  /// Check if user has paid for a tournament
  static Future<bool> hasPaid(String tournamentId) async {
    final payment = await getPaymentStatus(tournamentId);
    return payment != null && payment.status == PaymentStatus.success;
  }

  /// Clear payment status (useful for testing or refunds)
  static Future<void> clearPaymentStatus(String tournamentId) async {
    try {
      final box = await _box;
      final key = '$_paymentStatusPrefix$tournamentId';
      await box.delete(key);
      debugPrint('[PaymentService] ✓ Cleared payment status for: $tournamentId');
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error clearing payment: $e');
    }
  }

  // ── Payment History ─────────────────────────────────────────────────────

  /// Save a payment to local history
  static Future<void> addToHistory(TournamentPaymentEntity payment) async {
    try {
      final box = await _box;
      final historyKey = 'payment_${payment.id}';
      await box.put(historyKey, payment.toJson());
      debugPrint('[PaymentService] ✓ Added to history: ${payment.id}');
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error adding to history: $e');
    }
  }

  /// Get all payment history
  static Future<List<TournamentPaymentEntity>> getPaymentHistory() async {
    try {
      final box = await _box;
      final payments = <TournamentPaymentEntity>[];

      for (final key in box.keys) {
        if (key.toString().startsWith('payment_')) {
          final data = box.get(key);
          if (data != null) {
            try {
              payments.add(TournamentPaymentEntity.fromJson(
                  Map<String, dynamic>.from(data as Map)));
            } catch (e) {
              debugPrint('[PaymentService] Skipping invalid payment: $e');
            }
          }
        }
      }

      // Sort by date (newest first)
      payments.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return payments;
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error getting history: $e');
      return [];
    }
  }

  /// Clear all payment data (logout/reset)
  static Future<void> clearAll() async {
    try {
      final box = await _box;
      await box.clear();
      debugPrint('[PaymentService] ✓ Cleared all payment data');
    } catch (e) {
      debugPrint('[PaymentService] ✗ Error clearing all: $e');
    }
  }

  // ── Helper Methods ──────────────────────────────────────────────────────

  /// Format amount for display
  static String formatAmount(double amount) {
    return 'NPR ${amount.toStringAsFixed(2)}';
  }

  /// Get payment status display text
  static String getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  /// Get status color for UI
  static int getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return 0xFF4CAF50; // Green
      case PaymentStatus.pending:
        return 0xFFFF9800; // Orange
      case PaymentStatus.failed:
        return 0xFFF44336; // Red
    }
  }
}
