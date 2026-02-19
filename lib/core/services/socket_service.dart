import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_endpoints.dart';

/// Socket.IO Service for Real-Time Features
/// 
/// Matches web version exactly:
/// - Prevents duplicate connections
/// - Handles token refresh
/// - Auto-reconnect with proper cleanup
/// - Idempotent join/rejoin logic
class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  /// Convenience getter for singleton instance
  static SocketService get instance => _instance;

  IO.Socket? _socket;
  String? _currentToken;
  final StreamController<SocketState> _stateController =
      StreamController<SocketState>.broadcast();

  /// Get socket state stream
  Stream<SocketState> get stateStream => _stateController.stream;

  /// Get current socket state
  SocketState get state {
    if (_socket == null) return SocketState.disconnected;
    if (_socket!.connected) return SocketState.connected;
    return SocketState.connecting;
  }

  /// Get or create socket connection
  IO.Socket getSocket({required String token}) {
    // If no existing socket, create new one
    if (_socket == null) {
      debugPrint('[SOCKET] 🔌 Creating new socket connection');
      _createSocket(token);
      return _socket!;
    }

    // Check if token changed
    if (_currentToken != token) {
      debugPrint('[SOCKET] 🔄 Token changed - reconnecting');
      _reconnectWithNewToken(token);
      return _socket!;
    }

    // Socket exists with same token but disconnected
    if (!_socket!.connected) {
      debugPrint('[SOCKET] 🔄 Socket disconnected - reconnecting');
      _socket!.connect();
    }

    return _socket!;
  }

  /// Create new socket connection
  void _createSocket(String token) {
    _currentToken = token;

    // Get base URL without /api/v1
    final String socketUrl = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          // Flutter Web: WebSocket-only (polling breaks on web CORS)
          // Flutter native: websocket first, polling as fallback
          .setTransports(kIsWeb ? ['websocket'] : ['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .enableAutoConnect()
          .build(),
    );

    _attachListeners();
  }

  /// Reconnect with new token
  void _reconnectWithNewToken(String token) {
    if (_socket == null) return;

    _currentToken = token;

    // Remove all listeners to prevent duplicates
    _socket!.clearListeners();

    // Update auth token
    _socket!.auth = {'token': token};

    // Disconnect and reconnect
    if (_socket!.connected) {
      _socket!.disconnect();
    }

    // Re-attach listeners
    _attachListeners();

    // Reconnect
    _socket!.connect();
  }

  /// Attach event listeners
  void _attachListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('[SOCKET] ✅ Connected: ${_socket!.id}');
      _stateController.add(SocketState.connected);
    });

    _socket!.onConnectError((error) {
      debugPrint('[SOCKET] ❌ Connection error: $error');
      _stateController.add(SocketState.error);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[SOCKET] 🔌 Disconnected: $reason');
      _stateController.add(SocketState.disconnected);

      // Auto-reconnect if server initiated disconnect
      if (reason == 'io server disconnect') {
        debugPrint('[SOCKET] 🔄 Server disconnected - reconnecting...');
        _socket!.connect();
      }
    });

    _socket!.onError((error) {
      debugPrint('[SOCKET] ❌ Error: $error');
      _stateController.add(SocketState.error);
    });

    _socket!.on('reconnect', (attempt) {
      debugPrint('[SOCKET] 🔄 Reconnected after $attempt attempts');
      _stateController.add(SocketState.connected);
    });

    _socket!.on('reconnect_attempt', (attempt) {
      debugPrint('[SOCKET] 🔄 Reconnection attempt: $attempt');
      _stateController.add(SocketState.connecting);
    });

    _socket!.on('reconnect_error', (error) {
      debugPrint('[SOCKET] ❌ Reconnection error: $error');
      _stateController.add(SocketState.error);
    });

    _socket!.on('reconnect_failed', (_) {
      debugPrint('[SOCKET] ❌ Reconnection failed');
      _stateController.add(SocketState.error);
    });
  }

  /// Emit event
  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[SOCKET] ⚠️ Cannot emit - socket not connected');
      return;
    }

    debugPrint('[SOCKET] 📤 Emitting: $event');
    _socket!.emit(event, data);
  }

  /// Emit event with optional ack callback
  /// Falls back to plain emit if socket not connected (fire-and-forget)
  void emitWithAck(String event, dynamic data, {Function(dynamic)? onAck}) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[SOCKET] ⚠️ Cannot emit (with ack) - socket not connected');
      return;
    }

    debugPrint('[SOCKET] 📤 Emitting (ack): $event');
    if (onAck != null) {
      _socket!.emitWithAck(event, data, ack: onAck);
    } else {
      _socket!.emit(event, data);
    }
  }

  /// Listen to event
  void on(String event, Function(dynamic) handler) {
    if (_socket == null) {
      debugPrint('[SOCKET] ⚠️ Cannot listen - socket not initialized');
      return;
    }

    _socket!.on(event, handler);
  }

  /// Remove listener
  void off(String event, [Function(dynamic)? handler]) {
    if (_socket == null) return;

    if (handler != null) {
      _socket!.off(event, handler);
    } else {
      _socket!.off(event);
    }
  }

  /// Check if connected
  bool get isConnected => _socket?.connected ?? false;

  /// Get socket ID
  String? get socketId => _socket?.id;

  /// Disconnect and cleanup
  void disconnectSocket() {
    if (_socket != null) {
      debugPrint('[SOCKET] 🔌 Disconnecting socket');
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _currentToken = null;
      _stateController.add(SocketState.disconnected);
    }
  }

  /// Dispose resources
  void dispose() {
    disconnectSocket();
    _stateController.close();
  }
}

/// Socket connection state
enum SocketState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Global socket service instance
final socketService = SocketService();
