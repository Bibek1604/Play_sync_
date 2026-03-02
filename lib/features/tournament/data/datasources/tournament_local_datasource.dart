import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/core/constants/hive_table_constant.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_chat_message.dart';
import '../../domain/entities/tournament_payment_entity.dart';

/// Local data source for tournament caching via Hive
class TournamentLocalDataSource {
  // ── Tournament list cache ─────────────────────────────────────────────────

  Box get _tournamentsBox => Hive.box(HiveTableConstant.tournamentsBox);
  Box get _chatBox => Hive.box(HiveTableConstant.tournamentChatBox);
  Box get _paymentsBox => Hive.box(HiveTableConstant.tournamentPaymentsBox);

  /// Cache a list of tournaments
  Future<void> cacheTournaments(
      List<TournamentEntity> tournaments, String cacheKey) async {
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await _tournamentsBox.put(cacheKey, jsonEncode(jsonList));
    debugPrint('[TournamentLocal] Cached ${tournaments.length} tournaments ($cacheKey)');
  }

  /// Get cached tournaments
  List<TournamentEntity>? getCachedTournaments(String cacheKey) {
    final raw = _tournamentsBox.get(cacheKey);
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
    await _tournamentsBox.put(
        'tournament_${tournament.id}', jsonEncode(tournament.toJson()));
  }

  /// Get single cached tournament
  TournamentEntity? getCachedTournament(String id) {
    final raw = _tournamentsBox.get('tournament_$id');
    if (raw == null) return null;
    try {
      return TournamentEntity.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Tournament chat cache (last 50 messages per room) ─────────────────────

  static const int _maxCachedMessages = 50;

  /// Cache chat messages for a tournament
  Future<void> cacheChatMessages(
      String tournamentId, List<TournamentChatMessage> messages) async {
    // Keep only the last N messages
    final trimmed = messages.length > _maxCachedMessages
        ? messages.sublist(messages.length - _maxCachedMessages)
        : messages;
    final jsonList = trimmed.map((m) => m.toJson()).toList();
    await _chatBox.put('chat_$tournamentId', jsonEncode(jsonList));
    debugPrint(
        '[TournamentLocal] Cached ${trimmed.length} chat messages ($tournamentId)');
  }

  /// Get cached chat messages
  List<TournamentChatMessage>? getCachedChatMessages(String tournamentId) {
    final raw = _chatBox.get('chat_$tournamentId');
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
    final existing = getCachedChatMessages(tournamentId) ?? [];
    // Deduplicate by id
    if (message.id != null && existing.any((m) => m.id == message.id)) return;
    existing.add(message);
    await cacheChatMessages(tournamentId, existing);
  }

  // ── Payment cache ─────────────────────────────────────────────────────────

  Future<void> cachePayments(
      String key, List<TournamentPaymentEntity> payments) async {
    final jsonList = payments.map((p) => p.toJson()).toList();
    await _paymentsBox.put(key, jsonEncode(jsonList));
  }

  List<TournamentPaymentEntity>? getCachedPayments(String key) {
    final raw = _paymentsBox.get(key);
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

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _tournamentsBox.clear();
    await _chatBox.clear();
    await _paymentsBox.clear();
    debugPrint('[TournamentLocal] All caches cleared');
  }

  Future<void> clearChat(String tournamentId) async {
    await _chatBox.delete('chat_$tournamentId');
  }
}
