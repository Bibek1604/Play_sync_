import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api/api_endpoints.dart';

/// States the socket connection can be in
enum SocketState { disconnected, connecting, connected, error }

/// Singleton Socket.IO wrapper for PlaySync real-time features.
///
/// Usage:
/// ```dart
/// final socket = SocketService.instance.getSocket(token: accessToken);
/// socket.emit('join-room', {'roomId': gameId});
/// socket.on('new-message', (data) { /* handle */ });
/// ```
class SocketService {
  // ── Singleton ────────────────────────────────────────────────────────────
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  // ── State ─────────────────────────────────────────────────────────────────
  io.Socket? _socket;
  String? _currentToken;

  final _stateController = StreamController<SocketState>.broadcast();

  /// Stream of socket connection states
  Stream<SocketState> get stateStream => _stateController.stream;

  SocketState _state = SocketState.disconnected;
  SocketState get state => _state;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns (and creates if needed) the socket connected with [token].
  ///
  /// Idempotent — calling multiple times with the same token returns the
  /// existing socket.  Calling with a different token reconnects.
  io.Socket getSocket({required String token}) {
    if (_socket != null && _currentToken == token && _socket!.connected) {
      return _socket!;
    }

    // Disconnect old socket if token changed
    if (_socket != null && _currentToken != token) {
      _socket!.dispose();
      _socket = null;
    }

    _currentToken = token;
    _connect();
    return _socket!;
  }

  /// Disconnect the current socket and clear the connection.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
    _updateState(SocketState.disconnected);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _connect() {
    // Build the socket URL (strip /api/v1 path)
    final socketUrl = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');

    _updateState(SocketState.connecting);

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(
            kIsWeb ? ['websocket'] : ['websocket', 'polling'],
          )
          .setAuth({'token': _currentToken})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('[Socket] Connected');
        _updateState(SocketState.connected);
      })
      ..onDisconnect((reason) {
        debugPrint('[Socket] Disconnected: $reason');
        _updateState(SocketState.disconnected);
      })
      ..onConnectError((error) {
        debugPrint('[Socket] Connect error: $error');
        _updateState(SocketState.error);
      })
      ..onError((error) {
        debugPrint('[Socket] Error: $error');
      });
  }

  void _updateState(SocketState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
