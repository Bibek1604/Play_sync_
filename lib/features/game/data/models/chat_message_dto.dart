import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';

/// Chat Message DTO
class ChatMessageDto {
  final String id;
  final String gameId;
  final String senderId;
  final String senderName;
  final String message;
  final String timestamp;
  final String type;
  final String? senderAvatar;

  ChatMessageDto({
    required this.id,
    required this.gameId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.senderAvatar,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] ?? json['_id'] ?? '',
      gameId: json['gameId'] ?? json['game_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      type: json['type'] ?? 'user',
      senderAvatar: json['senderAvatar'] ?? json['sender_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'senderAvatar': senderAvatar,
    };
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      gameId: gameId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.parse(timestamp),
      type: type == 'system' ? MessageType.system : MessageType.user,
      senderAvatar: senderAvatar,
    );
  }
}
