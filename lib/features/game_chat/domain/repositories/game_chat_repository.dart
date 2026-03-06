import '../entities/message_entity.dart';

/// Abstract contract for game chat data access.
///
/// The data layer implements this; the presentation layer depends on it.
abstract class GameChatRepository {
  /// Fetches the full chat history for [gameId].
  ///
  /// Returns messages in chronological order (oldest first).
  /// Throws on network/auth errors.
  Future<List<MessageEntity>> fetchMessages(String gameId);

  /// Sends a [text] message to [gameId] and returns the confirmed
  /// [MessageEntity] from the server.
  ///
  /// **IMPORTANT**: Only append this returned entity to the local list.
  /// Do NOT call [fetchMessages] after this — it causes duplication.
  Future<MessageEntity> sendMessage(String gameId, String text);
}
