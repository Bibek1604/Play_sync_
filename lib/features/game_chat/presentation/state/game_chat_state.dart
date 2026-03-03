import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

/// Immutable state for the game chat feature.
class GameChatState extends Equatable {
  /// Full list of messages for the active game room, oldest-first.
  final List<MessageEntity> messages;

  /// True while [fetchMessages] is in flight (initial load).
  final bool isLoading;

  /// True while [sendMessage] is in flight.
  final bool isSending;

  /// Non-null when the last operation failed.
  final String? error;

  const GameChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  GameChatState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return GameChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isSending, error];
}
