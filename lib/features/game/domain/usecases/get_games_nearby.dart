import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Get Games Nearby Use Case (Domain Layer)
/// 
/// Retrieves games near a specific location based on distance
class GetGamesNearby {
  final GameRepository _repository;

  GetGamesNearby(this._repository);

  /// Execute the use case to get games near a location
  /// 
  /// Parameters:
  /// - [latitude]: User's latitude
  /// - [longitude]: User's longitude
  /// - [maxDistanceKm]: Optional maximum distance in kilometers
  /// 
  /// Returns: List of games within the specified distance
  Future<List<Game>> call({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
  }) async {
    return await _repository.getGamesNearby(
      latitude: latitude,
      longitude: longitude,
      maxDistanceKm: maxDistanceKm,
    );
  }
}
