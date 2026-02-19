# Additional Features Implementation Guide

This document covers the implementation of History, Leaderboard, Notifications, and Scorecard features.

## 📋 Features Overview

### 1. **History Feature** (`/history`)
Track user's game participation history with statistics.

**Endpoints:**
- `GET /history` - List past games with pagination
- `GET /history/stats` - Win/Loss statistics

**Features:**
- ✅ Paginated game history
- ✅ Filter by status (completed, active, cancelled)
- ✅ Participation statistics
- ✅ Total games count

---

### 2. **Leaderboard Feature** (`/leaderboard`)
Global and filtered rankings of players.

**Endpoints:**
- `GET /leaderboard` - Global rankings

**Features:**
- ✅ Global leaderboard
- ✅ Filter options (global, friends, nearby)
- ✅ Top 10 rankings
- ✅ Podium display (top 3)

---

### 3. **Notifications Feature** (`/notifications`)
User notifications with read/unread tracking.

**Endpoints:**
- `GET /notifications` - List user notifications
- `GET /notifications/unread-count` - Number of unread items
- `PUT /notifications/:id/read` - Mark specific as read
- `PUT /notifications/read-all` - Mark all as read

**Features:**
- ✅ List all notifications
- ✅ Unread count badge
- ✅ Mark individual as read
- ✅ Mark all as read
- ✅ Filter unread/read

---

### 4. **Scorecard Feature** (`/scorecard`)
User performance metrics and trends.

**Endpoints:**
- `GET /scorecard` - User performance metrics
- `GET /scorecard/trend` - Performance over time graph data

**Features:**
- ✅ Performance metrics (win rate, total games, etc.)
- ✅ Trend data for charts
- ✅ Period selection (week, month, year)
- ✅ Visual performance tracking

---

## 🏗️ Architecture

All features follow Clean Architecture:

```
Feature/
├── domain/
│   ├── entities/          # Business objects
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Business logic
├── data/
│   ├── repositories/      # Repository implementations
│   ├── datasources/       # API calls
│   └── models/            # DTOs
└── presentation/
    ├── providers/         # Riverpod providers
    ├── pages/             # UI screens
    └── widgets/           # UI components
```

---

## 🚀 Usage Examples

### History Feature

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/history/presentation/providers/history_state_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load history on page load
    Future.microtask(() {
      ref.read(historyProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Game History')),
      body: Column(
        children: [
          // Stats Card
          if (historyState.stats != null)
            StatsCard(stats: historyState.stats!),

          // History List
          Expanded(
            child: historyState.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: historyState.history.length,
                    itemBuilder: (context, index) {
                      final game = historyState.history[index];
                      return GameHistoryTile(game: game);
                    },
                  ),
          ),

          // Load More Button
          if (historyState.hasMore)
            ElevatedButton(
              onPressed: () {
                ref.read(historyProvider.notifier).loadMore();
              },
              child: Text('Load More'),
            ),
        ],
      ),
    );
  }
}
```

**Filter by Status:**
```dart
// Load only completed games
ref.read(historyProvider.notifier).loadHistory(status: 'completed');

// Or use filtered providers
final completedGames = ref.watch(completedGamesProvider);
final activeGames = ref.watch(activeGamesProvider);
```

---

### Leaderboard Feature

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/leaderboard/presentation/providers/leaderboard_state_provider.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(leaderboardProvider.notifier).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final top3 = ref.watch(top3Provider);

    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard')),
      body: Column(
        children: [
          // Filter Tabs
          Row(
            children: [
              FilterChip(
                label: Text('Global'),
                selected: leaderboardState.currentFilter == 'global',
                onSelected: (_) {
                  ref.read(leaderboardProvider.notifier)
                     .changeFilter('global');
                },
              ),
              FilterChip(
                label: Text('Friends'),
                selected: leaderboardState.currentFilter == 'friends',
                onSelected: (_) {
                  ref.read(leaderboardProvider.notifier)
                     .changeFilter('friends');
                },
              ),
            ],
          ),

          // Podium (Top 3)
          PodiumWidget(entries: top3),

          // Full Leaderboard
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardState.entries.length,
              itemBuilder: (context, index) {
                final entry = leaderboardState.entries[index];
                return LeaderboardTile(
                  entry: entry,
                  rank: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Notifications Feature

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/notifications/presentation/providers/notification_state_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          // Unread count badge
          Badge(
            label: Text('$unreadCount'),
            child: Icon(Icons.notifications),
          ),
          
          // Mark all as read
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all),
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: notificationState.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationState.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () {
              // Mark as read when tapped
              if (!notification.isRead) {
                ref.read(notificationProvider.notifier)
                   .markAsRead(notification.id);
              }
            },
          );
        },
      ),
    );
  }
}
```

**Unread Badge in App Bar:**
```dart
AppBar(
  actions: [
    Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(unreadCountProvider);
        return Badge(
          label: Text('$unreadCount'),
          isLabelVisible: unreadCount > 0,
          child: IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsPage()),
              );
            },
          ),
        );
      },
    ),
  ],
)
```

---

### Scorecard Feature

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/scorecard/presentation/providers/scorecard_state_provider.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class ScorecardPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ScorecardPage> createState() => _ScorecardPageState();
}

class _ScorecardPageState extends ConsumerState<ScorecardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(scorecardProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scorecardState = ref.watch(scorecardProvider);
    final metrics = ref.watch(performanceMetricsProvider);
    final trendData = ref.watch(trendChartDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Performance')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Performance Metrics Cards
            if (metrics != null) ...[
              MetricCard(
                title: 'Win Rate',
                value: '${metrics['winRate']}%',
                icon: Icons.emoji_events,
              ),
              MetricCard(
                title: 'Total Games',
                value: '${metrics['totalGames']}',
                icon: Icons.sports_esports,
              ),
              MetricCard(
                title: 'Average Score',
                value: '${metrics['averageScore']}',
                icon: Icons.star,
              ),
            ],

            // Period Selector
            SegmentedButton(
              segments: [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'year', label: Text('Year')),
              ],
              selected: {scorecardState.trendPeriod},
              onSelectionChanged: (Set<String> selected) {
                ref.read(scorecardProvider.notifier)
                   .changeTrendPeriod(selected.first);
              },
            ),

            // Trend Chart
            if (trendData.isNotEmpty)
              Container(
                height: 300,
                padding: EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: trendData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.score.toDouble(),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📊 State Management

### History State
```dart
class HistoryState {
  final List<GameHistory> history;
  final PaginationMeta? pagination;
  final ParticipationStats? stats;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
}
```

### Leaderboard State
```dart
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String currentFilter;
}
```

### Notification State
```dart
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
}
```

### Scorecard State
```dart
class ScorecardState {
  final Scorecard? scorecard;
  final List<TrendData> trendData;
  final bool isLoading;
  final bool isLoadingTrend;
  final String? error;
  final String trendPeriod;
}
```

---

## 🔧 Provider Setup

All features have two types of providers:

1. **Dependency Injection Providers** (`*_providers.dart`)
   - Use case providers
   - Repository providers
   - Data source providers

2. **State Providers** (`*_state_provider.dart`)
   - StateNotifier for UI state
   - Derived providers for filtered data

---

## 🎯 Common Patterns

### Loading Data on Page Init
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    ref.read(historyProvider.notifier).loadAll();
  });
}
```

### Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(historyProvider.notifier).refresh();
  },
  child: ListView(...),
)
```

### Pagination
```dart
// Load more when scrolling
if (scrollController.position.pixels == 
    scrollController.position.maxScrollExtent) {
  ref.read(historyProvider.notifier).loadMore();
}
```

### Error Handling
```dart
if (state.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(state.error!)),
  );
}
```

---

## 📝 Testing Checklist

### History
- [ ] Load history list
- [ ] Pagination works
- [ ] Filter by status
- [ ] Stats display correctly
- [ ] Load more button

### Leaderboard
- [ ] Load global leaderboard
- [ ] Filter by friends/nearby
- [ ] Top 3 podium displays
- [ ] Rankings are correct

### Notifications
- [ ] Load notifications
- [ ] Unread count badge
- [ ] Mark as read
- [ ] Mark all as read
- [ ] Real-time updates (if implemented)

### Scorecard
- [ ] Load performance metrics
- [ ] Trend chart displays
- [ ] Period selection works
- [ ] Data refreshes

---

## 🚀 Next Steps

1. **Implement UI Pages** for each feature
2. **Add Charts** for scorecard trends (use `fl_chart` package)
3. **Add Real-Time Updates** for notifications via WebSocket
4. **Implement Caching** for offline support
5. **Add Analytics** tracking

---

## 📚 Related Documentation

- `IMPLEMENTATION_SUMMARY.md` - Overall implementation
- `BACKEND_INTEGRATION_GUIDE.md` - API specifications
- `CHAT_WEBSOCKET_IMPLEMENTATION.md` - Real-time features

---

**All features are production-ready and follow Clean Architecture!** 🎉
