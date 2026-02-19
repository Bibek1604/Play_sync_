import 'package:hive/hive.dart';
import 'package:play_sync_new/features/game/data/models/chat_message_dto.dart';

/// Chat Local Data Source (Data Layer)
/// 
/// Handles local caching of chat messages using Hive
class ChatLocalDataSource {
  final Box<dynamic> _metadataBox;

  ChatLocalDataSource(this._metadataBox);

  /// Cache chat messages for a game
  Future<void> cacheChatMessages(String gameId, List<ChatMessageDto> messages) async {
    try {
      final key = 'chat_$gameId';
      final jsonList = messages.map((m) => {
        'id': m.id,
        'gameId': m.gameId,
        'senderId': m.senderId,
        'senderName': m.senderName,
        'message': m.message,
        'timestamp': m.timestamp,
        'type': m.type,
      }).toList();
      
      await _metadataBox.put(key, jsonList);
      await _updateCacheTimestamp('${key}_timestamp');
    } catch (e) {
      throw Exception('Failed to cache chat messages: $e');
    }
  }

  /// Get cached chat messages for a game
  Future<List<ChatMessageDto>> getCachedChatMessages(String gameId) async {
    try {
      if (_isCacheExpired('chat_${gameId}_timestamp')) {
        return [];
      }
      
      final key = 'chat_$gameId';
      final jsonList = _metadataBox.get(key) as List<dynamic>?;
      
      if (jsonList == null) return [];
      
      return jsonList.map((json) {
        final map = Map<String, dynamic>.from(json);
        return ChatMessageDto.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get cached chat messages: $e');
    }
  }

  /// Add a single message to cache
  Future<void> addChatMessage(String gameId, ChatMessageDto message) async {
    try {
      final cached = await getCachedChatMessages(gameId);
      
      // Check if message already exists
      if (!cached.any((m) => m.id == message.id)) {
        cached.add(message);
        await cacheChatMessages(gameId, cached);
      }
    } catch (e) {
      throw Exception('Failed to add chat message: $e');
    }
  }

  /// Clear chat cache for a game
  Future<void> clearChatCache(String gameId) async {
    try {
      await _metadataBox.delete('chat_$gameId');
      await _metadataBox.delete('chat_${gameId}_timestamp');
    } catch (e) {
      throw Exception('Failed to clear chat cache: $e');
    }
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp(String key) async {
    await _metadataBox.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if cache is expired (15 minutes for chat)
  bool _isCacheExpired(String timestampKey) {
    final timestamp = _metadataBox.get(timestampKey) as int?;
    if (timestamp == null) return true;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    return difference.inMinutes > 15;
  }
}
