/// String extension utilities used across the app.
extension StringX on String {
  /// Capitalise first letter: "hello world" → "Hello world"
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case: "hello world" → "Hello World"
  String get titleCase => split(' ').map((w) => w.capitalised).join(' ');

  /// Truncate with ellipsis: "Long text…" at [maxLength] chars.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Returns true if this string is a valid email address.
  bool get isValidEmail =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(trim());

  /// Returns true if this string looks like a URL.
  bool get isUrl => startsWith('http://') || startsWith('https://');

  /// Strips all whitespace including internal spaces.
  String get stripped => replaceAll(RegExp(r'\s+'), '');

  /// Returns initials: "Bibek Pandey" → "BP"
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Nullable String extension: safe operations when value may be null.
extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  String get orEmpty => this ?? '';
}
