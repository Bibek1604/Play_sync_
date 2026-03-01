import 'package:equatable/equatable.dart';

/// Backend notification types
class NotificationType {
  static const String gameJoin = 'game_join';
  static const String gameFull = 'game_full';
  static const String chatMessage = 'chat_message';
  static const String leaderboard = 'leaderboard';
  static const String gameCancel = 'game_cancel';
  static const String gameCancelled = 'game_cancelled';
  static const String gameCompleted = 'game_completed';
  static const String system = 'system';
}

/// Represents a single in-app notification (matches backend INotification).
class NotificationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? NotificationType.system,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  NotificationEntity copyWith({bool? read}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      data: data,
    );
  }

  /// Related game ID if this notification is game-related
  String? get gameId => data['gameId'] as String?;

  /// Icon data based on notification type
  String get iconEmoji => switch (type) {
        NotificationType.gameJoin => '🎮',
        NotificationType.gameFull => '✅',
        NotificationType.gameCancel || NotificationType.gameCancelled => '❌',
        NotificationType.gameCompleted => '🏆',
        NotificationType.chatMessage => '💬',
        NotificationType.leaderboard => '📊',
        NotificationType.system => '🔔',
        _ => '🔔',
      };

  @override
  List<Object?> get props => [id, type, read, createdAt];
}
