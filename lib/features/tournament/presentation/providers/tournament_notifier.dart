import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import '../../data/datasources/tournament_remote_datasource.dart';
import '../../data/datasources/tournament_local_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/repositories/tournament_repository.dart';
final tournamentRemoteDataSourceProvider =
    Provider<TournamentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TournamentRemoteDataSource(apiClient: apiClient);
});

final tournamentLocalDataSourceProvider =
    Provider<TournamentLocalDataSource>((ref) {
  return TournamentLocalDataSource();
});

final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return TournamentRepositoryImpl(
    remote: ref.watch(tournamentRemoteDataSourceProvider),
    local: ref.watch(tournamentLocalDataSourceProvider),
  );
});
class TournamentState {
  final List<TournamentEntity> tournaments;
  final List<TournamentEntity> myTournaments;
  final TournamentEntity? selectedTournament;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? statusFilter;
  final String? typeFilter;

  const TournamentState({
    this.tournaments = const [],
    this.myTournaments = const [],
    this.selectedTournament,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.statusFilter,
    this.typeFilter,
  });

  TournamentState copyWith({
    List<TournamentEntity>? tournaments,
    List<TournamentEntity>? myTournaments,
    TournamentEntity? selectedTournament,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? statusFilter,
    String? typeFilter,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return TournamentState(
      tournaments: tournaments ?? this.tournaments,
      myTournaments: myTournaments ?? this.myTournaments,
      selectedTournament:
          clearSelected ? null : (selectedTournament ?? this.selectedTournament),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}
class TournamentNotifier extends StateNotifier<TournamentState> {
  final ITournamentRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  TournamentNotifier(this._repository, this._ref)
      : super(const TournamentState()) {
    fetchTournaments();
  }
Future<void> fetchTournaments({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: refresh ? 1 : state.currentPage,
      hasMore: refresh ? true : state.hasMore,
    );

    final result = await _repository.getTournaments(
      page: 1,
      limit: 10,
      status: state.statusFilter,
      type: state.typeFilter,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (tournaments) => state = state.copyWith(
        isLoading: false,
        tournaments: tournaments,
        currentPage: 1,
        hasMore: tournaments.length >= 10,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.currentPage + 1;
    final result = await _repository.getTournaments(
      page: nextPage,
      limit: 10,
      status: state.statusFilter,
      type: state.typeFilter,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false),
      (tournaments) => state = state.copyWith(
        isLoadingMore: false,
        tournaments: [...state.tournaments, ...tournaments],
        currentPage: nextPage,
        hasMore: tournaments.length >= 10,
      ),
    );
  }

  Future<void> fetchMyTournaments() async {
    final result = await _repository.getMyTournaments();
    result.fold(
      (failure) => debugPrint('[Tournament] fetchMyTournaments failed: ${failure.message}'),
      (list) => state = state.copyWith(myTournaments: list),
    );
  }

  Future<void> fetchTournamentById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getTournamentById(id);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (tournament) => state = state.copyWith(
        isLoading: false,
        selectedTournament: tournament,
      ),
    );
  }
Future<bool> createTournament(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.createTournament(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (tournament) {
        state = state.copyWith(
          isLoading: false,
          tournaments: [tournament, ...state.tournaments],
          myTournaments: [tournament, ...state.myTournaments],
        );
        return true;
      },
    );
  }

  Future<bool> updateTournament(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.updateTournament(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (tournament) {
        state = state.copyWith(
          isLoading: false,
          selectedTournament: tournament,
          tournaments: state.tournaments
              .map((t) => t.id == id ? tournament : t)
              .toList(),
          myTournaments: state.myTournaments
              .map((t) => t.id == id ? tournament : t)
              .toList(),
        );
        return true;
      },
    );
  }

  Future<bool> deleteTournament(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.deleteTournament(id);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          tournaments: state.tournaments.where((t) => t.id != id).toList(),
          myTournaments: state.myTournaments.where((t) => t.id != id).toList(),
          clearSelected: true,
        );
        return true;
      },
    );
  }
void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    fetchTournaments(refresh: true);
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type);
    fetchTournaments(refresh: true);
  }

  void clearFilters() {
    state = const TournamentState();
    fetchTournaments(refresh: true);
  }
}
final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, TournamentState>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentNotifier(repository, ref);
});
