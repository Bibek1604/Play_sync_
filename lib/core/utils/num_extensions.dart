/// Numeric extension utilities.
extension NumX on num {
  /// Clamps this value to [min]..[max] inclusively.
  num clampTo(num min, num max) => clamp(min, max);

  /// Returns true if this number is between [min] and [max] (inclusive).
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Formats as a compact string: 1200 → "1.2k", 1500000 → "1.5M".
  String get compact {
    if (abs() >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (abs() >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toString();
  }

  /// Formats as an ordinal string: 1 → "1st", 2 → "2nd", 3 → "3rd".
  String get ordinal {
    final n = toInt().abs();
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

extension IntX on int {
  /// Returns a duration in seconds.
  Duration get seconds => Duration(seconds: this);

  /// Returns a duration in milliseconds.
  Duration get ms => Duration(milliseconds: this);

  /// Returns a rounded percentage string: 75 → "75%"
  String get asPercent => '$this%';
}
