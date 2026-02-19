import 'package:play_sync_new/features/game/domain/entities/game.dart';

/// Pure validation logic for game creation and update forms.
class GameValidator {
  GameValidator._();

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.trim().length < 3) return 'Title must be at least 3 characters';
    if (value.trim().length > 80) return 'Title too long (max 80 chars)';
    return null;
  }

  static String? validateMaxPlayers(int? value) {
    if (value == null) return 'Player limit is required';
    if (value < 2) return 'Minimum 2 players required';
    if (value > 100) return 'Maximum 100 players allowed';
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (value.trim().length > 500) return 'Description too long (max 500 chars)';
    return null;
  }

  /// Checks whether the user can join a game right now.
  static JoinEligibility canJoin(Game game, String userId) {
    if (game.createdBy == userId) return JoinEligibility.isCreator;
    if (game.players.any((p) => p.userId == userId)) {
      return JoinEligibility.alreadyMember;
    }
    if (game.status == GameStatus.ended) return JoinEligibility.gameEnded;
    if (game.status == GameStatus.cancelled) {
      return JoinEligibility.gameCancelled;
    }
    if (game.isFull) return JoinEligibility.gameFull;
    return JoinEligibility.eligible;
  }
}

enum JoinEligibility {
  eligible,
  isCreator,
  alreadyMember,
  gameEnded,
  gameCancelled,
  gameFull,
}

extension JoinEligibilityX on JoinEligibility {
  bool get canJoin => this == JoinEligibility.eligible;

  String get reason {
    switch (this) {
      case JoinEligibility.eligible:
        return '';
      case JoinEligibility.isCreator:
        return 'You created this game';
      case JoinEligibility.alreadyMember:
        return 'You have already joined';
      case JoinEligibility.gameEnded:
        return 'This game has ended';
      case JoinEligibility.gameCancelled:
        return 'This game was cancelled';
      case JoinEligibility.gameFull:
        return 'Game is full';
    }
  }
}
