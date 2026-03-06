import 'package:equatable/equatable.dart';

/// Valid responses a user can give to a game invitation.
enum InvitationAction { accept, decline }

/// Status of a game invitation.
enum InvitationStatus { pending, accepted, declined, expired }

/// A direct game invitation sent by the host to a specific user.
class GameInvitation extends Equatable {
  final String id;
  final String gameId;
  final String invitedBy;
  final String invitedUser;
  final String? message;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  // Populated fields (optional — may come from backend)
  final String? gameTitle;
  final String? inviterName;

  const GameInvitation({
    required this.id,
    required this.gameId,
    required this.invitedBy,
    required this.invitedUser,
    this.message,
    this.status = InvitationStatus.pending,
    required this.expiresAt,
    required this.createdAt,
    this.gameTitle,
    this.inviterName,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  factory GameInvitation.fromJson(Map<String, dynamic> json) {
    // gameId may be populated object or string
    final rawGame = json['gameId'];
    String gameId;
    String? gameTitle;
    if (rawGame is Map<String, dynamic>) {
      gameId = rawGame['_id'] as String? ?? rawGame['id'] as String? ?? '';
      gameTitle = rawGame['title'] as String?;
    } else {
      gameId = rawGame?.toString() ?? '';
    }

    // invitedBy may be populated object or string
    final rawInviter = json['invitedBy'];
    String invitedBy;
    String? inviterName;
    if (rawInviter is Map<String, dynamic>) {
      invitedBy = rawInviter['_id'] as String? ?? rawInviter['id'] as String? ?? '';
      inviterName = rawInviter['fullName'] as String?;
    } else {
      invitedBy = rawInviter?.toString() ?? '';
    }

    final rawInvitedUser = json['invitedUser'];
    final invitedUser = rawInvitedUser is Map<String, dynamic>
        ? (rawInvitedUser['_id'] as String? ?? rawInvitedUser['id'] as String? ?? '')
        : rawInvitedUser?.toString() ?? '';

    return GameInvitation(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      gameId: gameId,
      invitedBy: invitedBy,
      invitedUser: invitedUser,
      message: json['message'] as String?,
      status: InvitationStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => InvitationStatus.pending,
      ),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      gameTitle: gameTitle,
      inviterName: inviterName,
    );
  }

  @override
  List<Object?> get props => [id, gameId, status];
}
