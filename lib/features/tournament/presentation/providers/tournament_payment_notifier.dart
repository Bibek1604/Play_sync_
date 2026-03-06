import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tournament_payment_entity.dart';
import '../../domain/repositories/tournament_repository.dart';
import 'tournament_notifier.dart';

// ── Payment Flow State ──────────────────────────────────────────────────────

enum PaymentFlowStatus {
  idle,
  initiating,
  awaitingPayment,
  verifying,
  success,
  failed,
}

class TournamentPaymentState {
  final PaymentFlowStatus flowStatus;
  final PaymentInitiation? paymentInitiation;
  final TournamentPaymentEntity? lastPayment;
  final ChatAccessResult? chatAccess;
  final List<TournamentPaymentEntity> dashboardTransactions;
  final List<TournamentPaymentEntity> tournamentPayments;
  final String? error;
  final int verifyRetryCount;
  final bool isCheckingAccess;

  const TournamentPaymentState({
    this.flowStatus = PaymentFlowStatus.idle,
    this.paymentInitiation,
    this.lastPayment,
    this.chatAccess,
    this.dashboardTransactions = const [],
    this.tournamentPayments = const [],
    this.error,
    this.verifyRetryCount = 0,
    this.isCheckingAccess = false,
  });

  TournamentPaymentState copyWith({
    PaymentFlowStatus? flowStatus,
    PaymentInitiation? paymentInitiation,
    TournamentPaymentEntity? lastPayment,
    ChatAccessResult? chatAccess,
    List<TournamentPaymentEntity>? dashboardTransactions,
    List<TournamentPaymentEntity>? tournamentPayments,
    String? error,
    int? verifyRetryCount,
    bool? isCheckingAccess,
    bool clearError = false,
    bool clearPayment = false,
  }) {
    return TournamentPaymentState(
      flowStatus: flowStatus ?? this.flowStatus,
      paymentInitiation:
          clearPayment ? null : (paymentInitiation ?? this.paymentInitiation),
      lastPayment: clearPayment ? null : (lastPayment ?? this.lastPayment),
      chatAccess: chatAccess ?? this.chatAccess,
      dashboardTransactions:
          dashboardTransactions ?? this.dashboardTransactions,
      tournamentPayments: tournamentPayments ?? this.tournamentPayments,
      error: clearError ? null : (error ?? this.error),
      verifyRetryCount: verifyRetryCount ?? this.verifyRetryCount,
      isCheckingAccess: isCheckingAccess ?? this.isCheckingAccess,
    );
  }

  bool get canRetryVerify => verifyRetryCount < 6;
}

// ── Payment Notifier ────────────────────────────────────────────────────────

class TournamentPaymentNotifier extends StateNotifier<TournamentPaymentState> {
  final ITournamentRepository _repository;
  Timer? _retryTimer;

  static const int _maxRetries = 6;
  static const Duration _retryDelay = Duration(seconds: 5);

  TournamentPaymentNotifier(this._repository)
      : super(const TournamentPaymentState());

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // ── Initiate eSewa Payment ────────────────────────────────────────────────

  Future<void> initiatePayment(String tournamentId) async {
    state = state.copyWith(
      flowStatus: PaymentFlowStatus.initiating,
      clearError: true,
      clearPayment: true,
      verifyRetryCount: 0,
    );

    final result = await _repository.initiatePayment(tournamentId);
    result.fold(
      (failure) {
        state = state.copyWith(
          flowStatus: PaymentFlowStatus.failed,
          error: failure.message,
        );
      },
      (initiation) {
        state = state.copyWith(
          flowStatus: PaymentFlowStatus.awaitingPayment,
          paymentInitiation: initiation,
        );
      },
    );
  }

  // ── Verify Payment (POST callback from eSewa) ────────────────────────────

  Future<void> verifyPayment([String? base64Data]) async {
    _retryTimer?.cancel();
    state = state.copyWith(
      flowStatus: PaymentFlowStatus.verifying,
      clearError: true,
    );

    final result = await _repository.verifyPayment(base64Data);
    result.fold(
      (failure) {
        if (failure is ApiFailure && failure.statusCode == 202 && state.canRetryVerify) {
          // Payment still processing — schedule retry
          _scheduleRetry(base64Data);
        } else {
          state = state.copyWith(
            flowStatus: PaymentFlowStatus.failed,
            error: failure.message,
          );
        }
      },
      (payment) {
        state = state.copyWith(
          flowStatus: PaymentFlowStatus.success,
          lastPayment: payment,
        );
      },
    );
  }

  void _scheduleRetry(String? base64Data) {
    final nextRetry = state.verifyRetryCount + 1;
    state = state.copyWith(verifyRetryCount: nextRetry);
    debugPrint('[Payment] Retry $nextRetry/$_maxRetries in ${_retryDelay.inSeconds}s');

    _retryTimer = Timer(_retryDelay, () {
      if (mounted) verifyPayment(base64Data);
    });
  }

  // ── Check Payment Status ──────────────────────────────────────────────────

  Future<void> checkPaymentStatus(String tournamentId) async {
    final result = await _repository.getPaymentStatus(tournamentId);
    result.fold(
      (failure) => debugPrint('[Payment] Status check failed: ${failure.message}'),
      (payment) {
        state = state.copyWith(lastPayment: payment);
        if (payment.status == PaymentStatus.success) {
          state = state.copyWith(flowStatus: PaymentFlowStatus.success);
        }
      },
    );
  }

  // ── Chat Access ───────────────────────────────────────────────────────────

  Future<void> checkChatAccess(String tournamentId) async {
    state = state.copyWith(isCheckingAccess: true);
    final result = await _repository.checkChatAccess(tournamentId);
    result.fold(
      (failure) {
        state = state.copyWith(
          isCheckingAccess: false,
          chatAccess: ChatAccessResult(canAccess: false, reason: failure.message),
        );
      },
      (access) {
        state = state.copyWith(isCheckingAccess: false, chatAccess: access);
      },
    );
  }

  // ── Dashboard / Admin Payments ────────────────────────────────────────────

  Future<void> fetchDashboardTransactions() async {
    final result = await _repository.getDashboardTransactions();
    result.fold(
      (failure) => debugPrint('[Payment] Dashboard fetch failed: ${failure.message}'),
      (list) => state = state.copyWith(dashboardTransactions: list),
    );
  }

  Future<void> fetchTournamentPayments(String tournamentId) async {
    final result = await _repository.getTournamentPayments(tournamentId);
    result.fold(
      (failure) => debugPrint('[Payment] Tournament payments fetch failed: ${failure.message}'),
      (list) => state = state.copyWith(tournamentPayments: list),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetPaymentFlow() {
    _retryTimer?.cancel();
    state = const TournamentPaymentState();
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final tournamentPaymentProvider =
    StateNotifierProvider<TournamentPaymentNotifier, TournamentPaymentState>(
        (ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentPaymentNotifier(repository);
});
