import 'package:equatable/equatable.dart';

/// Represents a single in-app notification.
class NotificationEntity extends Equatable {
  final String id;
  final String type; // 'join', 'leave', 'cancel', 'general', etc.
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  /// Icon data based on notification type
  String get iconEmoji => switch (type) {
        'join' => '🎉',
        'leave' => '👋',
        'cancel' => '❌',
        'win' => '🏆',
        'reminder' => '⏰',
        _ => '🔔',
      };

  @override
  List<Object?> get props => [id, type, isRead, createdAt];
}
