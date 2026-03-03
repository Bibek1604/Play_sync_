import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/chat_message.dart';

/// Result of a paginated chat history request.
class ChatHistoryResult {
  final List<ChatMessage> messages;
  final bool hasMore;
  final String? nextCursor;

  const ChatHistoryResult({
    required this.messages,
    this.hasMore = false,
    this.nextCursor,
  });
}

/// Repository for game chat operations.
///
/// Wraps REST endpoints:
///   - GET  /games/:gameId/chat  → paginated message history
///   - POST /games/:gameId/chat  → send message (REST fallback)
///
/// Real-time messaging is handled via Socket.IO in the notifier layer.
class ChatRepository {
  final ApiClient _api;

  ChatRepository(this._api);

  /// Fetches paginated chat history for a game.
  ///
  /// [limit] — max messages to return (default 50, max 100 per backend).
  /// [before] — ISO-8601 cursor for pagination (load older messages).
  Future<ChatHistoryResult> getChatHistory(
    String gameId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final resp = await _api.get(
        ApiEndpoints.getChatMessages(gameId),
        queryParameters: {
          'limit': limit,
          if (before != null) 'before': before,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final rawList = (inner['messages'] as List?) ?? [];
      final hasMore = inner['hasMore'] as bool? ?? false;
      final nextCursor = inner['nextCursor'] as String?;

      final messages = rawList
          .map((raw) => _parseMessage(raw as Map<String, dynamic>, gameId))
          .toList();

      debugPrint('[ChatRepository] ✓ Fetched ${messages.length} messages for game $gameId');
      return ChatHistoryResult(
        messages: messages,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    } catch (e) {
      debugPrint('[ChatRepository] ❌ getChatHistory failed for $gameId: $e');
      rethrow;
    }
  }

  /// Sends a text message to a game chat via REST (fallback for when socket
  /// is offline or for guaranteed delivery).
  ///
  /// POST /games/:gameId/chat  body: { content }
  /// Returns the created [ChatMessage].
  Future<ChatMessage> sendMessage(String gameId, String content) async {
    try {
      final resp = await _api.post(
        ApiEndpoints.sendChatMessage(gameId),
        data: {'content': content.trim()},
      );
      final body = resp.data as Map<String, dynamic>;
      final msgData = (body['data'] as Map<String, dynamic>?) ?? body;
      debugPrint('[ChatRepository] ✓ Sent message to game $gameId via REST');
      return _parseMessage(msgData, gameId);
    } catch (e) {
      debugPrint('[ChatRepository] ❌ sendMessage failed for $gameId: $e');
      rethrow;
    }
  }

  /// Parses a backend ChatMessageDTO into [ChatMessage].
  ///
  /// Backend shape:
  /// ```json
  /// {
  ///   "_id": "abc",
  ///   "user": { "_id": "u1", "fullName": "John", "profilePicture": "..." },
  ///   "content": "hello",
  ///   "type": "text" | "system",
  ///   "createdAt": "2025-01-01T00:00:00Z"
  /// }
  /// ```
  ChatMessage _parseMessage(Map<String, dynamic> json, String roomId) {
    final rawUser = json['user'];
    String senderId = '';
    String senderName = 'User';
    String? senderAvatar;

    if (rawUser is Map<String, dynamic>) {
      senderId =
          (rawUser['_id'] as String? ?? rawUser['id'] as String? ?? '').trim();
      senderName = rawUser['fullName'] as String? ??
          rawUser['username'] as String? ??
          'User';
      senderAvatar = rawUser['profilePicture'] as String?;
    }

    final type = json['type'] as String? ?? 'text';
    final isSystem = type == 'system';
    final msgId =
        (json['_id'] as String? ?? json['id'] as String? ?? '').trim();

    return ChatMessage(
      id: msgId.isNotEmpty
          ? msgId
          : 'msg_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: isSystem ? 'system' : senderId,
      senderName: isSystem ? 'System' : senderName,
      senderAvatar: senderAvatar,
      content: json['content'] as String? ?? '',
      type: isSystem ? MessageType.system : MessageType.text,
      sentAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: true,
    );
  }
}
