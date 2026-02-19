enum LeaderboardPeriod { allTime, monthly, weekly, daily }

enum LeaderboardScope { global, friends, local }

/// Filter parameters for a leaderboard query.
class LeaderboardFilter {
  final LeaderboardPeriod period;
  final LeaderboardScope scope;
  final String? sportType;
  final int limit;
  final int offset;

  const LeaderboardFilter({
    this.period = LeaderboardPeriod.allTime,
    this.scope = LeaderboardScope.global,
    this.sportType,
    this.limit = 50,
    this.offset = 0,
  });

  LeaderboardFilter copyWith({
    LeaderboardPeriod? period,
    LeaderboardScope? scope,
    String? sportType,
    int? limit,
    int? offset,
  }) {
    return LeaderboardFilter(
      period: period ?? this.period,
      scope: scope ?? this.scope,
      sportType: sportType ?? this.sportType,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardFilter &&
          period == other.period &&
          scope == other.scope &&
          sportType == other.sportType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(period, scope, sportType, limit, offset);
}
