import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/entities/player.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable state for offline games list.
class OfflineGamesState {
  const OfflineGamesState({
    this.games = const [],
    this.isLoading = false,
    this.error,
    this.joiningGameId,
  });

  final List<Game> games;
  final bool isLoading;

  /// Non-null while a join request is in flight.
  final String? joiningGameId;

  /// Non-null when the last operation failed.
  final String? error;

  bool get hasError => error != null;

  OfflineGamesState copyWith({
    List<Game>? games,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? joiningGameId,
    bool clearJoining = false,
  }) {
    return OfflineGamesState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      joiningGameId: clearJoining ? null : (joiningGameId ?? this.joiningGameId),
    );
  }
}

// ---------------------------------------------------------------------------
// Computed per-card state DTO (all role-based logic lives here, NOT in UI)
// ---------------------------------------------------------------------------

enum OfflineCardAction { join, chat, delete, disabled }

/// Pre-computed button state for a single card.
class OfflineGameCardState {
  const OfflineGameCardState({
    required this.game,
    required this.action,
    required this.isJoining,
    required this.statusLabel,
    required this.statusColor,
  });

  final Game game;
  final OfflineCardAction action;
  final bool isJoining;
  final String statusLabel;
  final Color statusColor;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OfflineGamesNotifier extends StateNotifier<OfflineGamesState> {
  OfflineGamesNotifier(this._ref) : super(const OfflineGamesState());

  final Ref _ref;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadGames() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(gameRepositoryProvider);
      final allGames = await repo.getAvailableGames();
      final offlineGames =
          allGames.where((g) => g.category == GameCategory.offline).toList();
      state = state.copyWith(games: offlineGames, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  // ── Join ──────────────────────────────────────────────────────────────────

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteGame(String gameId) async {
    try {
      final deleteUsecase = _ref.read(deleteGameUseCaseProvider);
      await deleteUsecase(gameId);
      state = state.copyWith(
        games: state.games.where((g) => g.id != gameId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _friendlyError(e));
      rethrow;
    }
  }

  // ── Join ──────────────────────────────────────────────────────────────────

  Future<void> joinGame(String gameId) async {
    if (state.joiningGameId != null) return; // prevent double-tap

    state = state.copyWith(joiningGameId: gameId, clearError: true);
    try {
      final repo = _ref.read(gameRepositoryProvider);
      await repo.joinGame(gameId);

      // Optimistically update the game in state:
      // increment currentPlayers and add current userId to participants.
      final userId = _ref.read(authNotifierProvider).user?.userId ?? '';
      final updatedGames = state.games.map((g) {
        if (g.id != gameId) return g;
        final newCount = g.currentPlayers + 1;
        final newStatus =
            newCount >= g.maxPlayers ? GameStatus.full : GameStatus.open;
        // Optimistically add a lightweight Player so participant checks pass.
        final updatedParticipants = [
          ...g.participants,
          Player(
            id: userId, // Player.id stores the userId from backend
            joinedAt: DateTime.now(),
          ),
        ];
        return g.copyWith(
          currentPlayers: newCount,
          status: newStatus,
          participants: updatedParticipants,
        );
      }).toList();

      state = state.copyWith(
        games: updatedGames,
        clearJoining: true,
      );
    } catch (e) {
      state = state.copyWith(
        clearJoining: true,
        error: _friendlyError(e),
      );
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Game is full') || msg.contains('FULL')) {
      return 'This game is already full.';
    }
    if (msg.contains('already joined') || msg.contains('Already joined')) {
      return 'You have already joined this game.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No connection. Check your internet.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Primary notifier provider for the offline-games screen.
final offlineGamesProvider =
    StateNotifierProvider<OfflineGamesNotifier, OfflineGamesState>((ref) {
  return OfflineGamesNotifier(ref);
});

/// Derived provider for the filtered list (search applied externally in UI).
final filteredOfflineGamesProvider =
    Provider.family<List<Game>, String>((ref, query) {
  final games = ref.watch(offlineGamesProvider).games;
  if (query.trim().isEmpty) return games;
  final q = query.toLowerCase();
  return games
      .where((g) =>
          g.title.toLowerCase().contains(q) ||
          (g.description?.toLowerCase().contains(q) ?? false) ||
          (g.location?.toLowerCase().contains(q) ?? false) ||
          g.tags.any((t) => t.toLowerCase().contains(q)))
      .toList();
});

/// Per-game computed state (role-based button logic).
final offlineGameCardStateProvider =
    Provider.family<OfflineGameCardState, Game>((ref, game) {
  final authUser = ref.watch(authNotifierProvider).user;
  final joiningId = ref.watch(offlineGamesProvider).joiningGameId;
  final userId = authUser?.userId ?? '';

  final isCreator = userId.isNotEmpty && game.creatorId == userId;
  // Player.id == userId (see ParticipantDto.toEntity)
  final isParticipant =
      !isCreator && game.participants.any((p) => p.id == userId) && userId.isNotEmpty;
  final isFull = game.isFull;
  final isJoining = joiningId == game.id;

  late OfflineCardAction action;
  if (isCreator) {
    action = OfflineCardAction.delete;
  } else if (isParticipant) {
    action = OfflineCardAction.chat;
  } else if (isFull) {
    action = OfflineCardAction.disabled;
  } else {
    action = OfflineCardAction.join;
  }

  // Status display
  final Color statusColor;
  final String statusLabel;
  (statusLabel, statusColor) = switch (game.status) {
    GameStatus.open => ('Open', const Color(0xFF10B981)),
    GameStatus.full => ('Full', const Color(0xFFF59E0B)),
    GameStatus.ended => ('Ended', const Color(0xFF94A3B8)),
    GameStatus.cancelled => ('Cancelled', const Color(0xFFEF4444)),
  };

  return OfflineGameCardState(
    game: game,
    action: action,
    isJoining: isJoining,
    statusLabel: statusLabel,
    statusColor: statusColor,
  );
});
