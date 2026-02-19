import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_filter.freezed.dart';

enum LeaderboardPeriod { allTime, monthly, weekly, daily }

enum LeaderboardScope { global, friends, local }

@freezed
class LeaderboardFilter with _$LeaderboardFilter {
  const factory LeaderboardFilter({
    @Default(LeaderboardPeriod.allTime) LeaderboardPeriod period,
    @Default(LeaderboardScope.global) LeaderboardScope scope,
    String? sportType,
    @Default(50) int limit,
    @Default(0) int offset,
  }) = _LeaderboardFilter;

  const LeaderboardFilter._();

  Map<String, String> toQueryParams() {
    return {
      'period': period.name,
      'scope': scope.name,
      if (sportType != null) 'sportType': sportType!,
      'limit': '$limit',
      'offset': '$offset',
    };
  }

  LeaderboardFilter copyWithNextPage() => copyWith(offset: offset + limit);
}
