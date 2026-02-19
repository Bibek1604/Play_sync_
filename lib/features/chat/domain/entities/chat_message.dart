import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

/// A single chat message entity.
class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isRead;
  final bool isFromMe;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    required this.sentAt,
    this.isRead = false,
    this.isFromMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return ChatMessage(
      id: json['_id'] as String? ?? json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (t) => t.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isFromMe: currentUserId != null && json['senderId'] == currentUserId,
    );
  }

  @override
  List<Object?> get props => [id, content, sentAt, isFromMe];
}

/// A chat room / conversation.
class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroupChat;
  final List<String> memberIds;

  const ChatRoom({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isGroupChat = false,
    this.memberIds = const [],
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isGroupChat: json['isGroupChat'] as bool? ?? false,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [id, lastMessage, unreadCount];
}
