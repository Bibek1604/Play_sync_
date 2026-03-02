import 'package:equatable/equatable.dart';

/// Chat message for tournament chat (Socket.IO)
class TournamentChatMessage extends Equatable {
  final String? id;
  final String tournamentId;
  final TournamentChatUser? userId;
  final String content;
  final DateTime createdAt;

  const TournamentChatMessage({
    this.id,
    required this.tournamentId,
    this.userId,
    required this.content,
    required this.createdAt,
  });

  factory TournamentChatMessage.fromJson(Map<String, dynamic> json) {
    return TournamentChatMessage(
      id: json['_id']?.toString(),
      tournamentId: json['tournamentId']?.toString() ?? '',
      userId: json['userId'] is Map<String, dynamic>
          ? TournamentChatUser.fromJson(json['userId'])
          : json['userId'] != null
              ? TournamentChatUser(id: json['userId'].toString())
              : null,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tournamentId': tournamentId,
        'userId': userId?.toJson(),
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, tournamentId, content, createdAt];
}

/// User info attached to a chat message
class TournamentChatUser extends Equatable {
  final String id;
  final String? fullName;
  final String? avatar;

  const TournamentChatUser({
    required this.id,
    this.fullName,
    this.avatar,
  });

  factory TournamentChatUser.fromJson(Map<String, dynamic> json) {
    return TournamentChatUser(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'avatar': avatar,
      };

  @override
  List<Object?> get props => [id, fullName, avatar];
}

/// Participant info from tournament:participants event
class TournamentParticipantInfo extends Equatable {
  final String id;
  final String fullName;
  final String? avatar;
  final bool isCreator;

  const TournamentParticipantInfo({
    required this.id,
    required this.fullName,
    this.avatar,
    this.isCreator = false,
  });

  @override
  List<Object?> get props => [id, fullName, avatar, isCreator];
}
