import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import '../entities/tournament_entity.dart';
import '../entities/tournament_payment_entity.dart';

/// Tournament domain repository interface
abstract class ITournamentRepository {
  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  });

  Future<Either<Failure, TournamentEntity>> getTournamentById(String id);

  Future<Either<Failure, TournamentEntity>> createTournament(
      Map<String, dynamic> data);

  Future<Either<Failure, TournamentEntity>> updateTournament(
      String id, Map<String, dynamic> data);

  Future<Either<Failure, void>> deleteTournament(String id);

  Future<Either<Failure, List<TournamentEntity>>> getMyTournaments();

  // ── Payments ──────────────────────────────────────────────────────────────
  Future<Either<Failure, PaymentInitiation>> initiatePayment(String id);

  Future<Either<Failure, TournamentPaymentEntity>> verifyPayment(
      String transactionUuid);

  Future<Either<Failure, TournamentPaymentEntity>> getPaymentStatus(String id);

  Future<Either<Failure, ChatAccessResult>> checkChatAccess(String id);

  Future<Either<Failure, List<TournamentPaymentEntity>>>
      getDashboardTransactions();

  Future<Either<Failure, List<TournamentPaymentEntity>>>
      getTournamentPayments(String id);
}
