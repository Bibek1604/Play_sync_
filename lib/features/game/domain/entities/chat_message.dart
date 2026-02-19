/// Chat Message Entity (Domain Layer)
class ChatMessage {
  final String id;
  final String gameId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String? senderAvatar;

  const ChatMessage({
    required this.id,
    required this.gameId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.senderAvatar,
  });

  bool get isSystemMessage => type == MessageType.system;
  bool get isUserMessage => type == MessageType.user;

  ChatMessage copyWith({
    String? id,
    String? gameId,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    MessageType? type,
    String? senderAvatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}

enum MessageType {
  user,
  system,
}
