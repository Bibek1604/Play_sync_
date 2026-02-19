import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/entities/player.dart';

/// Game DTO (Data Transfer Object)
/// 
/// Handles JSON serialization/deserialization for API responses
/// Maps backend game schema to Flutter domain model
class GameDto {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final List<String> tags;
  final String? imageUrl;
  final String? imagePublicId;
  final int maxPlayers;
  final int minPlayers;
  final int currentPlayers;
  final String category;
  final String status;
  final String creatorId;
  final List<ParticipantDto> participants;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? endedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  // Location coordinates for offline games
  final double? latitude;
  final double? longitude;
  final double? maxDistance;

  GameDto({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.tags,
    this.imageUrl,
    this.imagePublicId,
    required this.maxPlayers,
    required this.minPlayers,
    required this.currentPlayers,
    required this.category,
    required this.status,
    required this.creatorId,
    required this.participants,
    required this.startTime,
    required this.endTime,
    this.endedAt,
    this.cancelledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.latitude,
    this.longitude,
    this.maxDistance,
  });

  factory GameDto.fromJson(Map<String, dynamic> json) {
    return GameDto(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      imageUrl: json['imageUrl'],
      imagePublicId: json['imagePublicId'],
      maxPlayers: json['maxPlayers'] ?? json['max_players'] ?? 10,
      minPlayers: json['minPlayers'] ?? json['min_players'] ?? 2,
      currentPlayers: json['currentPlayers'] ?? json['current_players'] ?? 0,
      category: json['category'] ?? 'ONLINE',
      status: json['status'] ?? 'OPEN',
      creatorId: json['creatorId']?.toString() ?? 
                 json['creator_id']?.toString() ?? 
                 json['hostId']?.toString() ?? '',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => ParticipantDto.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      startTime: _parseDateTime(json['startTime'] ?? json['start_time'] ?? json['createdAt']),
      endTime: _parseDateTime(json['endTime'] ?? json['end_time']),
      endedAt: _parseDateTime(json['endedAt'] ?? json['ended_at']),
      cancelledAt: _parseDateTime(json['cancelledAt'] ?? json['cancelled_at']),
      completedAt: _parseDateTime(json['completedAt'] ?? json['completed_at']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at'] ?? json['createdAt']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      latitude: json['latitude']?.toDouble() ?? json['lat']?.toDouble(),
      longitude: json['longitude']?.toDouble() ?? json['lon']?.toDouble() ?? json['lng']?.toDouble(),
      maxDistance: json['maxDistance']?.toDouble() ?? json['max_distance']?.toDouble(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'location': location,
      'tags': tags,
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'currentPlayers': currentPlayers,
      'category': category,
      'status': status,
      'creatorId': creatorId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'latitude': latitude,
      'longitude': longitude,
      'maxDistance': maxDistance,
    };
  }

  /// Convert DTO to Domain Entity
  Game toEntity() {
    return Game(
      id: id,
      title: title,
      description: description,
      location: location,
      tags: tags,
      imageUrl: imageUrl,
      maxPlayers: maxPlayers,
      minPlayers: minPlayers,
      currentPlayers: currentPlayers,
      category: GameCategory.fromString(category),
      status: GameStatus.fromString(status),
      creatorId: creatorId,
      participants: participants.map((p) => p.toEntity()).toList(),
      startTime: startTime,
      endTime: endTime,
      endedAt: endedAt,
      cancelledAt: cancelledAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
      latitude: latitude,
      longitude: longitude,
      maxDistance: maxDistance,
    );
  }
}

/// Participant DTO - maps backend participant sub-document
class ParticipantDto {
  final String userId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String status;
  final List<ActivityLogDto> activityLogs;

  ParticipantDto({
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    required this.status,
    required this.activityLogs,
  });

  factory ParticipantDto.fromJson(Map<String, dynamic> json) {
    return ParticipantDto(
      userId: json['userId']?.toString() ?? 
              json['user_id']?.toString() ?? 
              json['id']?.toString() ?? '',
      joinedAt: GameDto._parseDateTime(json['joinedAt'] ?? json['joined_at']),
      leftAt: json['leftAt'] != null || json['left_at'] != null
          ? GameDto._parseDateTime(json['leftAt'] ?? json['left_at'])
          : null,
      status: json['status'] ?? 'ACTIVE',
      activityLogs: (json['activityLogs'] as List<dynamic>?)
          ?.map((log) => ActivityLogDto.fromJson(log as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'status': status,
      'activityLogs': activityLogs.map((log) => log.toJson()).toList(),
    };
  }

  /// Convert to domain Player entity
  Player toEntity() {
    return Player(
      id: userId,
      joinedAt: joinedAt,
      isActive: status == 'ACTIVE',
    );
  }
}

/// Activity Log DTO
class ActivityLogDto {
  final String status;
  final DateTime timestamp;

  ActivityLogDto({
    required this.status,
    required this.timestamp,
  });

  factory ActivityLogDto.fromJson(Map<String, dynamic> json) {
    return ActivityLogDto(
      status: json['status'] ?? 'OFFLINE',
      timestamp: GameDto._parseDateTime(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Legacy PlayerDto for backward compatibility
class PlayerDto extends ParticipantDto {
  PlayerDto({
    required super.userId,
    required super.joinedAt,
    super.leftAt,
    required super.status,
    required super.activityLogs,
  });

  factory PlayerDto.fromJson(Map<String, dynamic> json) {
    final participant = ParticipantDto.fromJson(json);
    return PlayerDto(
      userId: participant.userId,
      joinedAt: participant.joinedAt,
      leftAt: participant.leftAt,
      status: participant.status,
      activityLogs: participant.activityLogs,
    );
  }
}
