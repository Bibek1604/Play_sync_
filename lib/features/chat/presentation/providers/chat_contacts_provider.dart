import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

// ---------------------------------------------------------------------------
// GameContact entity (lightweight)
// ---------------------------------------------------------------------------

class GameContact {
  final String userId;
  final String fullName;
  final String? profilePicture;
  final bool isOnline;

  const GameContact({
    required this.userId,
    required this.fullName,
    this.profilePicture,
    this.isOnline = false,
  });

  factory GameContact.fromJson(Map<String, dynamic> json) => GameContact(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String? ?? '',
        profilePicture: json['profilePicture'] as String?,
        isOnline: json['isOnline'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// GameContacts state
// ---------------------------------------------------------------------------

class GameContactsState {
  final List<GameContact> contacts;
  final bool isLoading;
  final String? error;

  const GameContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  GameContactsState copyWith({
    List<GameContact>? contacts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GameContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GameContactsNotifier extends StateNotifier<GameContactsState> {
  final Dio _dio;

  GameContactsNotifier(this._dio) : super(const GameContactsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(ApiEndpoints.getGameContacts);
      final data = response.data['data'] as Map<String, dynamic>?;
      final contactsJson = data?['contacts'] as List<dynamic>? ?? [];
      final contacts = contactsJson
          .map((e) => GameContact.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(contacts: contacts, isLoading: false);
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

final gameContactsProvider =
    StateNotifierProvider<GameContactsNotifier, GameContactsState>((ref) {
  return GameContactsNotifier(ref.watch(dioProvider));
});
