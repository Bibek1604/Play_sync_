import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/api/secure_storage_provider.dart';
import '../../../core/services/socket_service.dart';
import '../domain/entities/game_entity.dart';
import '../presentation/providers/game_notifier.dart';

/// Backend game-related Socket.IO events
class _GameSocketEvent {
  static const playerJoined = 'game:player:joined';
  static const playerLeft = 'game:player:left';
  static const statusChanged = 'game:status:changed';
  static const slotsUpdated = 'game:slots:updated';
  static const gameCreated = 'game:created';
  static const gameDeleted = 'game:deleted';
  static const gameUpdated = 'game:updated';
  static const memberRemoved = 'game:member:removed';
  static const memberBanned = 'game:member:banned';
}

/// Listens to real-time game events from Socket.IO and syncs them into
/// the [GameNotifier] state.
///
/// Features:
///   - Joins the `discovery` room to receive listing-level updates
///   - Listens for player join/leave, status changes, CRUD broadcasts
///   - Automatically reconnects when the socket reconnects
///   - Provides a per-game room subscription (`watchGame` / `unwatchGame`)
class GameEventListener {
  final GameNotifier _notifier;
  final FlutterSecureStorage _storage;

  io.Socket? _socket;
  final Set<String> _watchedGameIds = {};
  bool _discoveryJoined = false;

  GameEventListener(this._notifier, this._storage);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Connects to the socket and registers all game event listeners.
  /// Safe to call multiple times — idempotent.
  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return;

    _socket = SocketService.instance.getSocket(token: token);
    _registerListeners();

    // Join discovery room for listing updates
    if (!_discoveryJoined) {
      _socket!.emit('join:discovery');
      _discoveryJoined = true;
      debugPrint('[GameEventListener] Joined discovery room');
    }
  }

  /// Disconnects listeners. Does NOT disconnect the shared socket.
  void dispose() {
    _removeListeners();
    _watchedGameIds.clear();
    _discoveryJoined = false;
  }

  /// Subscribe to a specific game room for granular events (player join/leave etc.)  
  void watchGame(String gameId) {
    if (_watchedGameIds.add(gameId)) {
      _socket?.emit('join:game', gameId);
      debugPrint('[GameEventListener] Watching game $gameId');
    }
  }

  /// Unsubscribe from a specific game room.
  void unwatchGame(String gameId) {
    if (_watchedGameIds.remove(gameId)) {
      _socket?.emit('leave:game', gameId);
      debugPrint('[GameEventListener] Unwatched game $gameId');
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _registerListeners() {
    if (_socket == null) return;
    _removeListeners(); // Prevent duplicates

    _socket!
      ..on(_GameSocketEvent.playerJoined, _onPlayerJoined)
      ..on(_GameSocketEvent.playerLeft, _onPlayerLeft)
      ..on(_GameSocketEvent.statusChanged, _onStatusChanged)
      ..on(_GameSocketEvent.slotsUpdated, _onSlotsUpdated)
      ..on(_GameSocketEvent.gameCreated, _onGameCreated)
      ..on(_GameSocketEvent.gameDeleted, _onGameDeleted)
      ..on(_GameSocketEvent.gameUpdated, _onGameUpdated)
      ..on(_GameSocketEvent.memberRemoved, _onMemberRemoved)
      ..on('connect', (_) {
        // Re-join rooms after reconnect
        if (_discoveryJoined) _socket!.emit('join:discovery');
        for (final id in _watchedGameIds) {
          _socket!.emit('join:game', id);
        }
      });
  }

  void _removeListeners() {
    _socket?.off(_GameSocketEvent.playerJoined);
    _socket?.off(_GameSocketEvent.playerLeft);
    _socket?.off(_GameSocketEvent.statusChanged);
    _socket?.off(_GameSocketEvent.slotsUpdated);
    _socket?.off(_GameSocketEvent.gameCreated);
    _socket?.off(_GameSocketEvent.gameDeleted);
    _socket?.off(_GameSocketEvent.gameUpdated);
    _socket?.off(_GameSocketEvent.memberRemoved);
  }

  // ── Event handlers ──────────────────────────────────────────────────────

  void _onPlayerJoined(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;

    debugPrint('[GameEventListener] Player joined game $gameId');
    // Force-refresh this game from backend for authoritative state
    _notifier.fetchGameById(gameId, forceRefresh: true);
  }

  void _onPlayerLeft(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;

    debugPrint('[GameEventListener] Player left game $gameId');
    _notifier.fetchGameById(gameId, forceRefresh: true);
  }

  void _onStatusChanged(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;

    debugPrint('[GameEventListener] Status changed for game $gameId → ${map['status']}');
    _notifier.fetchGameById(gameId, forceRefresh: true);
  }

  void _onSlotsUpdated(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;

    // Lightweight — just update current players count without full refetch
    final currentPlayers = map['currentPlayers'] as int?;
    if (currentPlayers != null) {
      debugPrint('[GameEventListener] Slots updated for $gameId → $currentPlayers');
    }
  }

  void _onGameCreated(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    debugPrint('[GameEventListener] New game created: ${map['gameId']}');
    // Refresh the game list to include the new game
    _notifier.fetchGames(refresh: true);
  }

  void _onGameDeleted(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;
    debugPrint('[GameEventListener] Game deleted: $gameId');
    // Refresh list to remove deleted game
    _notifier.fetchGames(refresh: true);
  }

  void _onGameUpdated(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;
    debugPrint('[GameEventListener] Game updated: $gameId');
    _notifier.fetchGameById(gameId, forceRefresh: true);
  }

  void _onMemberRemoved(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final gameId = map['gameId'] as String?;
    if (gameId == null) return;
    debugPrint('[GameEventListener] Member removed from game $gameId');
    _notifier.fetchGameById(gameId, forceRefresh: true);
    _notifier.fetchMyJoinedGames();
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provides a [GameEventListener] that syncs real-time game events
/// from Socket.IO into the [GameNotifier] state.
///
/// Usage:
/// ```dart
/// final listener = ref.read(gameEventListenerProvider);
/// listener.connect();         // On app startup / after login
/// listener.watchGame(id);     // When viewing game detail
/// listener.unwatchGame(id);   // When leaving game detail
/// listener.dispose();         // On logout
/// ```
final gameEventListenerProvider = Provider<GameEventListener>((ref) {
  final notifier = ref.watch(gameProvider.notifier);
  final storage = ref.watch(secureStorageProvider);
  final listener = GameEventListener(notifier, storage);
  ref.onDispose(listener.dispose);
  return listener;
});
