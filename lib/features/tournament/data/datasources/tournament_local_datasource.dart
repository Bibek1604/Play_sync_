import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/core/constants/hive_table_constant.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_chat_message.dart';
import '../../domain/entities/tournament_payment_entity.dart';

/// Local data source for tournament caching via Hive
class TournamentLocalDataSource {
Future<Box> get _tournamentsBox async {
    if (!Hive.isBoxOpen(HiveTableConstant.tournamentsBox)) {
      return await Hive.openBox(HiveTableConstant.tournamentsBox);
    }
    return Hive.box(HiveTableConstant.tournamentsBox);
  }

  Future<Box> get _chatBox async {
    if (!Hive.isBoxOpen(HiveTableConstant.tournamentChatBox)) {
      return await Hive.openBox(HiveTableConstant.tournamentChatBox);
    }
    return Hive.box(HiveTableConstant.tournamentChatBox);
  }

  Future<Box> get _paymentsBox async {
    if (!Hive.isBoxOpen(HiveTableConstant.tournamentPaymentsBox)) {
      return await Hive.openBox(HiveTableConstant.tournamentPaymentsBox);
    }
    return Hive.box(HiveTableConstant.tournamentPaymentsBox);
  }

  /// Cache a list of tournaments
  Future<void> cacheTournaments(
      List<TournamentEntity> tournaments, String cacheKey) async {
    final box = await _tournamentsBox;
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await box.put(cacheKey, jsonEncode(jsonList));
    debugPrint('[TournamentLocal] Cached ${tournaments.length} tournaments ($cacheKey)');
  }

  /// Get cached tournaments
  Future<List<TournamentEntity>?> getCachedTournaments(String cacheKey) async {
    final box = await _tournamentsBox;
    final raw = box.get(cacheKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TournamentLocal] Cache parse error: $e');
      return null;
    }
  }

  /// Cache a single tournament
  Future<void> cacheTournament(TournamentEntity tournament) async {
    final box = await _tournamentsBox;
    await box.put(
        'tournament_${tournament.id}', jsonEncode(tournament.toJson()));
  }

  /// Get single cached tournament
  Future<TournamentEntity?> getCachedTournament(String id) async {
    final box = await _tournamentsBox;
    final raw = box.get('tournament_$id');
    if (raw == null) return null;
    try {
      return TournamentEntity.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
static const int _maxCachedMessages = 50;

  /// Cache chat messages for a tournament
  Future<void> cacheChatMessages(
      String tournamentId, List<TournamentChatMessage> messages) async {
    final box = await _chatBox;
    // Keep only the last N messages
    final trimmed = messages.length > _maxCachedMessages
        ? messages.sublist(messages.length - _maxCachedMessages)
        : messages;
    final jsonList = trimmed.map((m) => m.toJson()).toList();
    await box.put('chat_$tournamentId', jsonEncode(jsonList));
    debugPrint(
        '[TournamentLocal] Cached ${trimmed.length} chat messages ($tournamentId)');
  }

  /// Get cached chat messages
  Future<List<TournamentChatMessage>?> getCachedChatMessages(String tournamentId) async {
    final box = await _chatBox;
    final raw = box.get('chat_$tournamentId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((e) =>
              TournamentChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Append a single message and trim
  Future<void> appendChatMessage(
      String tournamentId, TournamentChatMessage message) async {
    final existing = await getCachedChatMessages(tournamentId) ?? [];
    // Deduplicate by id
    if (message.id != null && existing.any((m) => m.id == message.id)) return;
    existing.add(message);
    await cacheChatMessages(tournamentId, existing);
  }
Future<void> cachePayments(
      String key, List<TournamentPaymentEntity> payments) async {
    final box = await _paymentsBox;
    final jsonList = payments.map((p) => p.toJson()).toList();
    await box.put(key, jsonEncode(jsonList));
  }

  Future<List<TournamentPaymentEntity>?> getCachedPayments(String key) async {
    final box = await _paymentsBox;
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list
          .map((e) =>
              TournamentPaymentEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
Future<void> clearAll() async {
    final tBox = await _tournamentsBox;
    final cBox = await _chatBox;
    final pBox = await _paymentsBox;
    await tBox.clear();
    await cBox.clear();
    await pBox.clear();
    debugPrint('[TournamentLocal] All caches cleared');
  }

  Future<void> clearChat(String tournamentId) async {
    final box = await _chatBox;
    await box.delete('chat_$tournamentId');
  }
}
