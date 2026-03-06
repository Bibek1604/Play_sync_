import 'package:play_sync_new/core/services/app_logger.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/message_model.dart';

/// Remote data source for game chat.
class GameChatRemoteDatasource {
  final ApiClient _api;

  GameChatRemoteDatasource(this._api);

  /// Fetches chat history for [gameId].
  Future<List<MessageModel>> fetchMessages(String gameId) async {
    try {
      AppLogger.api('Fetching chat history for game $gameId');
      final resp = await _api.get(
        ApiEndpoints.getChatMessages(gameId),
        queryParameters: {'limit': 50},
      );

      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final rawList = (inner['messages'] as List?) ?? [];

      final messages = rawList
          .map((raw) => MessageModel.fromJson(raw as Map<String, dynamic>, gameId))
          .toList();

      AppLogger.api('Fetched ${messages.length} messages for game $gameId');
      return messages;
    } catch (e) {
      AppLogger.api('fetchMessages failed for $gameId', isError: true, error: e);
      rethrow;
    }
  }

  /// Sends [text] to [gameId] and returns the confirmed [MessageModel].
  Future<MessageModel> sendMessage(String gameId, String text) async {
    try {
      AppLogger.api('Sending message to game $gameId');
      final resp = await _api.post(
        ApiEndpoints.sendChatMessage(gameId),
        data: {'content': text.trim()},
      );

      final body = resp.data as Map<String, dynamic>;
      final msgData = (body['data'] as Map<String, dynamic>?) ?? body;

      AppLogger.api('Sent message to game $gameId');
      return MessageModel.fromJson(msgData, gameId);
    } catch (e) {
      AppLogger.api('sendMessage failed for $gameId', isError: true, error: e);
      rethrow;
    }
  }
}
