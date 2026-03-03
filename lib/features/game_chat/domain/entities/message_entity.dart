import 'package:equatable/equatable.dart';

/// A single chat message in the domain layer.
///
/// `isMe` is computed dynamically by comparing [senderId] against
/// the current user's ID — it is NEVER stored as a field so it
/// is always fresh, even if the auth state changes.
class MessageEntity extends Equatable {
  final String id;
  final String gameId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;
  final bool isSystemMessage;

  const MessageEntity({
    required this.id,
    required this.gameId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
    this.isSystemMessage = false,
  });

  /// Returns `true` when this message was sent by the current user.
  ///
  /// STRICT RULE: Comparison is ID-only, with normalization:
  /// - Both IDs are trimmed and lowercased
  /// - No name fallback, no exceptions, no index-based logic
  /// - If IDs don't match exactly, this returns false
  bool isMe(String? currentUserId, {String? currentUserName}) {
    if (isSystemMessage) {
      return false;
    }

    if (currentUserId == null || currentUserId.toString().trim().isEmpty) {
      return false;
    }

    // Normalize both IDs: trim, lowercase, remove hidden characters
    final normalizedCurrent =
        currentUserId.toString().trim().toLowerCase();
    final normalizedSender =
        senderId.trim().toLowerCase();

    // Strict ID comparison only
    return normalizedSender == normalizedCurrent;
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        senderId,
        senderName,
        senderAvatar,
        text,
        createdAt,
        isSystemMessage,
      ];
}
