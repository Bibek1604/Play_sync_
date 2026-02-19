import 'package:intl/intl.dart';

/// App-wide date/time formatting utilities.
class DateTimeUtils {
  DateTimeUtils._();

  static final _timeFormatter = DateFormat('h:mm a');
  static final _dateFormatter = DateFormat('MMM d, yyyy');
  static final _shortDateFormatter = DateFormat('MMM d');
  static final _fullFormatter = DateFormat('MMM d, yyyy · h:mm a');

  /// Returns "2:30 PM"
  static String formatTime(DateTime dt) => _timeFormatter.format(dt);

  /// Returns "Feb 19, 2026"
  static String formatDate(DateTime dt) => _dateFormatter.format(dt);

  /// Returns "Feb 19"
  static String formatShortDate(DateTime dt) => _shortDateFormatter.format(dt);

  /// Returns "Feb 19, 2026 · 2:30 PM"
  static String formatFull(DateTime dt) => _fullFormatter.format(dt);

  /// Returns relative time: "just now", "5m ago", "2h ago", "3d ago".
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(dt);
  }

  /// Returns "Starts in 3h 20m" or "Started 2 days ago".
  static String relativeToNow(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Started ${timeAgo(dt)}';
    if (diff.inMinutes < 60) return 'Starts in ${diff.inMinutes}m';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? 'Starts in ${h}h ${m}m' : 'Starts in ${h}h';
    }
    return 'Starts ${formatShortDate(dt)}';
  }
}
