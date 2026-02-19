/// Controls sorting when fetching game lists from the repository.
enum GameSortType {
  /// Most recently created first.
  newest,

  /// Closest to the user's current location.
  nearest,

  /// Games with the most active players first.
  mostPopular,

  /// Games starting soonest.
  startingSoon,

  /// Games ranked by creator rating.
  topRated,
}

extension GameSortTypeX on GameSortType {
  String get queryValue {
    switch (this) {
      case GameSortType.newest:
        return 'newest';
      case GameSortType.nearest:
        return 'nearest';
      case GameSortType.mostPopular:
        return 'popular';
      case GameSortType.startingSoon:
        return 'starting_soon';
      case GameSortType.topRated:
        return 'top_rated';
    }
  }

  String get label {
    switch (this) {
      case GameSortType.newest:
        return 'Newest First';
      case GameSortType.nearest:
        return 'Nearest';
      case GameSortType.mostPopular:
        return 'Most Popular';
      case GameSortType.startingSoon:
        return 'Starting Soon';
      case GameSortType.topRated:
        return 'Top Rated';
    }
  }
}
