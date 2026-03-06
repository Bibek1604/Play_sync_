import 'dart:convert';

import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_payment_entity.dart';

/// Remote data source for tournament API calls
class TournamentRemoteDataSource {
  final ApiClient _apiClient;

  TournamentRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<TournamentEntity>> getTournaments({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;

    final response = await _apiClient.get(
      ApiEndpoints.getTournaments,
      queryParameters: params,
    );

    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // data might have { tournaments: [...], pagination: {...} }
    if (data is Map<String, dynamic>) {
      final list = data['tournaments'] ?? data['data'] ?? data['results'];
      if (list is List) {
        return list
            .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  Future<TournamentEntity> getTournamentById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.getTournamentById(id));
    final data = _extractData(response.data);
    return TournamentEntity.fromJson(data as Map<String, dynamic>);
  }

  Future<TournamentEntity> createTournament(Map<String, dynamic> body) async {
    final response = await _apiClient.post(
      ApiEndpoints.createTournament,
      data: body,
    );
    final data = _extractData(response.data);
    return TournamentEntity.fromJson(data as Map<String, dynamic>);
  }

  Future<TournamentEntity> updateTournament(
      String id, Map<String, dynamic> body) async {
    final response = await _apiClient.patch(
      ApiEndpoints.updateTournament(id),
      data: body,
    );
    final data = _extractData(response.data);
    return TournamentEntity.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTournament(String id) async {
    await _apiClient.delete(ApiEndpoints.deleteTournament(id));
  }

  Future<List<TournamentEntity>> getMyTournaments() async {
    final response = await _apiClient.get(ApiEndpoints.getMyTournaments);
    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['tournaments'] ?? data['data'] ?? data['results'];
      if (list is List) {
        return list
            .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<PaymentInitiation> initiatePayment(String id) async {
    final response = await _apiClient.post(
      ApiEndpoints.initiatePayment,
      data: {'tournamentId': id},
    );
    final data = _extractData(response.data);
    return PaymentInitiation.fromJson(data as Map<String, dynamic>);
  }

  /// Verify payment — returns entity or throws.
  /// Backend returns 202 for PENDING (caller should retry).
  Future<Map<String, dynamic>> verifyPaymentRaw(String? base64Data) async {
    final params = <String, dynamic>{};
    if (base64Data != null && base64Data.isNotEmpty) {
      params['data'] = base64Data;
    }
    final response = await _apiClient.get(
      ApiEndpoints.verifyPayment,
      queryParameters: params,
    );
    return {
      'statusCode': response.statusCode,
      'data': response.data,
      'callbackData':
          (base64Data != null && base64Data.isNotEmpty) ? _decodeEsewaData(base64Data) : null,
    };
  }

  Future<TournamentPaymentEntity> getPaymentStatus(String id) async {
    final response = await _apiClient.get(ApiEndpoints.getPaymentStatus(id));
    final data = _extractData(response.data);
    return TournamentPaymentEntity.fromJson(data as Map<String, dynamic>);
  }

  Future<ChatAccessResult> checkChatAccess(String id) async {
    final response = await _apiClient.get(ApiEndpoints.checkChatAccess(id));
    final data = _extractData(response.data);
    return ChatAccessResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TournamentPaymentEntity>> getDashboardTransactions() async {
    final response =
        await _apiClient.get(ApiEndpoints.getDashboardTransactions);
    final data = _extractData(response.data);
    return _parsePaymentList(data);
  }

  Future<List<TournamentPaymentEntity>> getTournamentPayments(
      String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.getTournamentPayments(id));
    final data = _extractData(response.data);
    return _parsePaymentList(data);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<TournamentPaymentEntity> _parsePaymentList(dynamic data) {
    if (data is List) {
      return data
          .map((e) =>
              TournamentPaymentEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['payments'] ?? data['data'] ?? data['results'];
      if (list is List) {
        return list
            .map((e) =>
                TournamentPaymentEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// Extract the `data` field from standard API response
  /// Response shape: { success: bool, message: string, data: T }
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['data'] ?? responseData;
    }
    return responseData;
  }

  /// eSewa verify endpoint only returns message in current backend,
  /// so decode the callback payload to preserve transaction details.
  Map<String, dynamic>? _decodeEsewaData(String base64Data) {
    try {
      final decoded = utf8.decode(base64Decode(base64Data));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      return null;
    } catch (_) {
      return null;
    }
  }
}
