# PlaySync Flutter — Implementation Documentation

> **App:** PlaySync  
> **Framework:** Flutter (Dart SDK ^3.10.3)  
> **Architecture:** Clean Architecture (Domain / Data / Presentation)  
> **State Management:** Riverpod (flutter_riverpod ^2.5.1)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Entry Point & App Bootstrap](#3-entry-point--app-bootstrap)
4. [Core Layer](#4-core-layer)
5. [Feature — Auth](#5-feature--auth)
6. [Feature — Dashboard](#6-feature--dashboard)
7. [Feature — Game](#7-feature--game)
8. [Feature — Chat](#8-feature--chat)
9. [Feature — Profile](#9-feature--profile)
10. [Feature — Leaderboard](#10-feature--leaderboard)
11. [Feature — Notifications](#11-feature--notifications)
12. [Feature — History](#12-feature--history)
13. [Feature — Scorecard](#13-feature--scorecard)
14. [Feature — Location](#14-feature--location)
15. [Feature — Settings](#15-feature--settings)
16. [Navigation & Routing](#16-navigation--routing)
17. [Key Packages](#17-key-packages)

---

## 1. Project Overview

PlaySync is a social gaming coordination app that lets users:

- Browse, create, join, and manage **online and offline games**
- Chat in real-time inside game lobbies (Socket.IO)
- View personal **scorecards**, **game history**, and global **leaderboards**
- Manage their **profile** with avatar / cover / gallery pictures
- Receive in-app **notifications**
- Discover nearby offline games using **location** services

---

## 2. Architecture

Every feature follows **Clean Architecture** with three layers:

```
feature/
├── domain/          ← pure Dart, no Flutter/framework deps
│   ├── entities/    ← core business objects (immutable)
│   ├── repositories/← abstract interfaces (contracts)
│   └── usecases/    ← single-responsibility business actions
│
├── data/            ← implements domain contracts
│   ├── models/      ← DTOs (JSON ↔ Hive serialization)
│   ├── datasources/ ← remote (Dio/Socket) + local (Hive)
│   └── repositories/← concrete repo implementations
│
└── presentation/    ← Flutter UI
    ├── pages/       ← full-screen routes
    ├── screens/     ← alternative screen layouts
    ├── providers/   ← Riverpod providers & StateNotifiers
    ├── state/       ← immutable state classes
    ├── view_model/  ← optional ViewModel layer
    └── widgets/     ← reusable UI components
```

**Error handling** uses `dartz` `Either<Failure, T>` — every use case returns `Right(data)` on success or `Left(Failure)` on error.

---

## 3. Entry Point & App Bootstrap

**File:** `lib/main.dart`

```
main()
  └─ HiveInit.initialize()   ← registers all Hive adapters, opens boxes
  └─ runApp(ProviderScope(child: PlaySyncApp()))
```

**File:** `lib/app/app.dart` — `PlaySyncApp` (ConsumerWidget)

- Watches `themeModeProvider` to apply light/dark theme.
- Uses `MaterialApp` with `AppRouter.generateRoute` for named routing.
- Theme defined in `lib/app/theme/` with full `AppTheme.lightTheme` and `AppTheme.darkTheme`.

---

## 4. Core Layer

Located in `lib/core/`.

### 4.1 API Client — `core/api/api_client.dart`

- Wraps **Dio** with base options (timeouts: 30 s).
- Injects `Authorization: Bearer <token>` via an interceptor reading from `SecureStorageProvider`.
- Auto-refreshes token on 401 responses.

### 4.2 API Endpoints — `core/api/api_endpoints.dart`

Centralized constants for every backend route:

| Group | Endpoints |
|---|---|
| Auth | `/auth/register/user`, `/auth/login`, `/auth/logout`, `/auth/refresh-token`, `/auth/me` |
| Profile | `/profile`, `/profile/avatar`, `/profile/cover`, `/profile/pictures` |
| Games | `/games`, `/games/:id`, `/games/:id/join`, `/games/:id/leave`, ... |
| Leaderboard | `/leaderboard` |
| Notifications | `/notifications` |
| History | `/history` |
| Scorecard | `/scorecard` |

Base URL automatically resolves:
- Android emulator → `http://10.0.2.2:5000/api/v1`
- Web / other → `http://localhost:5000/api/v1`

### 4.3 Socket Service — `core/services/socket_service.dart`

- **Singleton** (`SocketService.instance`) backed by `socket_io_client`.
- `getSocket({required String token})` — creates or reuses the connection.
- Re-connects automatically when token changes or socket drops.
- Exposes `Stream<SocketState>` (`connected` / `connecting` / `disconnected`).

### 4.4 Connectivity Service — `core/services/connectivity_service.dart`

- Uses `connectivity_plus` to detect online/offline state.
- Used by repositories to decide remote-first vs cache-first data fetching.

### 4.5 Sound Manager — `core/services/sound_manager.dart`

- Uses `audioplayers` to play short sound effects (joins, messages, etc.).
- Loaded from `assets/sounds/`.

### 4.6 Hive Database — `core/database/hive_init.dart`

Opens the following boxes on startup:

| Box name | Stores |
|---|---|
| `games` | `GameDto` objects |
| `game_metadata` | game list metadata (timestamps) |
| `chat_metadata` | chat pagination metadata |
| `game_history` | `GameHistoryDto` |
| `leaderboard` | `LeaderboardEntryDto` |
| `notifications` | `NotificationDto` |
| `profile` | `ProfileResponseModel` |
| `scorecard` | `ScorecardDto` |

---

## 5. Feature — Auth

**Path:** `lib/features/auth/`

### What is implemented

| Layer | File | Responsibility |
|---|---|---|
| Domain entity | `domain/entities/auth_entity.dart` | User fields: `userId`, `fullName`, `email`, `role (user/admin)`, `token`, `refreshToken` |
| Use cases | `login_usecase.dart` | Calls repo `login()`, returns `Either<Failure, AuthEntity>` |
| Use cases | `register_usecase.dart` | Calls repo `register()` |
| Presentation state | `AuthState` (in auth_notifier) | `initial / loading / authenticated / unauthenticated / error` |
| Presentation | `AuthNotifier` | `StateNotifier<AuthState>` — calls use cases, caches token to secure storage |
| UI — Splash | `presentation/pages/splash_page.dart` | Checks cached token → redirects to dashboard or login |
| UI — Login | `presentation/pages/login_page.dart` | Email + password form |
| UI — Register/Signup | `register_page.dart`, `signup_page.dart` | Full registration form |

### How it works

```
SplashPage
  └─ AuthNotifier._init()
       └─ repository.isLoggedIn()
            ├─ YES → emit authenticated → navigate /dashboard
            └─ NO  → emit unauthenticated → navigate /login

LoginPage → user submits form
  └─ AuthNotifier.login(email, password)
       └─ LoginUsecase.call()
            └─ AuthRepositoryImpl.login()
                 └─ remote datasource POST /auth/login
                      └─ store token in FlutterSecureStorage
                           └─ emit AuthStatus.authenticated
```

Token is persisted in **FlutterSecureStorage** — survives app restart.

---

## 6. Feature — Dashboard

**Path:** `lib/features/dashboard/`

### What is implemented

- `dashboard.dart` — exports presentation layer.
- `presentation/` contains the main shell page that hosts the bottom navigation linking to games, leaderboard, notifications, and profile.
- Uses `themeModeProvider` from `lib/app/theme/` for dark/light toggle.

> Domain and Data layers are planned for future implementation (currently marked as stubs in the barrel file comments).

---

## 7. Feature — Game

**Path:** `lib/features/game/`  
This is the **most complete** feature.

### Domain Entities

| Entity | Key fields |
|---|---|
| `Game` | `id, title, description, location, tags, maxPlayers, minPlayers, currentPlayers, category (online/offline), status (open/started/ended/cancelled), creatorId, participants, startTime, endTime, latitude, longitude, maxDistance` |
| `Player` | Participant info |
| `ChatMessage` | Message inside a game lobby |
| `GameHistory` | Past game record for a user |

Computed properties on `Game`: `isFull`, `isOpen`, `hasEnded`, `availableSlots`, `isOnline`, `isOffline`.

### Use Cases (14 total)

| Use Case | Action |
|---|---|
| `GetAvailableGames` | List public open games |
| `GetMyJoinedGames` | Games current user joined |
| `GetMyCreatedGames` | Games current user created |
| `GetGamesNearby` | Offline games within radius |
| `GetGameById` | Single game detail |
| `GetGameHistory` | Past games for current user |
| `GetPopularTags` | Tag suggestions for game creation |
| `GetChatMessages` | Paginated chat history for a game |
| `CreateGame` | Create a new game |
| `JoinGame` | Join an existing game |
| `LeaveGame` | Leave a game |
| `UpdateGame` | Edit game details (creator only) |
| `DeleteGame` | Remove game (creator only) |
| `SendChatMessage` | Post a message in lobby chat |

### Data Layer

- **Remote datasource** (`GameRemoteDataSource`) — Dio for REST, `SocketService` for real-time events.
- **Local datasource** (`GameLocalDataSource`) — Hive `Box<GameDto>` for offline-first caching.
- **Chat local datasource** (`ChatLocalDataSource`) — Hive cache for messages.
- **Repository** (`GameRepositoryImpl`) — tries remote first, falls back to local cache on failure.

### Presentation

| Screen / Widget | Purpose |
|---|---|
| `AvailableGamesPage` | Browse all joinable games |
| `OnlineGamesPage` | Filter: online-only games |
| `OfflinePage` | Filter: nearby physical games |
| `GameChatPage` | Real-time lobby chat screen |
| `GameLobbyScreen` | Player list + chat panel combined |
| `GameHubScreen` | Top-level game navigation hub |
| `GameCard` | Summary card widget used in lists |
| `OfflineGameCard` | Card variant showing distance |
| `CreateGameDialog` | Modal to create a new game |
| `PlayerListPanel` | Lists joined players with avatars |
| `ChatPanel` | In-lobby message thread widget |

### How real-time works

```
GameRemoteDataSource
  └─ SocketService.getSocket(token)
       └─ socket.on('game:playerJoined')  → update participant list
       └─ socket.on('game:message')       → append to chat
       └─ socket.on('game:statusChanged') → update game status
       └─ socket.emit('game:join', gameId)
       └─ socket.emit('game:message', {gameId, content})
```

Riverpod providers wire everything together through `gameRepositoryProvider` → `gameListProvider` / `currentGameProvider`.

---

## 8. Feature — Chat

**Path:** `lib/features/chat/`

### What is implemented

- `presentation/pages/` hosts dedicated chat screens per game context.
- Game-specific in-lobby chat is handled by the `ChatPanel` widget inside the Game feature.
- Real-time messaging powered by `SocketService` (see Game feature §7).

---

## 9. Feature — Profile

**Path:** `lib/features/profile/`

### What is implemented

| Layer | Details |
|---|---|
| Domain | `ProfileEntity` with user fields, avatar, cover, gallery |
| Use cases | Get profile, update profile, upload avatar, upload cover, upload gallery |
| Data | `ProfileResponseModel` (Hive-cached), remote datasource (Dio multipart for images) |
| UI — Profile Page | Displays avatar, cover photo, bio, stats |
| UI — Edit Profile Page | Form to edit name, bio, social links |

### How it works

- **Avatar / Cover / Gallery** uploads use Dio `FormData` with `image_picker` to capture images.
- Profile is cached in Hive box `profile` so it loads instantly offline.
- `ProfileViewModel` (StateNotifier) manages loading / submitting states.

---

## 10. Feature — Leaderboard

**Path:** `lib/features/leaderboard/`

### What is implemented

| Layer | Details |
|---|---|
| Domain | `LeaderboardEntry` (rank, userId, username, points, wins, gamesPlayed), `LeaderboardStats` |
| Use cases | `GetLeaderboard` — paginated global rankings, `GetLeaderboardStats` — summary stats |
| Data | `LeaderboardEntryDto` (Hive adapter registered), remote datasource |
| UI — Rankings Page | Sorted list with rank badges, user avatars, and point scores |

### How it works

```
RankingsPage
  └─ watches leaderboardProvider
       └─ GetLeaderboard.call()
            └─ LeaderboardRepositoryImpl
                 └─ remote: GET /leaderboard
                 └─ local:  Hive cache fallback
```

---

## 11. Feature — Notifications

**Path:** `lib/features/notifications/`

### What is implemented

| Layer | Details |
|---|---|
| Domain | `NotificationEntity` (id, title, body, type, isRead, createdAt) |
| Use cases | `GetNotifications`, `MarkAsRead`, `MarkAllAsRead` |
| Data | `NotificationDto` (Hive cached), remote datasource |
| UI — Notifications Page | List with unread badge, swipe-to-read, mark-all button |

---

## 12. Feature — History

**Path:** `lib/features/history/`

### What is implemented

| Layer | Details |
|---|---|
| Domain | `GameHistory` (game record), `ParticipationStats` (aggregated counts) |
| Use cases | `GetMyHistory`, `GetStats`, `GetCount` |
| Data | `GameHistoryDto` + `ParticipationStatsDto` (Hive cached), remote datasource |
| Presentation | `history_providers.dart`, `history_notifier.dart` (StateNotifier) |

---

## 13. Feature — Scorecard

**Path:** `lib/features/scorecard/`

### What is implemented

| Layer | Details |
|---|---|
| Domain | `Scorecard` (total points, wins, losses, winRate, breakdown by game type), `PointsTrend` |
| Use cases | `GetMyScorecard`, `GetTrend` |
| Data | `ScorecardDto` + `PointsTrendDto` (Hive cached), remote datasource |
| Presentation | Providers & UI to show streaks and points graph |

---

## 14. Feature — Location

**Path:** `lib/features/location/`

### What is implemented

- `presentation/providers/` contains location providers that expose current latitude/longitude.
- Used by `GetGamesNearby` use case to filter offline games by `maxDistance` (km).
- Distance calculation uses the **Haversine formula** implemented inside `Game` entity.

---

## 15. Feature — Settings

**Path:** `lib/features/settings/`

### What is implemented

- `presentation/pages/` — settings screen (theme toggle, account options).
- Theme mode (`light` / `dark` / `system`) persisted via `shared_preferences` through `themeModeProvider`.
- Domain and Data layers are planned stubs (not yet required).

---

## 16. Navigation & Routing

**Files:** `lib/app/routes/`

All routes are named strings defined in `AppRoutes`:

| Route | Screen |
|---|---|
| `/` | SplashPage |
| `/login` | LoginPage |
| `/signup` | SignupPage |
| `/dashboard` | DashboardPage |
| `/profile` | ProfilePage |
| `/available-games` | AvailableGamesPage |
| `/online-games` | OnlineGamesPage |
| `/offline-games` | OfflineGamesPage |
| `/game-history` | GameHistoryPage |
| `/chat` | ChatPage |
| `/notifications` | NotificationsPage |
| `/rankings` | RankingsPage |
| `/settings` | SettingsPage |
| `/game-detail` | GameDetailPage |

`AppRouter.generateRoute` handles route construction. Auth guard redirect (unauthenticated → `/login`) is managed inside `AuthNotifier._init()` on startup.

---

## 17. Key Packages

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management (Provider, StateNotifier) |
| `dio` | ^5.3.3 | HTTP client with interceptors |
| `socket_io_client` | ^2.0.3+1 | Real-time WebSocket (Socket.IO) |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | Local NoSQL database (offline caching) |
| `flutter_secure_storage` | ^9.0.0 | Secure JWT token storage |
| `dartz` | ^0.10.1 | Functional `Either<Failure, T>` error handling |
| `equatable` | ^2.0.5 | Value equality for entities |
| `connectivity_plus` | ^5.0.2 | Network connectivity detection |
| `image_picker` | ^1.0.7 | Camera / gallery image selection |
| `audioplayers` | ^5.2.1 | Sound effects playback |
| `shared_preferences` | ^2.2.2 | Theme mode persistence |
| `shimmer` | ^3.0.0 | Loading skeleton animations |
| `flutter_svg` | ^2.0.10 | SVG asset rendering |
| `uuid` | ^4.2.1 | UUID generation for local IDs |
