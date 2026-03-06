import 'package:equatable/equatable.dart';

/// Represents a shareable invite link for a game.
class InviteLink extends Equatable {
  final String inviteCode;
  final DateTime expiresAt;
  final String inviteUrl;

  const InviteLink({
    required this.inviteCode,
    required this.expiresAt,
    required this.inviteUrl,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory InviteLink.fromJson(Map<String, dynamic> json) {
    return InviteLink(
      inviteCode: json['inviteCode'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      inviteUrl: json['inviteUrl'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [inviteCode, expiresAt];
}

/// Details returned when resolving an invite code.
class InviteDetails extends Equatable {
  final String inviteCode;
  final String gameId;
  final String gameTitle;
  final String? gameDescription;
  final int currentPlayers;
  final int maxPlayers;
  final String gameStatus;
  final String? imageUrl;

  const InviteDetails({
    required this.inviteCode,
    required this.gameId,
    required this.gameTitle,
    this.gameDescription,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.gameStatus,
    this.imageUrl,
  });

  bool get isFull => currentPlayers >= maxPlayers;
  bool get isOpen => gameStatus == 'OPEN';

  factory InviteDetails.fromJson(Map<String, dynamic> json) {
    final game = json['game'] as Map<String, dynamic>? ?? {};
    return InviteDetails(
      inviteCode: json['inviteCode'] as String? ?? '',
      gameId: game['id'] as String? ?? game['_id'] as String? ?? '',
      gameTitle: game['title'] as String? ?? '',
      gameDescription: game['description'] as String?,
      currentPlayers: game['currentPlayers'] as int? ?? 0,
      maxPlayers: game['maxPlayers'] as int? ?? 0,
      gameStatus: game['status'] as String? ?? 'OPEN',
      imageUrl: game['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [inviteCode, gameId];
}
