/// Extension helpers on [Map] and [List] for safe access.
extension MapX<K, V> on Map<K, V> {
  /// Returns value at [key], or [fallback] if absent or null.
  V getOrDefault(K key, V fallback) => this[key] ?? fallback;

  /// Returns a subset of the map with only the given [keys].
  Map<K, V> pick(List<K> keys) =>
      {for (final k in keys) if (containsKey(k)) k: this[k] as V};

  /// Removes entries where value is null.
  Map<K, V> whereNotNull() =>
      Map.fromEntries(entries.where((e) => e.value != null));
}

/// Extension helpers on Iterable.
extension IterableX<T> on Iterable<T> {
  /// Returns the first element satisfying [test], or null if none.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Groups elements by the key returned by [keyOf].
  Map<K, List<T>> groupBy<K>(K Function(T) keyOf) {
    final result = <K, List<T>>{};
    for (final element in this) {
      (result[keyOf(element)] ??= []).add(element);
    }
    return result;
  }

  /// Returns distinct elements based on [keyOf].
  List<T> distinctBy<K>(K Function(T) keyOf) {
    final seen = <K>{};
    return where((e) => seen.add(keyOf(e))).toList();
  }
}

extension ListX<T> on List<T> {
  /// Returns a new list with [item] toggled: added if absent, removed if present.
  List<T> toggle(T item) =>
      contains(item) ? (List.of(this)..remove(item)) : [...this, item];

  /// Safe element access — returns null instead of throwing RangeError.
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;
}
