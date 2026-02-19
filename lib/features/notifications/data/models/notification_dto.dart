import 'package:play_sync_new/features/notifications/domain/entities/notification.dart';

class NotificationDto {
  final String id;
  final String user;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final String? link;
  final bool read;
  final String createdAt;
  final String updatedAt;

  NotificationDto({
    required this.id,
    required this.user,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.link,
    this.read = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['_id'] ?? json['id'] ?? '',
      user: json['user'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      link: json['link'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'link': link,
      'read': read,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Notification toEntity() {
    return Notification(
      id: id,
      userId: user,
      type: NotificationType.fromString(type),
      title: title,
      message: message,
      data: data,
      link: link,
      read: read,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
