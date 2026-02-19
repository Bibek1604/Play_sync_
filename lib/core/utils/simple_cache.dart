import 'dart:math' show Random;

/// Lightweight in-memory cache with optional TTL expiry.
///
/// Useful for caching API responses between navigations without Hive.
///
/// ```dart
/// final cache = SimpleCache<List<Game>>(ttl: Duration(minutes: 5));
/// cache.set('games:online', gameList);
/// final cached = cache.get('games:online'); // null if expired
/// ```
class SimpleCache<T> {
  final Duration? ttl;
  final int maxEntries;

  final _store = <String, _CacheEntry<T>>{};
  final _random = Random();

  SimpleCache({this.ttl, this.maxEntries = 50});

  void set(String key, T value) {
    if (_store.length >= maxEntries) _evict();
    _store[key] = _CacheEntry(value: value, createdAt: DateTime.now());
  }

  T? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (ttl != null &&
        DateTime.now().difference(entry.createdAt) > ttl!) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  bool has(String key) => get(key) != null;

  void invalidate(String key) => _store.remove(key);

  void clear() => _store.clear();

  int get size => _store.length;

  void _evict() {
    // Random eviction — simple, avoids LRU overhead
    final keys = _store.keys.toList();
    _store.remove(keys[_random.nextInt(keys.length)]);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  const _CacheEntry({required this.value, required this.createdAt});
}
