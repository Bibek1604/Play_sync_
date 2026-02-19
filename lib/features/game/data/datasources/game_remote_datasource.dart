import 'dart:async';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';
import 'package:play_sync_new/features/game/data/models/chat_message_dto.dart';
import 'package:play_sync_new/features/game/data/models/game_history_dto.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/services/socket_service.dart';

/// Game Remote Data Source (Data Layer)
/// 
/// Handles all HTTP and WebSocket communication for games
class GameRemoteDataSource {
  final Dio _dio;
  final SocketService _socketService;

  GameRemoteDataSource(this._dio, this._socketService);

  /// Get all available games
  Future<List<GameDto>> getAvailableGames({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getAllGames,
        queryParameters: {'page': page, 'limit': limit},
      );
      
      final data = response.data;
      final List<dynamic> games = data is Map 
          ? (data['data']?['games'] ?? data['games'] ?? [])
          : data;
      
      return games.map((json) => GameDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get specific game by ID
  Future<GameDto> getGameById(String gameId) async {
    try {
      final endpoint = ApiEndpoints.getGameById.replaceAll(':id', gameId);
      final response = await _dio.get(endpoint);
      
      final data = response.data is Map 
          ? (response.data['data']?['game'] ?? response.data['data'] ?? response.data)
          : response.data;
      
      return GameDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new game
  Future<GameDto> createGame({
    required String title,
    String? description,
    required List<String> tags,
    required int maxPlayers,
    required DateTime endTime,
    XFile? imageFile,
  }) async {
    try {
      MultipartFile? imageMultipart;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'game_image.jpg';
        imageMultipart = MultipartFile.fromBytes(bytes, filename: fileName);
      }
      final formData = FormData.fromMap({
        'title': title,
        if (description != null) 'description': description,
        'tags': tags,
        'maxPlayers': maxPlayers,
        'endTime': endTime.toIso8601String(),
        if (imageMultipart != null) 'image': imageMultipart,
      });
      
      final response = await _dio.post(
        ApiEndpoints.createGame,
        data: formData,
      );
      
      final data = response.data is Map 
          ? (response.data['data']?['game'] ?? response.data['data'] ?? response.data)
          : response.data;
      
      return GameDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join an existing game
  Future<GameDto> joinGame(String gameId) async {
    try {
      final endpoint = ApiEndpoints.joinGame.replaceAll(':id', gameId);
      final response = await _dio.post(endpoint);
      
      final data = response.data is Map 
          ? (response.data['data']?['game'] ?? response.data['data'] ?? response.data)
          : response.data;
      
      // Emit socket event for joining
      _socketService.emit('join-game', {'gameId': gameId});
      
      return GameDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave a game
  Future<void> leaveGame(String gameId) async {
    try {
      final endpoint = ApiEndpoints.leaveGame.replaceAll(':id', gameId);
      await _dio.post(endpoint);
      
      // Emit socket event for leaving
      _socketService.emit('leave-game', {'gameId': gameId});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get games created by current user
  Future<List<GameDto>> getMyCreatedGames({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getMyCreatedGames,
        queryParameters: {'page': page, 'limit': limit},
      );
      
      final data = response.data;
      final List<dynamic> games = data is Map 
          ? (data['data']?['games'] ?? data['games'] ?? [])
          : data;
      
      return games.map((json) => GameDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get games joined by current user
  Future<List<GameDto>> getMyJoinedGames({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getMyJoinedGames,
        queryParameters: {'page': page, 'limit': limit},
      );
      
      final data = response.data;
      final List<dynamic> games = data is Map 
          ? (data['data']?['games'] ?? data['games'] ?? [])
          : data;
      
      return games.map((json) => GameDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if user can join a game
  Future<Map<String, dynamic>> canJoinGame(String gameId) async {
    try {
      final endpoint = ApiEndpoints.canJoinGame.replaceAll(':id', gameId);
      final response = await _dio.get(endpoint);
      
      final data = response.data is Map 
          ? (response.data['data'] ?? response.data)
          : response.data;
      
      return {
        'canJoin': data['canJoin'] ?? false,
        'reason': data['reason'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get popular game tags
  Future<List<String>> getPopularTags() async {
    try {
      final response = await _dio.get(ApiEndpoints.getPopularTags);
      
      final data = response.data;
      final List<dynamic> tags = data is Map 
          ? (data['data']?['tags'] ?? data['tags'] ?? [])
          : data;
      
      return tags.map((tag) => tag.toString()).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update game settings
  Future<GameDto> updateGame(
    String gameId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final endpoint = ApiEndpoints.updateGame.replaceAll(':id', gameId);
      final response = await _dio.patch(
        endpoint,
        data: updates,
      );
      
      final data = response.data is Map 
          ? (response.data['data']?['game'] ?? response.data['data'] ?? response.data)
          : response.data;
      
      return GameDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a game
  Future<void> deleteGame(String gameId) async {
    try {
      final endpoint = ApiEndpoints.deleteGame.replaceAll(':id', gameId);
      await _dio.delete(endpoint);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat messages for a game
  Future<List<ChatMessageDto>> getChatMessages(String gameId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.replacePath(ApiEndpoints.getChatMessages, {'gameId': gameId}),
      );

      // Safely extract messages from any backend response shape:
      // Shape A: [ {...}, {...} ]                     (bare list)
      // Shape B: { messages: [...] }                 (top-level key)
      // Shape C: { data: [...] }                     (data = list)
      // Shape D: { data: { messages: [...] } }       (nested – caused _JsonMap error)
      // Shape E: { success: true, messages: [...] }  (success wrapper)
      final raw = response.data;
      List<dynamic> messages;

      if (raw is List) {
        messages = raw;
      } else if (raw is Map) {
        final inner = raw['data'];
        if (inner is List) {
          // Shape C
          messages = inner;
        } else if (inner is Map) {
          // Shape D — the one that was causing _JsonMap error
          final deep = inner['messages'] ?? inner['data'] ?? inner['chat'] ?? [];
          messages = deep is List ? deep : [];
        } else {
          // Shape B / E — try common top-level keys
          final top = raw['messages'] ?? raw['chat'] ?? raw['results'] ?? [];
          messages = top is List ? top : [];
        }
      } else {
        messages = [];
      }

      return messages
          .whereType<Map<String, dynamic>>()
          .map((json) => ChatMessageDto.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send a chat message
  Future<ChatMessageDto> sendChatMessage(
    String gameId,
    String message,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.replacePath(ApiEndpoints.sendChatMessage, {'gameId': gameId}),
        data: {'message': message},
      );
      
      final data = response.data is Map 
          ? (response.data['data'] ?? response.data)
          : response.data;
      
      return ChatMessageDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get game history
  Future<List<GameHistoryDto>> getGameHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.historyList,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      final List<dynamic> history = response.data is Map 
          ? (response.data['data'] ?? response.data['history'] ?? [])
          : response.data;
      
      return history.map((json) => GameHistoryDto.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Watch game updates via WebSocket
  Stream<GameDto> watchGame(String gameId) {
    final controller = StreamController<GameDto>.broadcast();

    // Listen to game update events
    _socketService.on(ApiEndpoints.socketGameUpdate, (data) {
      if (data != null && data is Map) {
        final game = GameDto.fromJson(data as Map<String, dynamic>);
        if (game.id == gameId) {
          controller.add(game);
        }
      }
    });

    return controller.stream;
  }

  /// Watch chat messages via WebSocket
  Stream<ChatMessageDto> watchChatMessages(String gameId) {
    final controller = StreamController<ChatMessageDto>.broadcast();

    // Listen to chat message events
    _socketService.on(ApiEndpoints.socketChatMessage, (data) {
      if (data != null && data is Map) {
        final message = ChatMessageDto.fromJson(data as Map<String, dynamic>);
        if (message.gameId == gameId) {
          controller.add(message);
        }
      }
    });

    return controller.stream;
  }

  /// Error handler
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      final message = data is Map 
          ? (data['message'] ?? data['error'] ?? 'An error occurred')
          : 'An error occurred';
      return Exception(message);
    }
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return Exception('Unable to connect to server. Please try again later.');
    }
    
    return Exception('Network error: ${error.message}');
  }
}
