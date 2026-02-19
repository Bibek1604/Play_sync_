# PlaySync Flutter — Bugs, Inconsistencies & Hardcoded Data Audit

> Audited: February 19, 2026  
> Scope: `lib/` directory — all features

This document lists every identified problem grouped by category. Each entry includes the exact file + line, what the problem is, and what the fix should be.

---

## Table of Contents

1. [Hardcoded Data That Must Come from Backend](#1-hardcoded-data-that-must-come-from-backend)
2. [Inconsistent Data Loading Problems](#2-inconsistent-data-loading-problems)
3. [UI Shows Wrong / Static State](#3-ui-shows-wrong--static-state)
4. [Missing Features / Stub Implementations](#4-missing-features--stub-implementations)
5. [Data Loading in Wrong Lifecycle Place](#5-data-loading-in-wrong-lifecycle-place)
6. [Pagination Not Implemented](#6-pagination-not-implemented)
7. [Summary Table](#7-summary-table)

---

## 1. Hardcoded Data That Must Come from Backend

---

### BUG-01 — Notification badge count is hardcoded `'5'`

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L112)

**Problem:**
```dart
child: const Text(
  '5',    // ← hardcoded, never changes
  ...
```
The AppBar notification bell shows `'5'` at all times. It is a `const` — it never reads any real state.

**What it should be:**
```dart
// Watch the real provider:
final notifState = ref.watch(notificationProvider);
...
child: Text('${notifState.unreadCount}')
```
`notificationProvider` already has `unreadCount` tracked from the backend. That value should replace `'5'`.

---

### BUG-02 — Notification banner is completely disconnected from real data

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L1160)

**Problem:**
`_NotificationBanner` is a plain `StatelessWidget`. It always renders:
- A red dot on the bell icon
- "You have new notifications"
- "Tap to see invites, game updates & more"

There is no check. Even when the user has 0 unread notifications, the banner still shows as if something is pending.

**What it should be:**
- The banner should be conditionally rendered: only show when `notifState.unreadCount > 0`.
- The message should include the count: *"You have 3 new notifications"*.
- `_NotificationBanner` should be a `ConsumerWidget` watching `notificationProvider`.

---

### BUG-03 — Friends list in Chat is entirely hardcoded

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L308)

**Problem:**
```dart
// Mock friends data
final friends = [
  {'name': 'John Doe', 'status': 'Playing CS:GO', 'online': true},
  {'name': 'Sarah Wilson', 'status': 'Available', 'online': true},
  {'name': 'Mike Chen', 'status': 'Last seen 2h ago', 'online': false},
  {'name': 'Alex Johnson', 'status': 'Away', 'online': false},
];
```
These 4 fake users (`John Doe`, `Sarah Wilson`, `Mike Chen`, `Alex Johnson`) are always displayed. No real users from the backend ever appear in the Friends tab.

**What it should be:**
The Friends tab needs a backend endpoint (e.g., `/friends` or `/users/following`) to fetch the real friend list. A `FriendsNotifier` / provider should be created and `_FriendsTab` should be a `ConsumerWidget` watching it.

---

### BUG-04 — Groups list in Chat is entirely hardcoded

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L340)

**Problem:**
```dart
// Mock groups data
final groups = [
  {'name': 'Team Alpha', 'members': 8, 'lastActive': '5m ago'},
  {'name': 'CS:GO Squad', 'members': 12, 'lastActive': '1h ago'},
  {'name': 'Weekend Warriors', 'members': 5, 'lastActive': '2h ago'},
];
```
Three fake groups are always shown. The `if (groups.isEmpty)` check below can never be `true` because the list is always populated with static data.

**What it should be:**
Groups should come from the backend. Until a backend endpoint exists, this whole tab should show an "empty / coming soon" state — not fake static data that confuses users.

---

### BUG-05 — Chat item last-message and timestamp are hardcoded placeholders

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L277)

**Problem:**
```dart
// We don't have last message info yet, showing generic info
return _ChatItem(
  name: game.title,
  message: 'Tap to view chat',   // ← hardcoded
  time: '',                       // ← hardcoded empty
  unread: 0,                      // ← hardcoded 0 (never shows badge)
  online: true,                   // ← hardcoded always online
  ...
```
Every game chat entry shows identical placeholder text. Users cannot see last message previews, unread counts, or timestamps.

**What it should be:**
The backend (or a local Hive cache of the last socket message) should provide:
- `lastMessage: String` — last message content
- `lastMessageAt: DateTime`
- `unreadCount: int` — messages since user last opened this chat

The `ChatMessage` entity and `ChatLocalDataSource` already exist but are not used here.

---

### BUG-06 — "Online" presence indicator in WelcomeCard is always hardcoded

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L567)

**Problem:**
```dart
const Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.circle, color: Color(0xFF69F0AE), size: 10),
    SizedBox(width: 6),
    Text('Online', ...),     // ← always shows "Online"
  ],
)
```
The green dot + "Online" text is a `const` widget — it never reflects actual socket connection state. Even when the socket is disconnected or the user is offline, it still says "Online".

**What it should be:**
Watch `SocketService.instance.state` or a `socketStateProvider` derived from `SocketService.stateStream`. Show `'Online'` only when `SocketState.connected`, otherwise `'Offline'` or `'Connecting...'`.

---

## 2. Inconsistent Data Loading Problems

---

### BUG-07 — `loadGames()` triggered from 3 different places independently

**Problem:**
The same API call (`GET /games`) is triggered from:

| Location | How |
|---|---|
| [dashboard_page.dart L31](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L31) | `Future.microtask(() { ref.read(gameListProvider.notifier).loadGames(); })` inside `build()` |
| [available_games_page.dart L34](../lib/features/game/presentation/pages/available_games_page.dart#L34) | `Future.microtask(() { ref.read(gameListProvider.notifier).loadGames(); })` in `initState` |
| [game_lobby_screen.dart L28](../lib/features/game/presentation/screens/game_lobby_screen.dart#L28) | `Future.microtask(() => ref.read(gameListProvider.notifier).loadGames())` in `initState` |

All three share the same `gameListProvider` state (Riverpod keeps a single instance), so the last one to resolve wins. If two pages are alive simultaneously, redundant HTTP requests fire.

**What it should be:**
Load games once — in `initState` of the first page that needs them, or use a `ref.listen` / `autoDispose` strategy. `DashboardPage` should not trigger `loadGames()` from inside `build()`.

---

### BUG-08 — `loadJoinedGames()` called independently from both Dashboard and Chat

**Problem:**
| Location | Source |
|---|---|
| [dashboard_page.dart L915](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L915) | `_MyJoinedGamesSectionState.initState()` |
| [chat_page.dart L30](../lib/features/chat/presentation/pages/chat_page.dart#L30) | `ChatPage.initState()` |

Both call `ref.read(joinedGamesProvider.notifier).loadJoinedGames()` when the page opens. Since the provider is shared, when Chat opens it overwrites dashboard data with a fresh (possibly different) response mid-flight.

**What it should be:**
Load once at app startup (e.g., after authentication) and refresh on `RefreshIndicator`. Don't trigger duplicate loads in `initState` of every page.

---

### BUG-09 — `offlineGamesProvider` has two separate, conflicting definitions

**Problem:**
`gameListProvider` (in [game_list_provider.dart](../lib/features/game/presentation/providers/game_list_provider.dart#L153)):
```dart
final offlineGamesProvider = Provider<List<Game>>((ref) {
  return ref.watch(gameListProvider).games.where((g) => g.isOffline).toList();
});
```
This is a **computed** provider — a filtered view of the single game list.

But `OfflineGamesPage` (in [offline_games_page.dart](../lib/features/game/presentation/pages/offline_games_page.dart)) watches a **different** provider `offlineGamesProvider` from `offline_game_provider.dart` which has its **own separate state and its own API call** (`GET /games/nearby`).

There are now TWO providers both named `offlineGamesProvider` in different files. The `dashboard_page.dart` watch of `offlineGamesProvider` resolves to the computed one; `OfflineGamesPage` resolves to the other. This means:
- The offline count on dashboard subtitle does not reflect what OfflineGamesPage shows.
- Users could see "3 local games" on dashboard but a different list in OfflineGamesPage.

**What it should be:**
Have a single `offlineGamesProvider` that all pages use. Use `GetGamesNearby` for the offline list and remove the computed filter from `gameListProvider`.

---

### BUG-10 — Profile data loaded in 3 separate places without coordination

**Problem:**
Profile is fetched by calling `getProfile()` from:

| Location |
|---|
| [dashboard_page.dart L34](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L34) — inside `build()` |
| [app_drawer.dart L32](../lib/core/widgets/app_drawer.dart#L32) — inside `build()` |
| [profile_page.dart L22](../lib/features/profile/presentation/pages/profile_page.dart#L22) — `initState` |
| [edit_profile_page.dart L34](../lib/features/profile/presentation/pages/edit_profile_page.dart#L34) — `initState` |

The drawer opens frequently. Each time its `build()` runs, it conditionally calls `getProfile()` via `microtask`, firing a new request whenever the profile is null or been cleared.

**What it should be:**
Load profile once at login. `AppDrawer` should only `watch` `profileNotifierProvider` — not trigger loads itself. A single profile load at the app level (after auth) to prime the provider is sufficient.

---

### BUG-11 — Scorecard loaded in 2 places inside `build()` methods

**Problem:**
`AppDrawer.build()` ([app_drawer.dart L36](../lib/core/widgets/app_drawer.dart#L36)) and `DashboardPage.build()` ([dashboard_page.dart L32](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L32)) both call:
```dart
Future.microtask(() => ref.read(scorecardProvider.notifier).loadScorecard());
```
Both are called every time those widgets rebuild. Since `DashboardPage` rebuilds whenever `scorecardProvider` changes (causing a rebuild → microtask → load → state change → rebuild loop), this can create repeated unnecessary API calls.

**What it should be:**
Load scorecard once in `DashboardPage.initState()` (change to `ConsumerStatefulWidget`) and never load inside `build()`.

---

## 3. UI Shows Wrong / Static State

---

### BUG-12 — `OfflineGamesPage` background ignores dark mode

**File:** [features/game/presentation/pages/offline_games_page.dart](../lib/features/game/presentation/pages/offline_games_page.dart#L67)

**Problem:**
```dart
backgroundColor: AppColors.backgroundSecondaryLight,  // ← always light
```
Unlike every other page (`OnlineGamesPage`, `RankingsPage`, `DashboardPage`) which checks `isDark`, this page is always on a light background regardless of the user's theme setting.

**What it should be:**
```dart
backgroundColor: isDark ? AppColors.backgroundPrimaryDark : AppColors.backgroundSecondaryLight,
```

---

### BUG-13 — `scorecard?.rank` can display `#null`

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L319)

**Problem:**
```dart
value: '#${scorecard?.rank ?? '-'}',
```
If `scorecard` is not null but `scorecard.rank` is `null` (because the API returned a scorecard without a rank field), this renders as `#null` on screen.

**What it should be:**
```dart
value: scorecard?.rank != null ? '#${scorecard!.rank}' : '-',
```

---

### BUG-14 — `_ChatsTab` always shows `unread: 0` — unread badge never appears

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L279)

**Problem:**
```dart
unread: 0,  // ← hardcoded; the red unread badge never shows
```
Users cannot see how many unread messages are in each game chat because the count is always zero.

**What it should be:**
The backend should return a `GET /games/chats/unread-counts` endpoint, or the socket layer should maintain per-game unread counts locally in a dedicated provider. That count should be passed in.

---

## 4. Missing Features / Stub Implementations

---

### BUG-15 — Search dialog in ChatPage does nothing

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L155)

**Problem:**
```dart
onPressed: () {
  Navigator.pop(context);
  // Perform search    ← only a comment, no implementation
},
```
The search button shows a dialog and closes it, but performs no actual search. The search query typed by the user is completely ignored.

---

### BUG-16 — "New Chat" FAB shows dialog with placeholder text but no action

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L170)

**Problem:**
```dart
content: const Text('Select a friend to start chatting'),
// No friend list rendered inside the dialog
```
The dialog contains only a static string and a Cancel button. No friend list, no user search, no action.

---

### BUG-17 — `Groups` tab always renders static data and never shows empty state

**File:** [features/chat/presentation/pages/chat_page.dart](../lib/features/chat/presentation/pages/chat_page.dart#L340)

**Problem:**
```dart
final groups = [
  {'name': 'Team Alpha', 'members': 8, 'lastActive': '5m ago'},
  ...
];

if (groups.isEmpty) {   // This is always false because of the above
  return Center(child: ...empty state...);
}
```
The empty state UI is dead code — it can never be reached.

---

### BUG-18 — Dashboard `_MyJoinedGamesSection` silently hides all errors

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L997)

**Problem:**
```dart
if (joinedGamesState.error != null && joinedGamesState.games.isEmpty) {
  return const SizedBox.shrink(); // Hide section on error
}
```
If the API call for joined games fails, the entire section silently disappears. Users see no feedback — no error message, no retry button. They may think they have no games rather than knowing there was a network error.

---

## 5. Data Loading in Wrong Lifecycle Place

---

### BUG-19 — `DashboardPage` is `ConsumerWidget` but loads data inside `build()`

**File:** [features/dashboard/presentation/pages/dashboard_page.dart](../lib/features/dashboard/presentation/pages/dashboard_page.dart#L31)

**Problem:**
```dart
// inside build():
Future.microtask(() {
  ref.read(gameListProvider.notifier).loadGames();
  ref.read(scorecardProvider.notifier).loadScorecard();
  if (profileState.profile == null && !profileState.isLoading) {
    ref.read(profileNotifierProvider.notifier).getProfile();
  }
});
```
`build()` is called on every state change. Even though `Future.microtask` defers execution, this can schedule multiple loads whenever any watched provider changes. Since `gameListProvider`, `scorecardProvider`, and `profileNotifierProvider` are all watched on this page, and loading them changes their state, which triggers a rebuild, which schedules another microtask — this is a subtle re-fetch loop risk.

**What it should be:**
Convert `DashboardPage` from `ConsumerWidget` to `ConsumerStatefulWidget` and move all data loading into `initState()`:
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    ref.read(gameListProvider.notifier).loadGames();
    ref.read(scorecardProvider.notifier).loadScorecard();
    ref.read(profileNotifierProvider.notifier).getProfile();
  });
}
```

---

### BUG-20 — `AppDrawer` triggers data fetches on every `build()` call

**File:** [lib/core/widgets/app_drawer.dart](../lib/core/widgets/app_drawer.dart#L32)

**Problem:**
```dart
// Inside build():
if (profileState.profile == null && !profileState.isLoading) {
  Future.microtask(() => ref.read(profileNotifierProvider.notifier).getProfile());
}
if (scorecardState.scorecard == null && !scorecardState.isLoading) {
  Future.microtask(() => ref.read(scorecardProvider.notifier).loadScorecard());
}
```
The drawer rebuilds whenever theme, auth, scorecard, or profile state changes. Each time the condition is temporarily met, a new fetch is queued. This is fragile and can result in multiple overlapping requests.

**What it should be:**
The drawer should be a pure read-only view. Data loading responsibilities belong in the page that uses the drawer (`initState`) or in a dedicated app-level initialization step after login.

---

## 6. Pagination Not Implemented

---

### BUG-21 — Game lists always load only page 1 (limit 20)

**File:** [features/game/data/datasources/game_remote_datasource.dart](../lib/features/game/data/datasources/game_remote_datasource.dart#L21)

**Problem:**
```dart
Future<List<GameDto>> getAvailableGames({int page = 1, int limit = 20}) async {
```
The `page` and `limit` parameters exist but the UI never changes them. `GameListNotifier.loadGames()` always calls with defaults:
```dart
final games = await _getAvailableGames(); // always page=1, limit=20
```
If the backend has more than 20 games, users will never see them.

**Affected use cases:**
- `GetAvailableGames`
- `GetMyJoinedGames`
- `GetMyCreatedGames`

**What it should be:**
Implement "load more" / infinite scroll in `AvailableGamesPage`, `OnlineGamesPage`, and `OfflineGamesPage`. The notifiers need `page` tracking and an `loadMore()` method.

---

## 7. Summary Table

| ID | Severity | File | Problem |
|---|---|---|---|
| BUG-01 | High | `dashboard_page.dart:112` | Notification badge count hardcoded as `'5'` |
| BUG-02 | High | `dashboard_page.dart:1160` | Notification banner always shows — not connected to real unread count |
| BUG-03 | High | `chat_page.dart:308` | Friends list is 4 hardcoded fake users |
| BUG-04 | High | `chat_page.dart:340` | Groups list is 3 hardcoded fake groups |
| BUG-05 | High | `chat_page.dart:277` | Chat last-message, timestamp, unread count hardcoded as placeholders |
| BUG-06 | Medium | `dashboard_page.dart:567` | "Online" presence badge is `const` — never reflects real socket state |
| BUG-07 | Medium | 3 files | `loadGames()` triggered from `build()` + 2 `initState`s independently |
| BUG-08 | Medium | `dashboard_page.dart` + `chat_page.dart` | `loadJoinedGames()` called independently from two separate pages |
| BUG-09 | High | `game_list_provider.dart` + `offline_game_provider.dart` | Two conflicting `offlineGamesProvider` definitions → dashboard count ≠ page content |
| BUG-10 | Medium | 4 files | Profile loaded from 3 different places including inside `build()` |
| BUG-11 | Medium | `dashboard_page.dart` + `app_drawer.dart` | Scorecard loaded inside `build()` in 2 widgets — re-fetch loop risk |
| BUG-12 | Low | `offline_games_page.dart:67` | Background color ignores dark mode — always light |
| BUG-13 | Low | `dashboard_page.dart:319` | `#${scorecard?.rank ?? '-'}` can render as `#null` |
| BUG-14 | Medium | `chat_page.dart:279` | Unread chat badge `unread: 0` hardcoded — badge never appears |
| BUG-15 | Low | `chat_page.dart:155` | Chat search dialog does nothing — no implementation |
| BUG-16 | Low | `chat_page.dart:170` | "New Chat" dialog has no action — only a Cancel button |
| BUG-17 | Low | `chat_page.dart:340` | Groups empty-state is unreachable dead code |
| BUG-18 | Medium | `dashboard_page.dart:997` | Joined games API error silently hides section with no user feedback |
| BUG-19 | High | `dashboard_page.dart:31` | Data loading inside `build()` on a `ConsumerWidget` — potential re-fetch loop |
| BUG-20 | Medium | `app_drawer.dart:32` | Drawer fetches data inside every `build()` call |
| BUG-21 | Medium | `game_remote_datasource.dart:21` | Pagination exists but never used — only first 20 games ever load |

---

## Recommended Fix Priority

1. **Immediate** (break real functionality): BUG-01, BUG-03, BUG-04, BUG-05, BUG-09, BUG-19
2. **High** (misleads users): BUG-02, BUG-06, BUG-07, BUG-08, BUG-10, BUG-11
3. **Medium** (degrades UX): BUG-14, BUG-18, BUG-20, BUG-21
4. **Low** (polish): BUG-12, BUG-13, BUG-15, BUG-16, BUG-17
