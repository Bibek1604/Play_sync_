import 'package:equatable/equatable.dart';

enum GameStatus { upcoming, live, completed, cancelled }

enum GameCategory { football, basketball, cricket, tennis, badminton, chess, other }

/// Core game entity matching the backend Game model.
class GameEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final GameCategory category;
  final GameStatus status;
  final String hostId;
  final String hostName;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime scheduledAt;
  final String? location;
  final bool isOnline;
  final List<String> participantIds;
  final String? thumbnailUrl;
  final int entryFee;
  final int prizePool;

  const GameEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.hostId,
    required this.hostName,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.scheduledAt,
    this.location,
    this.isOnline = false,
    required this.participantIds,
    this.thumbnailUrl,
    this.entryFee = 0,
    this.prizePool = 0,
  });

  bool get isFull => currentPlayers >= maxPlayers;
  bool get hasStarted => status == GameStatus.live || status == GameStatus.completed;
  int get spotsLeft => maxPlayers - currentPlayers;

  factory GameEntity.fromJson(Map<String, dynamic> json) {
    return GameEntity(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: GameCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String? ?? 'other'),
        orElse: () => GameCategory.other,
      ),
      status: GameStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'upcoming'),
        orElse: () => GameStatus.upcoming,
      ),
      hostId: json['hostId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? 'Unknown',
      maxPlayers: json['maxPlayers'] as int? ?? 2,
      currentPlayers: json['currentPlayers'] as int? ?? 0,
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      participantIds: List<String>.from(json['participantIds'] as List? ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      entryFee: json['entryFee'] as int? ?? 0,
      prizePool: json['prizePool'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, status, currentPlayers];
}
