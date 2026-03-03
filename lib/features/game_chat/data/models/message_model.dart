import '../../domain/entities/message_entity.dart';

/// Data-layer model for a chat message.
///
/// Parses the backend ChatMessageDTO which is currently in flat format:
/// ```json
/// {
///   "_id": "...",
///   "senderId": "userId",
///   "senderName": "Full Name",
///   "senderAvatar": "url | null",
///   "text": "message content",
///   "type": "text" | "system",
///   "createdAt": "ISO 8601 string"
/// }
/// ```
///
/// Also handles the legacy nested-user format as a fallback.
class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.gameId,
    required super.senderId,
    required super.senderName,
    super.senderAvatar,
    required super.text,
    required super.createdAt,
    super.isSystemMessage,
  });

  /// Parses a backend JSON map into [MessageModel].
  ///
  /// Supports both current (flat) and legacy (nested user) formats.
  factory MessageModel.fromJson(Map<String, dynamic> json, String gameId) {
    final type = json['type'] as String? ?? 'text';
    final isSystem = type == 'system';
    final msgId = _normalizeId(json['_id'] ?? json['id']);

    // ── Current format: flat senderId / senderName / text ──────────────────
    final flatSenderId = _normalizeId(json['senderId']);
    if (flatSenderId.isNotEmpty) {
      final content = (json['text'] as String?)?.isNotEmpty == true
          ? json['text'] as String
          : (json['content'] as String? ?? '');

      return MessageModel(
        id: msgId.isNotEmpty ? msgId : 'msg_${DateTime.now().microsecondsSinceEpoch}',
        gameId: gameId,
        senderId: isSystem ? 'system' : flatSenderId.trim(),
        senderName: isSystem
            ? 'System'
            : ((json['senderName'] as String?)?.trim().isNotEmpty == true
                ? json['senderName'] as String
                : 'Unknown'),
        senderAvatar: _cleanUrl(json['senderAvatar'] as String?),
        text: content,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isSystemMessage: isSystem,
      );
    }

    // ── Legacy format: nested user object / content field ───────────────────
    final rawUser = json['user'];
    String senderId = '';
    String senderName = 'Unknown';
    String? senderAvatar;

    if (rawUser is Map<String, dynamic>) {
      senderId = _normalizeId(rawUser['_id'] ?? rawUser['id']);
      final fullName = (rawUser['fullName'] as String?)?.trim() ?? '';
      final username = (rawUser['username'] as String?)?.trim() ?? '';
      senderName = fullName.isNotEmpty
          ? fullName
          : (username.isNotEmpty ? username : 'Unknown');
      senderAvatar = _cleanUrl(
        rawUser['profilePicture'] as String? ??
            rawUser['profileImage'] as String? ??
            rawUser['avatar'] as String?,
      );
    } else if (rawUser != null) {
      senderId = _normalizeId(rawUser);
    }

    return MessageModel(
      id: msgId.isNotEmpty ? msgId : 'msg_${DateTime.now().microsecondsSinceEpoch}',
      gameId: gameId,
      senderId: isSystem ? 'system' : senderId,
      senderName: isSystem ? 'System' : senderName,
      senderAvatar: senderAvatar,
      text: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isSystemMessage: isSystem,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Normalises a Mongo ObjectId (plain string or `{ $oid: '...' }` map) to a
  /// standardized trimmed lowercase string for reliable comparison.
  static String _normalizeId(dynamic id) {
    if (id == null) return '';
    if (id is String) return id.trim().toLowerCase();
    if (id is Map && id.containsKey(r'$oid')) {
      return id[r'$oid'].toString().trim().toLowerCase();
    }
    return id.toString().trim().toLowerCase();
  }

  /// Returns null for empty/null avatar URLs.
  static String? _cleanUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }
}
