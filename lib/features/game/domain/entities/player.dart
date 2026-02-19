/// Player Entity (Domain Layer)
class Player {
  final String id;
  final String? username;
  final String? avatar;
  final bool isActive;
  final bool isOnline;
  final DateTime joinedAt;
  final int score;
  final PlayerRole role;

  const Player({
    required this.id,
    this.username,
    this.avatar,
    this.isActive = true,
    this.isOnline = true,
    required this.joinedAt,
    this.score = 0,
    this.role = PlayerRole.player,
  });

  bool get isHost => role == PlayerRole.host;

  Player copyWith({
    String? id,
    String? username,
    String? avatar,
    bool? isActive,
    bool? isOnline,
    DateTime? joinedAt,
    int? score,
    PlayerRole? role,
  }) {
    return Player(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      joinedAt: joinedAt ?? this.joinedAt,
      score: score ?? this.score,
      role: role ?? this.role,
    );
  }
}

enum PlayerRole {
  host,
  player,
}
