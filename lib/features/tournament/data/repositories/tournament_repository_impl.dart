import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:play_sync_new/core/error/failures.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_payment_entity.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';
import '../datasources/tournament_local_datasource.dart';

/// Repository implementation — orchestrates remote + local cache
class TournamentRepositoryImpl implements ITournamentRepository {
  final TournamentRemoteDataSource _remote;
  final TournamentLocalDataSource _local;

  TournamentRepositoryImpl({
    required TournamentRemoteDataSource remote,
    required TournamentLocalDataSource local,
  })  : _remote = remote,
        _local = local;
@override
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    try {
      final tournaments = await _remote.getTournaments(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
      // Cache first page
      if (page == 1) {
        _local.cacheTournaments(tournaments, 'all_${status ?? 'any'}_${type ?? 'any'}');
      }
      return Right(tournaments);
    } on DioException catch (e) {
      // Fallback to cache
      final cached = await _local.getCachedTournaments('all_${status ?? 'any'}_${type ?? 'any'}');
      if (cached != null && cached.isNotEmpty) {
        debugPrint('[TournamentRepo] Serving from cache (network failed)');
        return Right(cached);
      }
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id) async {
    try {
      final tournament = await _remote.getTournamentById(id);
      _local.cacheTournament(tournament);
      return Right(tournament);
    } on DioException catch (e) {
      final cached = await _local.getCachedTournament(id);
      if (cached != null) return Right(cached);
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(
      Map<String, dynamic> data) async {
    try {
      final tournament = await _remote.createTournament(data);
      _local.cacheTournament(tournament);
      return Right(tournament);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> updateTournament(
      String id, Map<String, dynamic> data) async {
    try {
      final tournament = await _remote.updateTournament(id, data);
      _local.cacheTournament(tournament);
      return Right(tournament);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTournament(String id) async {
    try {
      await _remote.deleteTournament(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getMyTournaments() async {
    try {
      final list = await _remote.getMyTournaments();
      _local.cacheTournaments(list, 'my_tournaments');
      return Right(list);
    } on DioException catch (e) {
      final cached = await _local.getCachedTournaments('my_tournaments');
      if (cached != null && cached.isNotEmpty) return Right(cached);
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }
@override
  Future<Either<Failure, PaymentInitiation>> initiatePayment(String id) async {
    try {
      final result = await _remote.initiatePayment(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentPaymentEntity>> verifyPayment(
      String? transactionUuid) async {
    try {
      final raw = await _remote.verifyPaymentRaw(transactionUuid);
      final statusCode = raw['statusCode'] as int?;
      final responseData = raw['data'];
      final callbackData = raw['callbackData'] as Map<String, dynamic>?;

      if (statusCode == 202) {
        // PENDING — caller should retry
        return Left(const ApiFailure(
          message: 'Payment is still being processed. Please wait.',
          statusCode: 202,
        ));
      }

        final data = responseData is Map<String, dynamic>
          ? (responseData['data'] ?? responseData)
          : responseData;

        // Backend verify currently responds with message-only payload.
        // In that case, derive minimal payment details from eSewa callback data.
        final paymentMap = data is Map<String, dynamic> && data.containsKey('status')
          ? data
          : <String, dynamic>{
            '_id': callbackData?['transaction_uuid']?.toString() ?? '',
            'amount': _parseAmount(callbackData?['total_amount']),
            'transactionId': callbackData?['transaction_uuid']?.toString(),
            'status': 'success',
            'paidAt': DateTime.now().toIso8601String(),
          };

        final payment = TournamentPaymentEntity.fromJson(paymentMap);
      return Right(payment);
    } on DioException catch (e) {
      if (e.response?.statusCode == 202) {
        return Left(const ApiFailure(
          message: 'Payment is still being processed. Please wait.',
          statusCode: 202,
        ));
      }
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<Either<Failure, TournamentPaymentEntity>> getPaymentStatus(
      String id) async {
    try {
      final payment = await _remote.getPaymentStatus(id);
      return Right(payment);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatAccessResult>> checkChatAccess(String id) async {
    try {
      final result = await _remote.checkChatAccess(id);
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentPaymentEntity>>>
      getDashboardTransactions() async {
    try {
      final payments = await _remote.getDashboardTransactions();
      _local.cachePayments('dashboard_transactions', payments);
      return Right(payments);
    } on DioException catch (e) {
      final cached = await _local.getCachedPayments('dashboard_transactions');
      if (cached != null) return Right(cached);
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentPaymentEntity>>>
      getTournamentPayments(String id) async {
    try {
      final payments = await _remote.getTournamentPayments(id);
      _local.cachePayments('payments_$id', payments);
      return Right(payments);
    } on DioException catch (e) {
      final cached = await _local.getCachedPayments('payments_$id');
      if (cached != null) return Right(cached);
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(GeneralFailure(message: e.toString()));
    }
  }
Failure _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    String message = 'Network error occurred';

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ?? message;
    }

    switch (statusCode) {
      case 400:
        return ApiFailure(message: message, statusCode: 400);
      case 401:
        return AuthFailure(message: message);
      case 403:
        return AuthFailure(message: message);
      case 404:
        return ApiFailure(message: message, statusCode: 404);
      case 409:
        return ApiFailure(message: message, statusCode: 409);
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const NetworkFailure(message: 'Connection timeout');
        }
        if (e.type == DioExceptionType.connectionError) {
          return const NetworkFailure(message: 'No internet connection');
        }
        return ApiFailure(message: message, statusCode: statusCode);
    }
  }
}
