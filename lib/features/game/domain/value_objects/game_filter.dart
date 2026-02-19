/// Encapsulates all optional filtering criteria when querying available games.
class GameFilter {
  final String? sportType;
  final String? location;
  final double? maxDistanceKm;
  final int? minPlayers;
  final int? maxPlayers;
  final bool? onlineOnly;
  final bool? openOnly;
  final List<String>? tags;

  const GameFilter({
    this.sportType,
    this.location,
    this.maxDistanceKm,
    this.minPlayers,
    this.maxPlayers,
    this.onlineOnly,
    this.openOnly,
    this.tags,
  });

  bool get isEmpty =>
      sportType == null &&
      location == null &&
      maxDistanceKm == null &&
      minPlayers == null &&
      maxPlayers == null &&
      onlineOnly == null &&
      openOnly == null &&
      (tags == null || tags!.isEmpty);

  GameFilter copyWith({
    String? sportType,
    String? location,
    double? maxDistanceKm,
    int? minPlayers,
    int? maxPlayers,
    bool? onlineOnly,
    bool? openOnly,
    List<String>? tags,
  }) {
    return GameFilter(
      sportType: sportType ?? this.sportType,
      location: location ?? this.location,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      openOnly: openOnly ?? this.openOnly,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final map = <String, dynamic>{};
    if (sportType != null) map['sportType'] = sportType;
    if (location != null) map['location'] = location;
    if (maxDistanceKm != null) map['maxDistance'] = maxDistanceKm;
    if (minPlayers != null) map['minPlayers'] = minPlayers;
    if (maxPlayers != null) map['maxPlayers'] = maxPlayers;
    if (onlineOnly != null) map['online'] = onlineOnly;
    if (openOnly != null) map['open'] = openOnly;
    if (tags != null && tags!.isNotEmpty) map['tags'] = tags!.join(',');
    return map;
  }

  @override
  String toString() => 'GameFilter${toQueryParams()}';
}
