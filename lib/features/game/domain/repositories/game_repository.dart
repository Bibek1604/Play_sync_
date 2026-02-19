import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/entities/game_history.dart';

/// Game Repository Interface (Domain Layer)
/// 
/// Defines contract for game data operations
abstract class GameRepository {
  /// Get all available games
  Future<List<Game>> getAvailableGames({GameCategory? category});

  /// Get games joined by current user
  Future<List<Game>> getMyJoinedGames();

  /// Get games near a location (for offline layer)
  Future<List<Game>> getGamesNearby({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
  });

  /// Get specific game by ID
  Future<Game> getGameById(String gameId);

  /// Create a new game
  Future<Game> createGame({
    required String title,
    required String description,
    required List<String> tags,
    required int maxPlayers,
    required DateTime endTime,
    XFile? imageFile,
  });

  /// Join an existing game
  Future<Game> joinGame(String gameId);

  /// Leave a game
  Future<void> leaveGame(String gameId);

  /// Update game settings
  Future<Game> updateGame(String gameId, Map<String, dynamic> updates);

  /// Delete a game
  Future<void> deleteGame(String gameId);

  /// Get chat messages for a game
  Future<List<ChatMessage>> getChatMessages(String gameId);

  /// Send a chat message
  Future<ChatMessage> sendChatMessage(String gameId, String message);

  /// Get game history
  Future<List<GameHistory>> getGameHistory({int page = 1, int limit = 20});

  /// Stream of real-time game updates
  Stream<Game> watchGame(String gameId);

  /// Stream of real-time chat messages
  Stream<ChatMessage> watchChatMessages(String gameId);
  /// Get games created by current user
  Future<List<Game>> getMyCreatedGames();

  /// Get popular tags
  Future<List<String>> getPopularTags();
}
