import 'package:play_sync_new/features/scorecard/domain/entities/points_trend.dart';

class PointsTrendDto {
  final String date;
  final int points;

  PointsTrendDto({
    required this.date,
    required this.points,
  });

  factory PointsTrendDto.fromJson(Map<String, dynamic> json) {
    return PointsTrendDto(
      date: json['date'] ?? DateTime.now().toIso8601String(),
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'points': points,
    };
  }

  PointsTrend toEntity() {
    return PointsTrend(
      date: DateTime.parse(date),
      points: points,
    );
  }
}
