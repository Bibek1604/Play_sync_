import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

/// A single chat message entity.
/// Handles both old format (nested user) and new format (flat senderId/text).
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
  });

  /// Returns true if [currentUserId] is the sender of this message.
/// STRICT RULE: Comparison is ID-only, with complete normalization:
  /// - Both IDs are trimmed, lowercased, and checked for hidden characters
  /// - No name fallback, no exceptions, no index-based logic
  /// - System messages always return false
  bool isFromMe(String? currentUserId) {
    if (type == MessageType.system || currentUserId == null) {
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

  bool get isSystemMessage => type == MessageType.system;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Handle both old backend format (nested user object) and new format (flat fields)
    
    // Try new format first (senderId, text fields)
    final String? newFormatSenderId = json['senderId'] as String?;
    
    if (newFormatSenderId != null && newFormatSenderId.isNotEmpty) {
      // New REST API format
      final senderId = (newFormatSenderId).trim();
      final senderName = (json['senderName'] as String?)?.trim() ?? 'Unknown';
      final senderAvatar = (json['senderAvatar'] as String?)?.trim();
      
      return ChatMessage(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        senderId: senderId,
        senderName: senderName.isNotEmpty ? senderName : 'Unknown',
        senderAvatar: senderAvatar?.isNotEmpty == true ? senderAvatar : null,
        content: json['text'] as String? ?? '',
        type: _parseType(json['type']),
        sentAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        isRead: json['isRead'] as bool? ?? false,
      );
    }
    
    // Fallback: Old backend format with nested user object
    final Map<String, dynamic> userObj = (json['user'] as Map<String, dynamic>?) ?? {};
    
    // If user is null (system message), use defaults
    if (userObj.isEmpty) {
      return ChatMessage(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        senderId: 'system',
        senderName: 'System',
        senderAvatar: null,
        content: json['content'] as String? ?? '',
        type: MessageType.system,
        sentAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        isRead: json['isRead'] as bool? ?? false,
      );
    }
    
    final String senderId = (userObj['_id'] as String?) ?? (userObj['id'] as String?) ?? '';
    final String fullName = (userObj['fullName'] as String?)?.trim() ?? '';
    final String username = (userObj['username'] as String?)?.trim() ?? '';
    final String senderName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Unknown');
    final String? senderAvatar = userObj['profilePicture'] as String?;
    
    return ChatMessage(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar?.isNotEmpty == true ? senderAvatar : null,
      content: json['content'] as String? ?? '',
      type: _parseType(json['type']),
      sentAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static MessageType _parseType(dynamic typeStr) {
    if (typeStr is String) {
      return MessageType.values.firstWhere(
        (t) => t.name == typeStr.toLowerCase(),
        orElse: () => MessageType.text,
      );
    }
    return MessageType.text;
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'roomId': roomId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'text': content,
    'type': type.name,
    'createdAt': sentAt.toIso8601String(),
    'isRead': isRead,
  };

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    senderName,
    senderAvatar,
    content,
    type,
    sentAt,
    isRead,
  ];
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
