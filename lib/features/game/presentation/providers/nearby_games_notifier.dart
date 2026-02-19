import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_games_nearby.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';
import 'package:play_sync_new/features/location/presentation/providers/location_provider.dart';

/// Nearby Games State
class NearbyGamesState {
  final List<Game> games;
  final bool isLoading;
  final String? error;
  final double? maxDistanceKm;

  const NearbyGamesState({
    this.games = const [],
    this.isLoading = false,
    this.error,
    this.maxDistanceKm = 10.0, // Default 10km radius
  });

  NearbyGamesState copyWith({
    List<Game>? games,
    bool? isLoading,
    String? error,
    double? maxDistanceKm,
  }) {
    return NearbyGamesState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }
}

/// Nearby Games Notifier
class NearbyGamesNotifier extends StateNotifier<NearbyGamesState> {
  final GetGamesNearby _getGamesNearby;
  final Ref _ref;

  NearbyGamesNotifier(this._getGamesNearby, this._ref)
      : super(const NearbyGamesState());

  Future<void> loadNearbyGames({double? maxDistanceKm}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      maxDistanceKm: maxDistanceKm,
    );

    try {
      // Get current location from location provider
      final locationState = _ref.read(locationProvider);

      if (locationState.latitude == null || locationState.longitude == null) {
        throw Exception('Location not available. Using default coordinates.');
      }

      final games = await _getGamesNearby(
        latitude: locationState.latitude!,
        longitude: locationState.longitude!,
        maxDistanceKm: state.maxDistanceKm,
      );

      state = state.copyWith(
        games: games,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadNearbyGames(maxDistanceKm: state.maxDistanceKm);
  }

  void updateMaxDistance(double distance) {
    loadNearbyGames(maxDistanceKm: distance);
  }
}

/// Nearby Games Provider
final nearbyGamesNotifierProvider =
    StateNotifierProvider<NearbyGamesNotifier, NearbyGamesState>((ref) {
  return NearbyGamesNotifier(
    ref.watch(getGamesNearbyUseCaseProvider),
    ref,
  );
});
