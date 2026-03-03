import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/message_model.dart';

/// Remote data source for game chat.
///
/// Endpoints:
///   GET  /api/v1/games/{gameId}/chat  → fetch history
///   POST /api/v1/games/{gameId}/chat  → send message
///
/// Response envelope for both:
/// ```json
/// { "success": true, "message": "...", "data": <ChatMessageDTO | ChatHistoryResponse> }
/// ```
class GameChatRemoteDatasource {
  final ApiClient _api;

  GameChatRemoteDatasource(this._api);

  /// Fetches chat history for [gameId].
  ///
  /// Returns up to 50 messages in chronological order (oldest first).
  /// Throws [DioException] on network/auth failures.
  Future<List<MessageModel>> fetchMessages(String gameId) async {
    try {
      final resp = await _api.get(
        ApiEndpoints.getChatMessages(gameId),
        queryParameters: {'limit': 50},
      );

      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final rawList = (inner['messages'] as List?) ?? [];

      // Use raw list from API directly. Notifier will handle chronological sorting.
      final messages = rawList
          .map((raw) => MessageModel.fromJson(raw as Map<String, dynamic>, gameId))
          .toList();

      debugPrint('[GameChatDS] ✓ Fetched ${messages.length} messages for game $gameId');
      return messages;
    } catch (e) {
      debugPrint('[GameChatDS] ❌ fetchMessages failed for $gameId: $e');
      rethrow;
    }
  }

  /// Sends [text] to [gameId] and returns the confirmed [MessageModel].
  ///
  /// The backend returns the full saved DTO — we use that directly.
  /// DO NOT call [fetchMessages] after this; it causes duplication.
  Future<MessageModel> sendMessage(String gameId, String text) async {
    try {
      final resp = await _api.post(
        ApiEndpoints.sendChatMessage(gameId),
        data: {'content': text.trim()},
      );

      final body = resp.data as Map<String, dynamic>;
      // POST returns the DTO directly in body['data']
      final msgData = (body['data'] as Map<String, dynamic>?) ?? body;

      debugPrint('[GameChatDS] ✓ Sent message to game $gameId');
      return MessageModel.fromJson(msgData, gameId);
    } catch (e) {
      debugPrint('[GameChatDS] ❌ sendMessage failed for $gameId: $e');
      rethrow;
    }
  }
}
