enum NotificationType {
  gameJoin,
  gameLeave,
  gameCreate,
  gameFull,
  gameStart,
  gameEnd,
  chatMessage,
  leaderboard,
  gameCancel,
  gameCancelled,
  gameCompleted,
  completionBonus,
  system;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'game_join':
        return NotificationType.gameJoin;
      case 'game_leave':
        return NotificationType.gameLeave;
      case 'game_create':
        return NotificationType.gameCreate;
      case 'game_full':
        return NotificationType.gameFull;
      case 'game_start':
        return NotificationType.gameStart;
      case 'game_end':
        return NotificationType.gameEnd;
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'leaderboard':
        return NotificationType.leaderboard;
      case 'game_cancel':
      case 'game_cancelled':
        return NotificationType.gameCancelled;
      case 'game_completed':
        return NotificationType.gameCompleted;
      case 'completion_bonus':
        return NotificationType.completionBonus;
      default:
        return NotificationType.system;
    }
  }
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final String? link;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.link,
    this.read = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Business logic
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool get isGameRelated => [
        NotificationType.gameJoin,
        NotificationType.gameLeave,
        NotificationType.gameCreate,
        NotificationType.gameFull,
        NotificationType.gameStart,
        NotificationType.gameEnd,
        NotificationType.gameCancelled,
        NotificationType.gameCompleted,
      ].contains(type);

  bool get hasBonus => type == NotificationType.completionBonus;
}
