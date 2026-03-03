import 'package:equatable/equatable.dart';
import '../../../../core/api/api_endpoints.dart';

/// Backend game statuses
enum GameStatus { OPEN, FULL, ENDED, CANCELLED }

/// Resolves a possibly-relative image URL to a full URL.
/// Returns null if the input is null or empty.
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  // Relative path like /uploads/... — prepend server base
  return '${ApiEndpoints.imageBaseUrl}$url';
}

/// Backend participant statuses
enum ParticipantStatus { ACTIVE, LEFT, REMOVED, BANNED }

/// A single participant in a game
class GameParticipant extends Equatable {
  final String userId;
  final String displayName;
  final String? avatar;
  final ParticipantStatus status;
  final DateTime joinedAt;

  const GameParticipant({
    required this.userId,
    required this.displayName,
    this.avatar,
    this.status = ParticipantStatus.ACTIVE,
    required this.joinedAt,
  });

  factory GameParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    String userId;
    String displayName;
    String? avatar;
    if (user is Map<String, dynamic>) {
      userId = GameEntity.normalize(user['_id'] ?? user['id']);
      displayName = user['fullName'] as String? ?? user['email'] as String? ?? '';
      avatar = _resolveImageUrl(user['profilePicture'] as String? ?? user['avatar'] as String?);
    } else {
      userId = GameEntity.normalize(user);
      displayName = '';
    }
    return GameParticipant(
      userId: userId,
      displayName: displayName,
      avatar: avatar,
      status: ParticipantStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'ACTIVE'),
        orElse: () => ParticipantStatus.ACTIVE,
      ),
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, status];
}

/// GeoJSON point
class GeoLocation extends Equatable {
  final double longitude;
  final double latitude;
  final String? address;

  const GeoLocation({required this.longitude, required this.latitude, this.address});

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List?;
    return GeoLocation(
      longitude: (coords != null && coords.length >= 2) ? (coords[0] as num).toDouble() : 0,
      latitude: (coords != null && coords.length >= 2) ? (coords[1] as num).toDouble() : 0,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
    if (address != null) 'address': address,
  };

  @override
  List<Object?> get props => [longitude, latitude];
}

/// Core game entity matching the backend Game model.
class GameEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String sport;
  final String category; // "ONLINE" | "OFFLINE"
  final GameStatus status;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime? startTime;
  final DateTime? endTime;
  final GeoLocation? location;
  final List<String> tags;
  final List<GameParticipant> participants;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GameEntity({
    required this.id,
    required this.title,
    this.description = '',
    this.sport = '',
    this.category = 'OFFLINE',
    this.status = GameStatus.OPEN,
    required this.creatorId,
    this.creatorName = '',
    this.creatorAvatar,
    this.maxPlayers = 2,
    this.currentPlayers = 0,
    this.startTime,
    this.endTime,
    this.location,
    this.tags = const [],
    this.participants = const [],
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOnline => category == 'ONLINE';
  bool get isOffline => category == 'OFFLINE';
  bool get isFull => currentPlayers >= maxPlayers;
  bool get isOpen => status == GameStatus.OPEN;
  bool get isEnded => status == GameStatus.ENDED;
  bool get isCancelled => status == GameStatus.CANCELLED;
  int get spotsLeft => maxPlayers - currentPlayers;
  
  /// Returns the full image URL for the game cover image.
  /// Converts relative paths (e.g., "/uploads/games/abc.jpg") to full URLs.
  /// Returns null if no image is set.
  String? get imageUrl => _resolveImageUrl(image);

  /// Normalizes an ID to a plain string. Handles Mongo ObjectId map format if present.
  /// Standardized to trimmed lowercase for reliable comparison.
  static String normalize(dynamic id) {
    if (id == null) return '';
    String result = '';
    if (id is String) {
      result = id;
    } else if (id is Map && id.containsKey(r'$oid')) {
      result = id[r'$oid'].toString();
    } else {
      result = id.toString();
    }
    return result.trim().toLowerCase();
  }

  bool isParticipant(String userId) {
    final normalizedSearchId = normalize(userId);
    if (normalizedSearchId.isEmpty) return false;
    return participants.any((p) => 
      normalize(p.userId) == normalizedSearchId && 
      p.status == ParticipantStatus.ACTIVE
    );
  }

  bool isCreator(String userId) {
    final normalizedSearchId = normalize(userId);
    final normalizedCreatorId = normalize(creatorId);
    if (normalizedSearchId.isEmpty) return false;
    return normalizedCreatorId == normalizedSearchId;
  }

  factory GameEntity.fromJson(Map<String, dynamic> json) {
    // Parse creator (may be populated object or plain string id)
    final creator = json['creatorId'];
    String creatorId;
    String creatorName;
    String? creatorAvatar;
    if (creator is Map<String, dynamic>) {
      creatorId = normalize(creator['_id'] ?? creator['id']);
      creatorName = creator['fullName'] as String? ?? creator['email'] as String? ?? '';
      creatorAvatar = _resolveImageUrl(creator['profilePicture'] as String? ?? creator['avatar'] as String?);
    } else {
      creatorId = normalize(creator);
      creatorName = json['creatorName'] as String? ?? '';
    }

    final rawParticipants = json['participants'] as List? ?? [];
    final parsedParticipants = rawParticipants
        .map((p) => GameParticipant.fromJson(p as Map<String, dynamic>))
        .toList();

    return GameEntity(
      id: normalize(json['_id'] ?? json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      category: json['category'] as String? ?? 'OFFLINE',
      status: GameStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'OPEN'),
        orElse: () => GameStatus.OPEN,
      ),
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      maxPlayers: json['maxPlayers'] as int? ?? 2,
      currentPlayers: json['currentPlayers'] as int? ?? parsedParticipants.where((p) => p.status == ParticipantStatus.ACTIVE).length,
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      location: json['location'] != null ? GeoLocation.fromJson(json['location'] as Map<String, dynamic>) : null,
      tags: List<String>.from(json['tags'] as List? ?? []),
      participants: parsedParticipants,
      image: json['image'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'sport': sport,
    'category': category,
    'maxPlayers': maxPlayers,
    'status': status.name,
    'currentPlayers': currentPlayers,
    'participants': participants.map((p) => {
      'userId': {
        '_id': p.userId,
        'fullName': p.displayName,
        if (p.avatar != null) 'profilePicture': p.avatar,
      },
      'status': p.status.name,
      'joinedAt': p.joinedAt.toIso8601String(),
    }).toList(),
    'creatorId': creatorId,
    'creatorName': creatorName,
    if (creatorAvatar != null) 'creatorAvatar': creatorAvatar,
    if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    if (startTime != null) 'startTime': startTime!.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    if (location != null) 'location': location!.toJson(),
    if (tags.isNotEmpty) 'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'description': description,
    'sport': sport,
    'category': category,
    'maxPlayers': maxPlayers,
    if (startTime != null) 'startTime': startTime!.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    if (location != null) 'location': location!.toJson(),
    if (tags.isNotEmpty) 'tags': tags,
  };

  @override
  List<Object?> get props => [id, status, currentPlayers, participants];
}
