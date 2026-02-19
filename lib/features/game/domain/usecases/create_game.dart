import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Parameters for creating a game
class CreateGameParams {
  final String title;
  final String description;
  final List<String> tags;
  final int maxPlayers;
  final DateTime endTime;
  final XFile? imageFile;

  CreateGameParams({
    required this.title,
    required this.description,
    required this.tags,
    required this.maxPlayers,
    required this.endTime,
    this.imageFile,
  });
}

/// Create Game Use Case
class CreateGame {
  final GameRepository repository;

  CreateGame(this.repository);

  Future<Game> call(CreateGameParams params) async {
    // Business logic validation
    if (params.title.trim().isEmpty) {
      throw Exception('Game title cannot be empty');
    }

    if (params.title.trim().length < 3) {
      throw Exception('Game title must be at least 3 characters');
    }

    if (params.maxPlayers < 2) {
      throw Exception('Maximum players must be at least 2');
    }

    if (params.maxPlayers > 100) {
      throw Exception('Maximum players cannot exceed 100');
    }

    if (params.endTime.isBefore(DateTime.now())) {
      throw Exception('End time must be in the future');
    }

    return await repository.createGame(
      title: params.title,
      description: params.description,
      tags: params.tags,
      maxPlayers: params.maxPlayers,
      endTime: params.endTime,
      imageFile: params.imageFile,
    );
  }
}
