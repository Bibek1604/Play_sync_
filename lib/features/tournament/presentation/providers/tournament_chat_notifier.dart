import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/api/secure_storage_provider.dart';
import '../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/tournament_chat_message.dart';
import '../../data/datasources/tournament_local_datasource.dart';
import 'tournament_notifier.dart';
class TournamentChatState {
  final List<TournamentChatMessage> messages;
  final List<TournamentParticipantInfo> participants;
  final bool isConnected;
  final bool isSending;
  final bool isLoadingHistory;
  final String? error;
  final String? activeTournamentId;

  const TournamentChatState({
    this.messages = const [],
    this.participants = const [],
    this.isConnected = false,
    this.isSending = false,
    this.isLoadingHistory = false,
    this.error,
    this.activeTournamentId,
  });

  TournamentChatState copyWith({
    List<TournamentChatMessage>? messages,
    List<TournamentParticipantInfo>? participants,
    bool? isConnected,
    bool? isSending,
    bool? isLoadingHistory,
    String? error,
    String? activeTournamentId,
    bool clearError = false,
    bool clearRoom = false,
  }) {
    return TournamentChatState(
      messages: messages ?? this.messages,
      participants: participants ?? this.participants,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : (error ?? this.error),
      activeTournamentId:
          clearRoom ? null : (activeTournamentId ?? this.activeTournamentId),
    );
  }
}
class TournamentChatNotifier extends StateNotifier<TournamentChatState> {
  final Ref _ref;
  final TournamentLocalDataSource _localDs;
  io.Socket? _socket;

  TournamentChatNotifier(this._ref, this._localDs)
      : super(const TournamentChatState());

  String get _myId =>
      _ref.read(authNotifierProvider).user?.userId ?? '';
Future<void> joinRoom(String tournamentId) async {
    if (state.activeTournamentId == tournamentId && state.isConnected) return;

    // Leave previous room if any
    if (state.activeTournamentId != null) {
      leaveRoom();
    }

    state = state.copyWith(
      activeTournamentId: tournamentId,
      isLoadingHistory: true,
      clearError: true,
    );

    // Load cached messages first
    final cached = await _localDs.getCachedChatMessages(tournamentId);
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(messages: cached);
    }

    // Connect socket
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token') ?? '';
    if (token.isEmpty) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Not authenticated',
      );
      return;
    }

    _socket = SocketService.instance.getSocket(token: token);
    _setupListeners(tournamentId);

    // Emit join — backend will respond with tournament:history + tournament:participants
    _socket!.emit('tournament:join', {'tournamentId': tournamentId});
  }

  void _setupListeners(String tournamentId) {
    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        state = state.copyWith(isConnected: true);
        // Re-join room on reconnect
        _socket!.emit('tournament:join', {'tournamentId': tournamentId});
      })
      ..on('disconnect', (_) {
        if (!mounted) return;
        state = state.copyWith(isConnected: false);
      })
      ..on('tournament:history', (data) {
        if (!mounted) return;
        _handleHistory(data, tournamentId);
      })
      ..on('tournament:message', (data) {
        if (!mounted) return;
        _handleNewMessage(data, tournamentId);
      })
      ..on('tournament:participants', (data) {
        if (!mounted) return;
        _handleParticipants(data);
      })
      ..on('tournament:error', (data) {
        if (!mounted) return;
        final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
        state = state.copyWith(
          error: map['message'] as String? ?? 'Chat error',
        );
      });
  }
void _handleHistory(dynamic data, String tournamentId) {
    try {
      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        rawList = data['messages'] as List? ?? data['data'] as List? ?? [];
      } else {
        rawList = [];
      }

      final messages = rawList
          .map((j) =>
              TournamentChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();

      // Merge with existing (dedup by id)
      final merged = _mergeMessages(state.messages, messages);
      state = state.copyWith(
        messages: merged,
        isLoadingHistory: false,
        isConnected: true,
      );

      // Cache locally
      _localDs.cacheChatMessages(tournamentId, merged);
    } catch (e) {
      debugPrint('[TournamentChat] History parse error: $e');
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  void _handleNewMessage(dynamic data, String tournamentId) {
    try {
      final map = data as Map<String, dynamic>;
      final message = TournamentChatMessage.fromJson(map);

      // Skip own echo — optimistic message already shown
      final senderId = message.userId is TournamentChatUser
          ? (message.userId as TournamentChatUser).id
          : message.userId?.toString() ?? '';
      if (senderId == _myId) return;

      final updated = _mergeMessages(state.messages, [message]);
      state = state.copyWith(messages: updated);

      // Append to cache
      _localDs.cacheChatMessages(tournamentId, updated);
    } catch (e) {
      debugPrint('[TournamentChat] Message parse error: $e');
    }
  }

  void _handleParticipants(dynamic data) {
    try {
      final map = data as Map<String, dynamic>;
      final List<TournamentParticipantInfo> participants = [];

      // Creator
      if (map['creator'] != null) {
        final c = map['creator'] as Map<String, dynamic>;
        participants.add(TournamentParticipantInfo(
          id: c['_id'] as String? ?? '',
          fullName: c['fullName'] as String? ?? 'Creator',
          avatar: c['avatar'] as String?,
          isCreator: true,
        ));
      }

      // Members
      final members = map['members'] as List? ?? [];
      for (final m in members) {
        if (m is Map<String, dynamic>) {
          participants.add(TournamentParticipantInfo(
            id: m['_id'] as String? ?? '',
            fullName: m['fullName'] as String? ?? 'Member',
            avatar: m['avatar'] as String?,
            isCreator: false,
          ));
        }
      }

      state = state.copyWith(participants: participants);
    } catch (e) {
      debugPrint('[TournamentChat] Participants parse error: $e');
    }
  }
void sendMessage(String content) {
    final tournamentId = state.activeTournamentId;
    if (tournamentId == null ||
        content.trim().isEmpty ||
        _socket == null) {
      return;
    }

    state = state.copyWith(isSending: true);

    // Optimistic message
    final optimistic = TournamentChatMessage(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: tournamentId,
      userId: TournamentChatUser(
        id: _myId,
        fullName: _ref.read(authNotifierProvider).user?.fullName ?? 'You',
        avatar: null,
      ),
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final updated = [...state.messages, optimistic];
    state = state.copyWith(messages: updated, isSending: false);

    // Emit via socket
    _socket!.emit('tournament:send', {
      'tournamentId': tournamentId,
      'content': content.trim(),
    });
  }
void leaveRoom() {
    final tid = state.activeTournamentId;
    if (tid != null && _socket != null) {
      _socket!.emit('tournament:leave', {'tournamentId': tid});
    }
    // Remove listeners but don't disconnect socket (shared singleton)
    _socket?.off('tournament:history');
    _socket?.off('tournament:message');
    _socket?.off('tournament:participants');
    _socket?.off('tournament:error');
    state = const TournamentChatState();
  }
List<TournamentChatMessage> _mergeMessages(
    List<TournamentChatMessage> existing,
    List<TournamentChatMessage> incoming,
  ) {
    final map = <String, TournamentChatMessage>{};
    for (final m in existing) {
      final key = m.id ?? 'local_${m.hashCode}';
      map[key] = m;
    }
    for (final m in incoming) {
      // Replace temp messages when server confirms
      final key = m.id ?? 'local_${m.hashCode}';
      map[key] = m;
    }
    final merged = map.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}
final tournamentChatProvider =
    StateNotifierProvider<TournamentChatNotifier, TournamentChatState>((ref) {
  final localDs = ref.watch(tournamentLocalDataSourceProvider);
  return TournamentChatNotifier(ref, localDs);
});
