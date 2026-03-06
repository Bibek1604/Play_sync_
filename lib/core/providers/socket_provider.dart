import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/socket_service.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';

/// Socket connection state exposed via Riverpod.
class SocketConnectionState {
  final SocketState state;
  final io.Socket? socket;

  const SocketConnectionState({
    this.state = SocketState.disconnected,
    this.socket,
  });

  bool get isConnected => state == SocketState.connected;

  SocketConnectionState copyWith({
    SocketState? state,
    io.Socket? socket,
    bool clearSocket = false,
  }) {
    return SocketConnectionState(
      state: state ?? this.state,
      socket: clearSocket ? null : (socket ?? this.socket),
    );
  }
}

/// Manages Socket.IO connection lifecycle tied to auth state.
///
/// Auto-connects when user authenticates, disconnects on logout.
/// Joins the user's personal room for notifications.
class SocketConnectionNotifier extends StateNotifier<SocketConnectionState> {
  final Ref _ref;
  StreamSubscription? _socketStateSub;
  io.Socket? _socket;

  SocketConnectionNotifier(this._ref)
      : super(const SocketConnectionState()) {
    // Watch auth state and auto-connect/disconnect
    _ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.isAuthenticated && next.user?.token != null) {
        connect(next.user!.token!, next.user!.userId);
      } else if (prev?.isAuthenticated == true && !next.isAuthenticated) {
        disconnect();
      }
    }, fireImmediately: true);
  }

  /// Connect to the WebSocket server with the given token.
  void connect(String token, String? userId) {
    if (state.isConnected && _socket != null) {
      debugPrint('[SocketProvider] Already connected, skipping...');
      return;
    }

    try {
      debugPrint('[SocketProvider] 🔌 Connecting to WebSocket...');
      debugPrint('[SocketProvider] User ID: $userId');
      _socket = SocketService.instance.getSocket(token: token);

      // Listen to connection state changes
      _socketStateSub?.cancel();
      _socketStateSub =
          SocketService.instance.stateStream.listen((socketState) {
        debugPrint('[SocketProvider] State changed: $socketState');
        state = state.copyWith(state: socketState, socket: _socket);

        // Join personal room on connect
        if (socketState == SocketState.connected && userId != null) {
          _socket?.emit('join-room', {'roomId': 'user:$userId'});
          debugPrint('[SocketProvider] ✓ Joined room user:$userId');
        }
      });

      state = state.copyWith(
        state: SocketService.instance.state,
        socket: _socket,
      );

      // Also listen for game discovery events
      _socket?.on('game:updated', (data) {
        debugPrint('[SocketProvider] 📢 Game updated: $data');
      });

      _socket?.on('game:slots:updated', (data) {
        debugPrint('[SocketProvider] 📢 Game slots updated: $data');
      });
      
      debugPrint('[SocketProvider] ✓ Socket listeners registered');
    } catch (e, stack) {
      debugPrint('[SocketProvider] ✗ Connect error: $e');
      debugPrint('[SocketProvider] Stack: $stack');
    }
  }

  /// Join a specific game room for real-time updates.
  void joinGameRoom(String gameId) {
    _socket?.emit('join-room', {'roomId': 'game:$gameId'});
    debugPrint('[SocketProvider] Joined game room: game:$gameId');
  }

  /// Leave a specific game room.
  void leaveGameRoom(String gameId) {
    _socket?.emit('leave-room', {'roomId': 'game:$gameId'});
    debugPrint('[SocketProvider] Left game room: game:$gameId');
  }

  /// Join the discovery room for browsing game updates.
  void joinDiscovery() {
    _socket?.emit('join-room', {'roomId': 'discovery'});
    debugPrint('[SocketProvider] Joined discovery room');
  }

  /// Leave the discovery room.
  void leaveDiscovery() {
    _socket?.emit('leave-room', {'roomId': 'discovery'});
  }

  /// Disconnect socket.
  void disconnect() {
    _socketStateSub?.cancel();
    _socketStateSub = null;
    SocketService.instance.disconnect();
    _socket = null;
    state = const SocketConnectionState();
    debugPrint('[SocketProvider] Disconnected');
  }

  @override
  void dispose() {
    _socketStateSub?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final socketProvider = StateNotifierProvider<SocketConnectionNotifier,
    SocketConnectionState>((ref) {
  return SocketConnectionNotifier(ref);
});

/// Convenience provider to get current socket instance (nullable).
final socketInstanceProvider = Provider<io.Socket?>((ref) {
  return ref.watch(socketProvider).socket;
});
