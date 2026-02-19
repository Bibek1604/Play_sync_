import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

// ---------------------------------------------------------------------------
// ChatPreview entity
// ---------------------------------------------------------------------------

class ChatPreview {
  final String gameId;
  final String title;
  final String? imageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatPreview({
    required this.gameId,
    required this.title,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) => ChatPreview(
        gameId: json['gameId'] as String,
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        lastMessage: json['lastMessage'] as String?,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.tryParse(json['lastMessageAt'] as String)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

// ---------------------------------------------------------------------------
// ChatPreview state
// ---------------------------------------------------------------------------

class ChatPreviewState {
  final List<ChatPreview> previews;
  final bool isLoading;
  final String? error;

  const ChatPreviewState({
    this.previews = const [],
    this.isLoading = false,
    this.error,
  });

  ChatPreviewState copyWith({
    List<ChatPreview>? previews,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatPreviewState(
      previews: previews ?? this.previews,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatPreviewNotifier extends StateNotifier<ChatPreviewState> {
  final Dio _dio;

  ChatPreviewNotifier(this._dio) : super(const ChatPreviewState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.getJoinedChatPreview);
      final data = response.data['data'] as Map<String, dynamic>?;
      final previewsJson = data?['previews'] as List<dynamic>? ?? [];
      final previews = previewsJson
          .map((e) => ChatPreview.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort by most recent message first
      previews.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
      state = state.copyWith(previews: previews, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? e.message ?? 'Unknown error',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatPreviewProvider =
    StateNotifierProvider<ChatPreviewNotifier, ChatPreviewState>((ref) {
  return ChatPreviewNotifier(ref.watch(dioProvider));
});
