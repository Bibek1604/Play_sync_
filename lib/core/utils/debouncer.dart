import 'dart:async';

/// Debounce utility to throttle rapid function calls (e.g. search input).
///
/// Usage:
/// ```dart
/// final debounce = Debouncer(delay: const Duration(milliseconds: 400));
///
/// // Inside onChanged:
/// debounce.run(() => ref.read(searchProvider.notifier).search(query));
///
/// // Dispose when done:
/// debounce.dispose();
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 400)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending invocation.
  void cancel() => _timer?.cancel();

  /// Must be called in dispose() of the owning widget/notifier.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isPending => _timer?.isActive ?? false;
}

/// Function signature alias.
typedef VoidCallback = void Function();
