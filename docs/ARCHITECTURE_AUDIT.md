# PlaySync Full-Stack Architecture Audit
**Date:** 2025 | **Auditor:** GitHub Copilot  
**Scope:** Backend (playsync-backend) ↔ Flutter Frontend (play_sync_new)  
**Source of Truth:** Backend

---

## Table of Contents
1. [Backend API Contract Summary](#1-backend-api-contract-summary)
2. [Model Mapping Table](#2-model-mapping-table)
3. [Endpoint Mapping Table](#3-endpoint-mapping-table)
4. [Detected Issues List](#4-detected-issues-list)
5. [Exact Refactor Instructions](#5-exact-refactor-instructions)
6. [Final Clean Architecture Proposal](#6-final-clean-architecture-proposal)
7. [Final Validation Checklist](#7-final-validation-checklist)

---

## 1. Backend API Contract Summary

All responses follow:
```json
{ "success": bool, "message": string, "data": T, "meta"?: PaginationMeta }
```

### Auth (`/api/v1/auth`)

| Endpoint | Method | Auth | Request Body | Response `data` Shape |
|---|---|---|---|---|
| `/auth/register/user` | POST | ❌ | `{ fullName, email, password, confirmPassword }` | `{ user: { id, fullName, email, role, points } }` |
| `/auth/login` | POST | ❌ | `{ email, password }` | `{ accessToken, refreshToken, user: { id, fullName, email, role, points } }` |
| `/auth/refresh-token` | POST | ❌ | `{ refreshToken }` | `{ accessToken, refreshToken, user: { id, fullName, email, role, points } }` |
| `/auth/logout` | POST | ✅ | — | `null` |
| `/auth/forgot-password` | POST | ❌ | `{ email }` | `null` |
| `/auth/reset-password` | POST | ❌ | `{ email, otp, newPassword, confirmPassword }` | `null` |

**⚠️ `/auth/me` does NOT exist. There is no current-user endpoint on the auth router.**

### Profile (`/api/v1/profile`) ← mounted from `user.routes.ts`

| Endpoint | Method | Auth | Request | Response `data` Shape |
|---|---|---|---|---|
| `/profile` | GET | ✅ | — | Full `IUser` document: `{ _id, fullName, email, role, phone, favoriteGame, place, profilePicture, points, isVerified, createdAt, updatedAt }` |
| `/profile` | PATCH | ✅ | `multipart/form-data` or JSON | Full `IUser` document |
| `/profile/change-password` | PATCH | ✅ | `{ currentPassword, newPassword, confirmNewPassword }` | `null` |
| `/profile/game-contacts` → WRONG, this is `/users/game-contacts` | — | — | — | — |

**⚠️ `game-contacts` is under `/api/v1/profile/game-contacts` (because `userRoutes` is mounted at `/profile`), NOT `/api/v1/users/game-contacts`.**

### Games (`/api/v1/games`)

| Endpoint | Method | Auth | Response `data` Shape |
|---|---|---|---|
| `GET /games` | GET | optional | `{ games: IGameDocument[], pagination: { page, limit, total, totalPages } }` |
| `POST /games` | POST | ✅ | `{ game: IGameDocument }` |
| `GET /games/my/created` | GET | ✅ | `{ games: IGameDocument[], pagination }` |
| `GET /games/my/joined` | GET | ✅ | `{ games: IGameDocument[], pagination }` |
| `GET /games/my/joined/chat-preview` | GET | ✅ | `{ previews: [{ gameId, title, imageUrl, lastMessage, lastMessageAt, unreadCount }] }` |
| `GET /games/:id` | GET | optional | `{ game: IGameDocument }` |
| `GET /games/:id/can-join` | GET | ✅ | `{ canJoin: bool, reason?: string }` |
| `POST /games/:id/join` | POST | ✅ | `{ game: { id, title, status, currentPlayers, maxPlayers, availableSlots } }` |
| `POST /games/:id/leave` | POST | ✅ | `{ game: { id, status, currentPlayers, maxPlayers, availableSlots } }` |

**`IGameDocument` exact fields:** `_id, title, description, location, tags[], imageUrl, imagePublicId, maxPlayers, minPlayers, currentPlayers, category (ONLINE|OFFLINE), status (OPEN|FULL|ENDED|CANCELLED), creatorId, participants[], bannedUsers[], startTime, endTime, endedAt, cancelledAt, completedAt, metadata, createdAt, updatedAt`

**`participants[i]` fields:** `_id, userId, joinedAt, leftAt, status (ACTIVE|LEFT), activityLogs[]`

### History (`/api/v1/history`)

| Endpoint | Method | Auth | Response `data` Shape |
|---|---|---|---|
| `GET /history` | GET | ✅ | `{ history: GameHistoryEntry[], pagination }` |
| `GET /history/stats` | GET | ✅ | `{ totalGames, activeGames, completedGames, leftEarly }` |
| `GET /history/count` | GET | ✅ | `number` (direct count) |

**⚠️ `GameHistoryEntry` exact shape (from aggregation):**
```json
{
  "gameId": "ObjectId as string",
  "title": "string",
  "category": "ONLINE | OFFLINE",
  "status": "OPEN | FULL | ENDED | CANCELLED",
  "myParticipation": {
    "joinedAt": "Date",
    "leftAt": "Date | null",
    "participationStatus": "ACTIVE | LEFT",
    "durationMinutes": "number | null"
  },
  "gameInfo": {
    "creatorName": "string",
    "maxPlayers": "number (BUG: currently null — see Issue HIST-02)",
    "currentPlayers": "number (BUG: currently null)",
    "endTime": "Date | null (BUG: currently null)",
    "imageUrl": "string | null (BUG: currently null)"
  }
}
```

### Scorecard (`/api/v1/scorecard`)

| Endpoint | Method | Auth | Response `data` Shape |
|---|---|---|---|
| `GET /scorecard` | GET | ✅ | `{ totalPoints, gamesJoined, totalMinutesPlayed, rank?, breakdown: { pointsFromJoins, pointsFromTime } }` |
| `GET /scorecard/trend` | GET | ✅ | `[{ date: "YYYY-MM-DD", points: number }]` |

### Leaderboard (`/api/v1/leaderboard`)

| Endpoint | Method | Auth | Response `data` Shape |
|---|---|---|---|
| `GET /leaderboard` | GET | ❌ | `{ leaderboard: LeaderboardEntry[], pagination }` |
| `GET /leaderboard/stats` | GET | ❌ | `{ totalPlayers: number }` |

**`LeaderboardEntry` exact shape:**
```json
{
  "rank": 1,
  "userId": {
    "_id": "ObjectId",
    "fullName": "string",
    "email": "string",
    "avatar": "string | null"
  },
  "points": "number (= totalPoints)",
  "totalPoints": "number",
  "gamesJoined": "number",
  "totalMinutes": "number"
}
```

### Notifications (`/api/v1/notifications`)

| Endpoint | Method | Auth | Response `data` Shape |
|---|---|---|---|
| `GET /notifications` | GET | ✅ | `{ notifications: INotification[], unreadCount: number, pagination }` |
| `GET /notifications/unread-count` | GET | ✅ | `{ unreadCount: number }` |
| `PATCH /notifications/:id/read` | PATCH | ✅ | `{ notification: INotification }` |
| `POST /notifications/read-all` | POST | ✅ | `null` |

**`INotification` exact fields:** `_id, user (ObjectId), type, title, message, data (mixed), read, createdAt, updatedAt`  
*No `link` field exists in database.*

---

## 2. Model Mapping Table

### User / Auth

| Backend Field | Backend Type | Flutter Field | Flutter Type | Status |
|---|---|---|---|---|
| `id` (aliased from `_id`) | `string` | `userId` | `String?` | ✅ reads `_id\|userId\|id` |
| `fullName` | `string` | `fullName` | `String?` | ⚠️ **BROKEN in login** (reads from wrong level) |
| `email` | `string` | `email` | `String` | ⚠️ **BROKEN in login** |
| `role` | `"user"\|"admin"` | `role` | `String` | ⚠️ **BROKEN in login** |
| `points` | `number` | *(not in AuthResponseModel)* | — | ⚠️ points not stored after login |
| `phone` | `string` (default `""`) | `phoneNumber` | `String?` | ✅ reads `phone\|phoneNumber` |
| `favoriteGame` | `string` (default `""`) | `favouriteGame` | `String?` | ✅ reads `favouriteGame\|favoriteGame` |
| `place` | `string` | `location` | `String?` | ✅ reads `place\|location` |
| `profilePicture` | `string` (default `""`) | `profilePicture` | `String?` | ✅ |
| `isVerified` | `boolean` | `isVerified` | `bool?` | ✅ |
| `createdAt` | `Date` | `createdAt` | `DateTime?` | ✅ |
| `updatedAt` | `Date` | `updatedAt` | `DateTime?` | ✅ |
| *(none)* | — | `bio` | `String?` | ❌ **Non-existent in backend** |
| *(none)* | — | `gamingPlatform` | `String?` | ❌ **Non-existent in backend** |
| *(none)* | — | `skillLevel` | `String?` | ❌ **Non-existent in backend** |
| *(none)* | — | `dateOfBirth` | `String?` | ❌ **Non-existent in backend** |

### Game (IGameDocument)

| Backend Field | Backend Type | Flutter Field (GameDto) | Status |
|---|---|---|---|
| `_id` | `ObjectId` | `id` reads `_id\|id` | ✅ |
| `title` | `string` | `title` reads `title\|name` | ✅ |
| `description` | `string?` | `description` | ✅ |
| `location` | `string?` | `location` | ✅ |
| `tags` | `string[]` | `tags` | ✅ |
| `imageUrl` | `string?` | `imageUrl` | ✅ |
| `imagePublicId` | `string?` | `imagePublicId` | ✅ |
| `maxPlayers` | `number` | `maxPlayers` reads `maxPlayers\|max_players` | ✅ |
| `minPlayers` | `number` | `minPlayers` reads `minPlayers\|min_players` | ✅ |
| `currentPlayers` | `number` | `currentPlayers` reads `currentPlayers\|current_players` | ✅ |
| `category` | `"ONLINE"\|"OFFLINE"` | `category` | ✅ |
| `status` | `"OPEN"\|"FULL"\|"ENDED"\|"CANCELLED"` | `status` | ✅ |
| `creatorId` | `ObjectId` | `creatorId` reads `creatorId\|creator_id\|hostId` | ✅ |
| `participants[]` | `IGameParticipant[]` | `participants` as `ParticipantDto[]` | ✅ |
| `startTime` | `Date` | `startTime` reads `startTime\|start_time\|createdAt` | ⚠️ fallback to `createdAt` is wrong |
| `endTime` | `Date` | `endTime` reads `endTime\|end_time` | ✅ |
| `endedAt` | `Date?` | `endedAt` | ✅ |
| `cancelledAt` | `Date?` | `cancelledAt` | ✅ |
| `completedAt` | `Date?` | `completedAt` | ✅ |
| `metadata` | `mixed` | `metadata` | ✅ |
| `createdAt` | `Date` | `createdAt` | ✅ |
| `updatedAt` | `Date` | `updatedAt` | ✅ |
| *(none)* | — | `latitude` | ❌ Not in backend model |
| *(none)* | — | `longitude` | ❌ Not in backend model |
| *(none)* | — | `maxDistance` | ❌ Not in backend model |

### Game History

| Backend Field (`GameHistoryEntry`) | Backend Type | Flutter Field (`GameHistoryDto`) | Status |
|---|---|---|---|
| `gameId` | `string` | `id` (reads `_id\|id`) | ❌ **STRUCTURE MISMATCH** |
| `title` | `string` | *(nested in `game.title`)* | ❌ Flutter expects nested `GameDto` |
| `category` | `"ONLINE"\|"OFFLINE"` | *(nested in `game.category`)* | ❌ |
| `status` | `string` | `status` | — only direct field that partially aligns |
| `myParticipation.joinedAt` | `Date` | `joinedAt` | ❌ Flutter reads `joinedAt` at top level — not in `myParticipation` |
| `myParticipation.leftAt` | `Date?` | `leftAt` | ❌ Same issue |
| `myParticipation.participationStatus` | `"ACTIVE"\|"LEFT"` | *(not mapped)* | ❌ |
| `myParticipation.durationMinutes` | `number?` | *(not mapped)* | ❌ |
| `gameInfo.creatorName` | `string` | *(not mapped)* | ❌ |
| `gameInfo.maxPlayers` | `number` (BUG: null) | *(nested in `game.maxPlayers`)* | ❌ |
| *(none)* | — | `userId` | ❌ Backend doesn't return `userId` |
| *(none)* | — | `pointsEarned` | ❌ Backend doesn't return `pointsEarned` |
| *(none)* | — | `leftEarly` | ❌ Backend doesn't return `leftEarly` |
| *(none)* | — | `completedAt` | ❌ Backend doesn't return `completedAt` |
| *(none)* | — | `game: GameDto` | ❌ Backend returns flat `gameInfo`, not full GameDto |

### Scorecard

| Backend Field (`ScorecardData`) | Backend Type | Flutter Field (`ScorecardDto`) | Status |
|---|---|---|---|
| `totalPoints` | `number` | `totalPoints` (nullable) | ⚠️ nullable but exists |
| *(none)* | — | `points` reads `json['points']` | ❌ **Backend sends `totalPoints` not `points`** — always 0 |
| `gamesJoined` | `number` | `gamesJoined` (nullable) | ✅ |
| `totalMinutesPlayed` | `number` | `totalMinutesPlayed` (nullable) | ✅ |
| `rank` | `number?` | `rank` | ✅ |
| `breakdown.pointsFromJoins` | `number` | `breakdown.pointsFromJoins` | ✅ |
| `breakdown.pointsFromTime` | `number` | `breakdown.pointsFromTime` | ✅ |

### Notifications

| Backend Field | Flutter Field | Status |
|---|---|---|
| `_id` | `id` reads `_id\|id` | ✅ |
| `user` (ObjectId) | `user` | ✅ |
| `type` | `type` | ✅ |
| `title` | `title` | ✅ |
| `message` | `message` | ✅ |
| `data` | `data` | ✅ |
| `read` | `read` | ✅ |
| `createdAt` | `createdAt` | ✅ |
| `updatedAt` | `updatedAt` | ✅ |
| *(none)* | `link` | ⚠️ non-existent field, always null |

### Leaderboard

| Backend Field | Flutter Field (`LeaderboardEntryDto`) | Status |
|---|---|---|
| `rank` | `rank` | ✅ |
| `userId._id` | `userId.id` | ✅ (userId is nested object) |
| `userId.fullName` | `userId.fullName` | ✅ |
| `userId.avatar` | `userId.avatar` | ✅ |
| `points` (= totalPoints) | `points` reads `points\|totalPoints` | ✅ |
| `totalPoints` | *(secondary)* | ✅ |
| `gamesJoined` | *(not used in entity)* | ⚠️ data available but ignored |
| `totalMinutes` | *(not used in entity)* | ⚠️ data available but ignored |

---

## 3. Endpoint Mapping Table

| Feature | Flutter Constant | Flutter URL | Backend Route | Mounted At | Status |
|---|---|---|---|---|---|
| Register | `registerUser` | `/auth/register/user` | `POST /register/user` | `/api/v1/auth` | ✅ |
| Login | `login` | `/auth/login` | `POST /login` | `/api/v1/auth` | ✅ |
| Logout | `logout` | `/auth/logout` | `POST /logout` | `/api/v1/auth` | ✅ |
| Refresh Token | `refreshToken` | `/auth/refresh-token` | `POST /refresh-token` | `/api/v1/auth` | ✅ |
| **Get Current User** | `getCurrentUser` | `/auth/me` | ❌ **Does not exist** | — | ❌ |
| Get Profile | `getProfile` | `/profile` | `GET /` | `/api/v1/profile` | ✅ |
| Update Profile | `updateProfile` | `/profile` (PUT) | `PATCH /` | `/api/v1/profile` | ❌ **PUT vs PATCH** |
| Upload Avatar | `uploadProfilePicture` | `/profile/avatar` | *(routes file: check)* | — | ⚠️ Verify |
| **Game Contacts** | `getGameContacts` | `/users/game-contacts` | `GET /game-contacts` | `/api/v1/profile` | ❌ Wrong path `/users/` vs `/profile/` |
| All Games | `getAllGames` | `/games` | `GET /` | `/api/v1/games` | ✅ |
| Create Game | `createGame` | `/games` (POST) | `POST /` | `/api/v1/games` | ✅ |
| Game by ID | `getGameById` | `/games/:id` | `GET /:id` | `/api/v1/games` | ✅ |
| My Created Games | `getMyCreatedGames` | `/games/my/created` | `GET /my/created` | `/api/v1/games` | ✅ |
| My Joined Games | `getMyJoinedGames` | `/games/my/joined` | `GET /my/joined` | `/api/v1/games` | ✅ |
| Join Game | `joinGame` | `/games/:id/join` | `POST /:id/join` | `/api/v1/games` | ✅ |
| Leave Game | `leaveGame` | `/games/:id/leave` | `POST /:id/leave` | `/api/v1/games` | ✅ |
| Can Join | `canJoinGame` | `/games/:id/can-join` | `GET /:id/can-join` | `/api/v1/games` | ✅ |
| Chat Preview | `getJoinedChatPreview` | `/games/my/joined/chat-preview` | `GET /my/joined/chat-preview` | `/api/v1/games` | ✅ |
| Chat Messages | `getChatMessages` | `/games/:gameId/chat` | `GET /` | `/api/v1/games/:gameId/chat` | ✅ |
| History | `historyList` | `/history` | `GET /` | `/api/v1/history` | ✅ |
| History Stats | `historyStats` | `/history/stats` | `GET /stats` | `/api/v1/history` | ✅ |
| History Count | `historyCount` | `/history/count` | `GET /count` | `/api/v1/history` | ✅ |
| Scorecard | `scorecardGet` | `/scorecard` | `GET /` | `/api/v1/scorecard` | ✅ |
| Score Trend | `scorecardTrend` | `/scorecard/trend` | `GET /trend` | `/api/v1/scorecard` | ✅ |
| Leaderboard | `leaderboardList` | `/leaderboard` | `GET /` | `/api/v1/leaderboard` | ✅ |
| Leaderboard Stats | `leaderboardStats` | `/leaderboard/stats` | `GET /stats` | `/api/v1/leaderboard` | ✅ |
| Notifications | `notificationsList` | `/notifications` | `GET /` | `/api/v1/notifications` | ✅ |
| Unread Count | `notificationsUnreadCount` | `/notifications/unread-count` | `GET /unread-count` | `/api/v1/notifications` | ✅ |
| Mark Read | `notificationsMarkRead` | `/notifications/:id/read` | `PATCH /:id/read` | `/api/v1/notifications` | ✅ |
| Read All | `notificationsReadAll` | `/notifications/read-all` | `POST /read-all` | `/api/v1/notifications` | ✅ |

---

## 4. Detected Issues List

### 🔴 CRITICAL — App-Breaking

| ID | Area | Description |
|---|---|---|
| **AUTH-01** | Flutter `AuthResponseModel` | `fromJson` reads user fields (`userId`, `fullName`, `email`, `role`) from `json['data']` which is `{ accessToken, refreshToken, user: {...} }`. The user sub-object is never drilled into. After login: stored user has `null` id, `null` name, empty email, default `user` role. Tokens work but user object is broken. |
| **HIST-01** | Flutter `GameHistoryDto` | Expected shape `{ game: GameDto, userId, joinedAt, pointsEarned, leftEarly, status }` but backend returns `{ gameId, title, category, status, myParticipation: {...}, gameInfo: {...} }`. Completely different structure — all history data shows as empty/default values. |
| **HIST-02** | Backend History Repository | `history.repository.ts` `$project` references `$maxParticipants`, `$currentParticipants`, `$date`, `$image` — none of these fields exist in Game model. Correct references: `$maxPlayers`, `$currentPlayers`, `$endTime`, `$imageUrl`. Every `gameInfo` object in history response has `null` for these 4 fields. |

### 🟠 MAJOR — Feature Broken or Data Always Wrong

| ID | Area | Description |
|---|---|---|
| **SCORE-01** | Flutter `ScorecardDto` | `points: json['points'] ?? 0` — backend never sends a field named `points` in scorecard (it sends `totalPoints`). The primary score always displays 0. `totalPoints` is correctly read into a nullable field but `toEntity()` uses `points` (0) not `totalPoints`. |
| **PROFILE-01** | Flutter Profile Datasource | `_apiClient.put(ApiEndpoints.updateProfile)` uses HTTP `PUT` but backend `user.routes.ts` has `router.patch('/')`. Update profile always returns 404/405. |
| **ENDPOINT-02** | Flutter `ApiEndpoints` | `getGameContacts = '/users/game-contacts'` but backend mounts `userRoutes` at `/api/v1/profile`. Correct path is `/profile/game-contacts`. This means the game contacts endpoint always returns 404. |

### 🟡 MODERATE — Missing Data / Degraded Functionality

| ID | Area | Description |
|---|---|---|
| **PROFILE-02** | Flutter + Backend | `ProfileResponseModel` maps `bio`, `gamingPlatform`, `skillLevel`, `dateOfBirth` — none of these fields exist in backend `IUser` model. Profile page always shows empty for these. Either add fields to backend or remove from Flutter. |
| **ENDPOINT-01** | Flutter `ApiEndpoints` | `getCurrentUser = '/auth/me'` — this endpoint does not exist in backend. Auth routes don't have an `/me` endpoint. Need to either add it to auth routes or remove this constant and use `/profile` instead. |
| **GAME-01** | Flutter `GameDto` | `latitude`, `longitude`, `maxDistance` fields read from JSON but never returned by backend (not in Game model). These are always null — offline geo-fencing features are silently non-functional. |
| **GAME-02** | Flutter `GameDto` | `startTime` fallback: `json['startTime'] ?? json['start_time'] ?? json['createdAt']` — when `startTime` is missing (which shouldn't happen but can with corrupted data), falls back to `createdAt`. This is a logic error — games would appear to start when they were created. |

### 🟢 MINOR — Non-Breaking but Should Be Fixed

| ID | Area | Description |
|---|---|---|
| **NOTIF-01** | Flutter `NotificationDto` | `link` field always null since backend model has no `link` property. Non-breaking but clutters the model. |
| **SCORE-02** | Flutter `LeaderboardEntryDto` | `gamesJoined` and `totalMinutes` are returned by backend but never mapped to `LeaderboardEntry` entity. Available data is thrown away. |
| **CHAT-01** | Flutter Chat Feature | Chat has no domain/data architectural layer — only presentation providers. `chat_page.dart` calls providers directly. Inconsistent with rest of codebase's clean architecture. |
| **IMPORT-01** | Flutter Game Datasource | `game_remote_datasource.dart` imports `game_history_dto.dart` from the `game` feature but the DTO lives in the `history` feature. Conceptually wrong import location. |

---

## 5. Exact Refactor Instructions

### FIX AUTH-01: `auth_response_model.dart`

**File:** `play_sync_new/lib/features/auth/data/models/auth_response_model.dart`

**Problem:** When `json['data']` exists, `userData = json['data']` = `{ accessToken, refreshToken, user: {...} }`. User fields are never extracted from `userData['user']`.

**Fix:** Add `user` sub-object extraction when `userData` contains a `user` key:
```dart
factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
  Map<String, dynamic> envelopeData;
  if (json.containsKey('data') && json['data'] is Map) {
    envelopeData = json['data'] as Map<String, dynamic>;
  } else {
    envelopeData = json;
  }

  // Drill into user sub-object if envelope has one (login/refresh pattern)
  final Map<String, dynamic> userData;
  if (envelopeData.containsKey('user') && envelopeData['user'] is Map) {
    userData = envelopeData['user'] as Map<String, dynamic>;
  } else if (json.containsKey('user') && json['user'] is Map) {
    userData = json['user'] as Map<String, dynamic>;
  } else {
    userData = envelopeData;
  }

  // Token extraction from envelope level
  final token = envelopeData['accessToken'] ??
                envelopeData['token'] ??
                json['accessToken'] ??
                json['token'];

  final refreshToken = envelopeData['refreshToken'] ??
                       envelopeData['refresh_token'] ??
                       json['refreshToken'] ??
                       json['refresh_token'];

  return AuthResponseModel(
    userId: userData['id']?.toString() ?? userData['_id']?.toString() ?? userData['userId']?.toString(),
    fullName: userData['fullName'] ?? userData['full_name'] ?? userData['name'],
    email: userData['email'] ?? json['email'] ?? '',
    role: userData['role'] ?? json['role'] ?? 'user',
    token: token,
    refreshToken: refreshToken,
    message: json['message'],
    createdAt: userData['createdAt'] != null
        ? DateTime.tryParse(userData['createdAt'].toString())
        : null,
    isVerified: userData['isVerified'] ?? false,
  );
}
```

---

### FIX HIST-02: `history.repository.ts`

**File:** `playsync-backend/src/modules/history/history.repository.ts`

**Problem:** `$project` stage in aggregation pipeline uses wrong field names for `gameInfo`.

**Fix the `$project` stage:**
```typescript
gameInfo: {
  creatorName: { $ifNull: ['$creator.fullName', 'Unknown'] },
  maxPlayers: '$maxPlayers',       // was: '$maxParticipants'
  currentPlayers: '$currentPlayers', // was: '$currentParticipants'
  endTime: '$endTime',             // was: '$date'
  imageUrl: '$imageUrl',           // was: '$image'
},
```

---

### FIX HIST-01: `game_history_dto.dart`

**File:** `play_sync_new/lib/features/history/data/models/game_history_dto.dart`

**Problem:** Entire DTO structure does not match backend `GameHistoryEntry` shape. Backend returns flat structure with `myParticipation` and `gameInfo` objects, not a nested `GameDto`.

**Replace the DTO entirely:**
```dart
class GameHistoryDto {
  final String gameId;
  final String title;
  final String category;
  final String status;
  final ParticipationDetailsDto myParticipation;
  final GameInfoDto gameInfo;

  GameHistoryDto({
    required this.gameId,
    required this.title,
    required this.category,
    required this.status,
    required this.myParticipation,
    required this.gameInfo,
  });

  factory GameHistoryDto.fromJson(Map<String, dynamic> json) {
    return GameHistoryDto(
      gameId: json['gameId']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'ONLINE',
      status: json['status'] ?? 'OPEN',
      myParticipation: ParticipationDetailsDto.fromJson(
          json['myParticipation'] as Map<String, dynamic>? ?? {}),
      gameInfo: GameInfoDto.fromJson(
          json['gameInfo'] as Map<String, dynamic>? ?? {}),
    );
  }

  GameHistory toEntity() {
    return GameHistory(
      id: gameId,
      gameId: gameId,
      title: title,
      category: category,
      status: status,
      joinedAt: myParticipation.joinedAt,
      leftAt: myParticipation.leftAt,
      participationStatus: myParticipation.participationStatus,
      durationMinutes: myParticipation.durationMinutes,
      creatorName: gameInfo.creatorName,
      maxPlayers: gameInfo.maxPlayers,
      currentPlayers: gameInfo.currentPlayers,
      endTime: gameInfo.endTime,
      imageUrl: gameInfo.imageUrl,
    );
  }
}

class ParticipationDetailsDto {
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String participationStatus;
  final double? durationMinutes;

  ParticipationDetailsDto({
    required this.joinedAt,
    this.leftAt,
    required this.participationStatus,
    this.durationMinutes,
  });

  factory ParticipationDetailsDto.fromJson(Map<String, dynamic> json) {
    return ParticipationDetailsDto(
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      leftAt: json['leftAt'] != null ? DateTime.tryParse(json['leftAt'].toString()) : null,
      participationStatus: json['participationStatus'] ?? 'ACTIVE',
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
    );
  }
}

class GameInfoDto {
  final String creatorName;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime? endTime;
  final String? imageUrl;

  GameInfoDto({
    required this.creatorName,
    required this.maxPlayers,
    required this.currentPlayers,
    this.endTime,
    this.imageUrl,
  });

  factory GameInfoDto.fromJson(Map<String, dynamic> json) {
    return GameInfoDto(
      creatorName: json['creatorName'] ?? 'Unknown',
      maxPlayers: json['maxPlayers'] ?? 0,
      currentPlayers: json['currentPlayers'] ?? 0,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
```

> **Note:** Also update `GameHistory` entity and `GameHistoryRepository`/`GameHistoryProvider` to use the new fields.

---

### FIX SCORE-01: `scorecard_dto.dart`

**File:** `play_sync_new/lib/features/scorecard/data/models/scorecard_dto.dart`

**Problem:** `points: json['points'] ?? 0` — backend sends `totalPoints`, not `points`. The entity always gets 0.

**Fix `fromJson` and `toEntity`:**
```dart
factory ScorecardDto.fromJson(Map<String, dynamic> json) {
  final totalPoints = json['totalPoints'] ?? json['total_points'] ?? json['points'] ?? 0;
  return ScorecardDto(
    userId: json['userId'] ?? json['user_id'],
    points: totalPoints,          // ← now reads totalPoints as primary
    totalPoints: totalPoints,     // ← redundant but kept for backward compatibility
    rank: json['rank'] ?? 0,
    gamesJoined: json['gamesJoined'] ?? json['games_joined'],
    gamesPlayed: json['gamesPlayed'] ?? json['games_played'],
    totalMinutesPlayed: json['totalMinutesPlayed'] ?? json['total_minutes_played'],
    updatedAt: json['updatedAt'] ?? json['updated_at'],
    breakdown: json['breakdown'] != null
        ? BreakdownDto.fromJson(json['breakdown'])
        : null,
  );
}
```

---

### FIX PROFILE-01: `profile_remote_datasource.dart`

**File:** `play_sync_new/lib/features/profile/data/datasources/remote/profile_remote_datasource.dart`

**Problem:** `_apiClient.put(...)` but backend has `PATCH /api/v1/profile`.

**Fix:** Change `put` to `patch`:
```dart
response = await _apiClient.patch(
  ApiEndpoints.updateProfile,
  data: formData,
);
// and the JSON variant:
response = await _apiClient.patch(
  ApiEndpoints.updateProfile,
  data: profileData,
);
```

---

### FIX ENDPOINT-02: `api_endpoints.dart`

**File:** `play_sync_new/lib/core/api/api_endpoints.dart`

**Problem:** `getGameContacts = '/users/game-contacts'` — backend mounts userRoutes at `/api/v1/profile`, not `/api/v1/users`.

**Fix:**
```dart
static const String getGameContacts = '/profile/game-contacts';
```

**Also add `/auth/me` as an alias (since Flutter references it):**
Either add the route to backend auth routes OR redirect to profile. See Fix ENDPOINT-01 below.

---

### FIX ENDPOINT-01: Add `/auth/me` to backend

**File:** `playsync-backend/src/modules/auth/auth.routes.ts`

**Add to auth routes (after existing routes):**
```typescript
router.get(
  "/me",
  auth,
  asyncHandler(async (req, res) => {
    const user = await UserService.getProfile((req as any).user.id);
    res.status(200).json({
      success: true,
      message: "Current user retrieved",
      data: user,
    });
  })
);
```
*Or alternatively: remove `getCurrentUser` from `ApiEndpoints` if it's never called.*

---

### FIX PROFILE-02: Add missing profile fields to User model

**File:** `playsync-backend/src/modules/auth/auth.model.ts`

Add to `IUser` interface and schema:
```typescript
// EXTENDED PROFILE FIELDS
bio?: string;
dateOfBirth?: string;
gamingPlatform?: string;
skillLevel?: string;
```

Schema additions:
```typescript
bio: { type: String, trim: true, maxlength: [500, 'Bio too long'], default: '' },
dateOfBirth: { type: String, default: '' },
gamingPlatform: { type: String, trim: true, default: '' },
skillLevel: { type: String, enum: ['beginner', 'intermediate', 'advanced', 'pro', ''], default: '' },
```

---

## 6. Final Clean Architecture Proposal

### Chat Feature — Add Domain/Data Layer

Current state: Chat is presentation-only. Recommended structure (align with all other features):
```
lib/features/chat/
  domain/
    entities/chat_message.dart      (already exists as game feature entity)
    repositories/chat_repository.dart
    usecases/get_chat_messages.dart
    usecases/send_chat_message.dart
  data/
    models/chat_message_dto.dart    (move from game/data/models/)
    datasources/chat_remote_datasource.dart  (extract HTTP calls here)
    repositories/chat_repository_impl.dart
  presentation/
    pages/chat_page.dart            (existing)
    providers/                      (existing)
```

### History Feature — Update Entity

The `GameHistory` entity must match new `GameHistoryDto`. Suggested entity fields:
```dart
class GameHistory {
  final String id;              // = gameId
  final String gameId;
  final String title;
  final String category;
  final String status;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String participationStatus;
  final double? durationMinutes;
  final String creatorName;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime? endTime;
  final String? imageUrl;
}
```

### Scorecard Entity Cleanup

Remove the redundant `points` field from `Scorecard` entity — use only `totalPoints`. Update all UI references from `scorecard.points` to `scorecard.totalPoints`.

### Leaderboard Entity — Add Missing Fields

Add `gamesJoined` and `totalMinutes` to `LeaderboardEntry`:
```dart
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int points;
  final int rank;
  final int gamesJoined;    // ← add
  final int totalMinutes;   // ← add
}
```

---

## 7. Final Validation Checklist

After applying all fixes, verify the following end-to-end flows:

### Auth Flow
- [ ] `POST /auth/login` → `AuthResponseModel.fromJson` → `userId`, `fullName`, `email`, `role` are all non-null  
- [ ] `POST /auth/refresh-token` → same model → tokens and user refreshed correctly
- [ ] `POST /auth/register/user` → model parses user from `data.user` (no tokens expected)
- [ ] Stored user in Riverpod state has correct non-null `userId` after login

### Profile Flow
- [ ] `GET /api/v1/profile` → profile page shows `fullName`, `email`, `phone`, `favoriteGame`, `place`, `profilePicture`
- [ ] `PATCH /api/v1/profile` (confirm Flutter now sends PATCH) → profile updates persist
- [ ] `GET /api/v1/profile/game-contacts` (confirm Flutter uses `/profile/game-contacts`) → returns co-players

### Game Flow
- [ ] `GET /games` → games list displays with correct title, imageUrl, maxPlayers, currentPlayers
- [ ] `POST /games/:id/join` → join response `data.game.id` is non-null
- [ ] `GET /games/my/joined/chat-preview` → previews array with `gameId`, `lastMessage`, `unreadCount`

### Scorecard Flow
- [ ] `GET /scorecard` → `ScorecardDto.points` now equals `totalPoints` (non-zero if user has played games)
- [ ] Dashboard rank card shows correct score

### History Flow
- [ ] `GET /history` → `HistoryListResultDto` parses `history` array correctly
- [ ] Each entry has `gameId`, `title`, `category`, `status`, `myParticipation.joinedAt`, `gameInfo.creatorName`
- [ ] `gameInfo.maxPlayers`, `gameInfo.currentPlayers`, `gameInfo.endTime`, `gameInfo.imageUrl` are non-null (after HIST-02 fix)
- [ ] History page UI displays game title and participation status

### Leaderboard Flow  
- [ ] `GET /leaderboard` → `LeaderboardEntryDto.userId` is a parsed `UserDto` with non-empty `id` and `fullName`
- [ ] Ranks display correctly in order

### Notifications Flow
- [ ] `GET /notifications` → notifications parse correctly, `read` status respected
- [ ] `GET /notifications/unread-count` → badge count is accurate
- [ ] `PATCH /notifications/:id/read` → notification marked as read

---

*End of Audit — Generated by comprehensive 5-phase analysis of playsync-backend and play_sync_new codebases.*
