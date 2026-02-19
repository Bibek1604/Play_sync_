/// Classifies the type of notification to determine icon and routing behaviour.
enum NotificationType {
  gameInvite,
  playerJoined,
  playerLeft,
  gameStarting,
  gameEnded,
  gameCancelled,
  newMessage,
  badgeEarned,
  friendRequest,
  system,
}

extension NotificationTypeX on NotificationType {
  String get displayLabel {
    switch (this) {
      case NotificationType.gameInvite:
        return 'Game Invite';
      case NotificationType.playerJoined:
        return 'Player Joined';
      case NotificationType.playerLeft:
        return 'Player Left';
      case NotificationType.gameStarting:
        return 'Game Starting';
      case NotificationType.gameEnded:
        return 'Game Ended';
      case NotificationType.gameCancelled:
        return 'Game Cancelled';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.badgeEarned:
        return 'Badge Earned';
      case NotificationType.friendRequest:
        return 'Friend Request';
      case NotificationType.system:
        return 'System';
    }
  }

  String get iconAsset {
    switch (this) {
      case NotificationType.gameInvite:
      case NotificationType.playerJoined:
      case NotificationType.gameStarting:
      case NotificationType.gameEnded:
      case NotificationType.gameCancelled:
      case NotificationType.playerLeft:
        return 'sports_esports';
      case NotificationType.newMessage:
        return 'chat_bubble';
      case NotificationType.badgeEarned:
        return 'emoji_events';
      case NotificationType.friendRequest:
        return 'person_add';
      case NotificationType.system:
        return 'info';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}
