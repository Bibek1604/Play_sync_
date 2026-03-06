import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/tournament/domain/entities/tournament_payment_entity.dart';

/// Service to handle browser-based payment flows
class PaymentService {
  static const String _boxName = 'tournament_payments';

  /// Initialize the payment service
  static Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      debugPrint('Payment Service initialized');
    } catch (e) {
      debugPrint('Error initializing Payment Service: $e');
    }
  }

  /// Opens the payment URL in the system browser
  static Future<bool> launchPaymentBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch payment URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching payment browser: $e');
      return false;
    }
  }

  /// Saves the payment status locally using Hive
  static Future<void> savePaymentStatus({
    required String tournamentId,
    required TournamentPaymentEntity payment,
  }) async {
    try {
      final box = Hive.box(_boxName);
      await box.put(tournamentId, payment.status == PaymentStatus.success);
      debugPrint('Payment status saved for tournament: $tournamentId');
    } catch (e) {
      debugPrint('Error saving payment status: $e');
    }
  }

  /// Checks if a tournament is paid for
  static bool isTournamentPaid(String tournamentId) {
    try {
      final box = Hive.box(_boxName);
      return box.get(tournamentId, defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  /// Simulates a payment redirect for testing mode
  static String getTestPaymentUrl(String tournamentId, double amount) {
    // In a real scenario, this would be your backend endpoint that initiates eSewa
    // For testing, we can point to a mock hosted page or a local-friendly URL
    return 'https://rc-epay.esewa.com.np/api/epay/main/v2/form'; 
  }
}
