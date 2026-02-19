import 'dart:math' show sin, cos, sqrt, asin, pi;
import 'package:play_sync_new/features/game/domain/entities/player.dart';

/// Game Entity (Domain Layer)
/// 
/// Pure business logic model - no JSON serialization
class Game {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final List<String> tags;
  final String? imageUrl;
  final int maxPlayers;
  final int minPlayers;
  final int currentPlayers;
  final GameCategory category;
  final GameStatus status;
  final String creatorId;
  final List<Player> participants;
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
  final double? maxDistance; // in kilometers

  const Game({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.tags,
    this.imageUrl,
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

  // Computed properties
  bool get isFull => currentPlayers >= maxPlayers;
  bool get isOpen => status == GameStatus.open;
  bool get hasEnded => endedAt != null || status == GameStatus.ended;
  bool get isCancelled => status == GameStatus.cancelled;
  int get availableSlots => maxPlayers - currentPlayers;
  bool get isOnline => category == GameCategory.online;
  bool get isOffline => category == GameCategory.offline;

  // Legacy getters for backward compatibility
  String get name => title;
  String get hostId => creatorId;
  List<Player> get players => participants;

  Game copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    List<String>? tags,
    String? imageUrl,
    int? maxPlayers,
    int? minPlayers,
    int? currentPlayers,
    GameCategory? category,
    GameStatus? status,
    String? creatorId,
    List<Player>? participants,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? endedAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      category: category ?? this.category,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endedAt: endedAt ?? this.endedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxDistance: maxDistance ?? this.maxDistance,
    );
  }

  /// Calculate distance from given coordinates (Haversine formula)
  double? distanceFrom(double lat, double lon) {
    if (latitude == null || longitude == null) return null;
    
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat - latitude!);
    final dLon = _toRadians(lon - longitude!);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude!)) * cos(_toRadians(lat)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);

  /// Check if game is within distance from given coordinates
  bool isWithinDistance(double lat, double lon) {
    if (maxDistance == null) return true; // No distance limit
    final distance = distanceFrom(lat, lon);
    return distance != null && distance <= maxDistance!;
  }
}

/// Game Category - matches backend enum
enum GameCategory {
  online,
  offline;

  static GameCategory fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ONLINE':
        return GameCategory.online;
      case 'OFFLINE':
        return GameCategory.offline;
      default:
        return GameCategory.online;
    }
  }

  String toJson() => name.toUpperCase();
}

/// Game Status - matches backend enum
enum GameStatus {
  open,    // OPEN - accepting players
  full,    // FULL - max players reached
  ended,   // ENDED - game finished
  cancelled; // CANCELLED - game cancelled

  static GameStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return GameStatus.open;
      case 'FULL':
        return GameStatus.full;
      case 'ENDED':
        return GameStatus.ended;
      case 'CANCELLED':
        return GameStatus.cancelled;
      // Legacy status mappings
      case 'WAITING':
        return GameStatus.open;
      case 'PLAYING':
      case 'ACTIVE':
        return GameStatus.open;
      case 'FINISHED':
      case 'COMPLETED':
        return GameStatus.ended;
      default:
        return GameStatus.open;
    }
  }

  String toJson() => name.toUpperCase();
  
  // Legacy compatibility
  static const waiting = open;
  static const playing = open;
  static const paused = open;
  static const finished = ended;
}
