/// Profile module validators — run before calling use cases.
class ProfileValidators {
  ProfileValidators._();

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'At least 3 characters required';
    if (value.trim().length > 30) return 'Username too long (max 30 chars)';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  static String? validateBio(String? value) {
    if (value == null) return null;
    if (value.length > 200) return 'Bio too long (max 200 characters)';
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Display name is required';
    if (value.trim().length < 2) return 'At least 2 characters required';
    if (value.trim().length > 50) return 'Display name too long';
    return null;
  }

  /// Returns completion percent (0–100) for a profile entity map.
  static int completionPercent(Map<String, dynamic> fields) {
    final keys = [
      'avatarUrl',
      'coverUrl',
      'bio',
      'username',
      'favouriteGame',
      'displayName',
    ];
    int filled = 0;
    for (final k in keys) {
      final v = fields[k];
      if (v != null && v.toString().isNotEmpty) filled++;
    }
    return (filled / keys.length * 100).round();
  }
}
