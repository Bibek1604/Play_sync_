import 'package:equatable/equatable.dart';

/// Tournament status enum matching backend
enum TournamentStatus { open, closed, ongoing, completed, cancelled }

/// Participant in a tournament
class TournamentParticipant extends Equatable {
  final String userId;
  final String? fullName;
  final String? avatar;
  final String? paymentId;
  final DateTime? joinedAt;

  const TournamentParticipant({
    required this.userId,
    this.fullName,
    this.avatar,
    this.paymentId,
    this.joinedAt,
  });

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    // userId can be a string or a populated object
    final rawUser = json['userId'];
    String id;
    String? name;
    String? av;

    if (rawUser is Map<String, dynamic>) {
      id = rawUser['_id']?.toString() ?? '';
      name = rawUser['fullName'] as String?;
      av = rawUser['avatar'] as String?;
    } else {
      id = rawUser?.toString() ?? '';
    }

    return TournamentParticipant(
      userId: id,
      fullName: name,
      avatar: av,
      paymentId: json['paymentId']?.toString(),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'avatar': avatar,
        'paymentId': paymentId,
        'joinedAt': joinedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [userId, fullName, paymentId, joinedAt];
}

/// Tournament creator info (populated from backend)
class TournamentCreator extends Equatable {
  final String id;
  final String? fullName;
  final String? avatar;

  const TournamentCreator({
    required this.id,
    this.fullName,
    this.avatar,
  });

  factory TournamentCreator.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return TournamentCreator(
        id: json['_id']?.toString() ?? '',
        fullName: json['fullName'] as String?,
        avatar: json['avatar'] as String?,
      );
    }
    return TournamentCreator(id: json?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'avatar': avatar,
      };

  @override
  List<Object?> get props => [id, fullName, avatar];
}

/// Main tournament entity
class TournamentEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String type; // "online" | "offline"
  final TournamentStatus status;
  final double entryFee;
  final String? prize;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? game;
  final String? rules;
  final TournamentCreator creatorId;
  final List<TournamentParticipant> participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TournamentEntity({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    required this.entryFee,
    this.prize,
    required this.maxPlayers,
    required this.currentPlayers,
    this.startDate,
    this.endDate,
    this.game,
    this.rules,
    required this.creatorId,
    this.participants = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the current user is the creator
  bool isCreator(String userId) => creatorId.id == userId;

  /// Whether the current user is a participant
  bool isParticipant(String userId) =>
      participants.any((p) => p.userId == userId);

  /// Whether entry requires payment
  bool get requiresPayment => entryFee > 0;

  /// Whether tournament is joinable
  bool get isJoinable =>
      status == TournamentStatus.open && currentPlayers < maxPlayers;

  factory TournamentEntity.fromJson(Map<String, dynamic> json) {
    return TournamentEntity(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'online',
      status: _parseStatus(json['status'] as String?),
      entryFee: (json['entryFee'] ?? json['entryAmount'] ?? 0).toDouble(),
      prize: json['prize'] as String?,
      maxPlayers: (json['maxPlayers'] ?? 0) as int,
      currentPlayers: (json['currentPlayers'] ?? 0) as int,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      game: json['game'] as String?,
      rules: json['rules'] as String?,
      creatorId: TournamentCreator.fromJson(json['creatorId'] ?? ''),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => TournamentParticipant.fromJson(
                  p is Map<String, dynamic> ? p : {'userId': p}))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'type': type,
        'status': status.name,
        'entryFee': entryFee,
        'prize': prize,
        'maxPlayers': maxPlayers,
        'currentPlayers': currentPlayers,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'game': game,
        'rules': rules,
        'creatorId': creatorId.toJson(),
        'participants': participants.map((p) => p.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static TournamentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return TournamentStatus.open;
      case 'closed':
        return TournamentStatus.closed;
      case 'ongoing':
        return TournamentStatus.ongoing;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.open;
    }
  }

  @override
  List<Object?> get props => [id, name, status, entryFee, currentPlayers];
}
