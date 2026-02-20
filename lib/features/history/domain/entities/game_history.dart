import 'package:equatable/equatable.dart';

/// Represents a single entry in the user's game history.
class GameHistory extends Equatable {
  final String id;
  final String gameId;
  final String gameTitle;

  /// 'online' or 'offline'
  final String category;

  /// 'win', 'loss', 'draw', or 'played'
  final String result;

  final int? score;
  final DateTime date;
  final Map<String, dynamic> metadata;

  const GameHistory({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.category,
    required this.result,
    this.score,
    required this.date,
    this.metadata = const {},
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      gameId: json['gameId'] as String? ?? '',
      gameTitle: json['gameTitle'] as String? ?? 'Unknown Game',
      category: json['category'] as String? ?? 'offline',
      result: json['result'] as String? ?? 'played',
      score: json['score'] as int?,
      date: DateTime.tryParse(json['date'] as String? ??
              json['createdAt'] as String? ??
              '') ??
          DateTime.now(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Result icon based on outcome
  static const Map<String, String> _resultIcon = {
    'win': '🏆',
    'loss': '💔',
    'draw': '🤝',
    'played': '🎮',
  };

  String get resultIcon => _resultIcon[result] ?? '🎮';

  @override
  List<Object?> get props => [id, gameId, result, date];
}
