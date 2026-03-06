import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/esewa_service.dart';

/// eSewa Service Provider
/// 
/// Provides a singleton instance of the eSewa service for payment operations
final esewaServiceProvider = Provider<EsewaService>((ref) {
  return EsewaService();
});
