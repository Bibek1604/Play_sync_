# Backend API Integration Guide

This document defines the contract between the Flutter Frontend and the Backend API. It serves as a blueprint for backend development to ensuring seamless integration with the existing frontend architecture.

## 📡 Base Configuration

*   **Base URL (Development)**: `http://localhost:5000/api/v1`
*   **Base URL (Android Emulator)**: `http://10.0.2.2:5000/api/v1`
*   **Timeout**: 30 seconds
*   **Authentication**: Bearer Token in `Authorization` header.

## 📦 Response Structure

All API responses should follow this consistent envelope structure to match the frontend's parsing logic.

### Success Response
```json
{
  "status": "success",
  "message": "Optional success message",
  "data": {
    // Actual data goes here
    "user": { ... },
    "games": [ ... ]
  }
}
```

### Error Response
```json
{
  "status": "error",
  "message": "User not found", // Frontend displays this
  "code": "USER_NOT_FOUND",  // Optional error code
  "details": "..."           // Optional technical details
}
```

---

## 🔑 1. Authentication Feature (`/auth`)

| Method | Endpoint | Description | Request Body | Response Data Key |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/register/user` | Register new user | `{ fullName, email, password, confirmPassword }` | `user`, `token` |
| `POST` | `/login` | Login user | `{ email, password }` | `user`, `token` |
| `POST` | `/logout` | Logout user | `{}` | - |
| `POST` | `/refresh-token` | Refresh Access Token | `{ refreshToken }` | `token` |
| `GET` | `/me` | Get Current User | - | `user` |

**User Model (JSON)**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "item": "John Doe",
  "role": "user", // or "admin"
  "avatar": "url/to/image.jpg"
}
```

---

## 👤 2. Profile Feature (`/profile`)

| Method | Endpoint | Description | Request Body |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Get Profile Details | - |
| `PATCH` | `/` | Update Profile | `{ fullName, phone, favouriteGame, place, ... }` |
| `POST` | `/avatar` | Upload Profile Pic | `FormData: image` |
| `POST` | `/cover` | Upload Cover Pic | `FormData: image` |
| `POST` | `/pictures` | Upload Gallery | `FormData: image[]` |

---

## 🎮 3. Game Feature (`/games`)

This is the core feature. Supports pagination via `page` and `limit` query params.

| Method | Endpoint | Description | Request Body |
| :--- | :--- | :--- | :--- |
| `POST` | `/` | Create Game | `FormData` (with image) or JSON |
| `GET` | `/` | List All Games | `?page=1&limit=20` |
| `GET` | `/:id` | Get Game Details | - |
| `PATCH` | `/:id` | Update Game | `{ title, description, ... }` |
| `DELETE` | `/:id` | Delete Game | - |
| `POST` | `/:id/join` | Join Game | - |
| `POST` | `/:id/leave` | Leave Game | - |
| `GET` | `/my/created` | My Created Games | - |
| `GET` | `/my/joined` | My Joined Games | - |
| `GET` | `/tags/popular` | Popular Tags | - |

**Game Model (JSON)**
```json
{
  "id": "uuid",
  "title": "Badminton Match",
  "description": "Friendly match",
  "tags": ["Sports", "Badminton"],
  "maxPlayers": 4,
  "currentPlayers": 2, // Count
  "participants": [ ... ], // Array of Users
  "creator": { ... }, // User object
  "status": "open", // open, in_progress, completed, cancelled
  "startTime": "ISO-8601",
  "endTime": "ISO-8601",
  "image": "url/path"
}
```

---

## 💬 4. Chat Feature (Sub-feature of Games)

Chat is scoped to a specific game.

| Method | Endpoint | Description | Request Body |
| :--- | :--- | :--- | :--- |
| `GET` | `/games/:gameId/chat` | Get Messages | `?page=1` |
| `POST` | `/games/:gameId/chat` | Send Message | `{ message: "Hello" }` |

**Chat Message Model (JSON)**
```json
{
  "id": "uuid",
  "gameId": "uuid",
  "content": "Hello world",
  "sender": { "id": "uuid", "name": "John", "avatar": "..." },
  "createdAt": "ISO-8601"
}
```

---

## 🔌 5. WebSockets (Socket.IO)

The backend must implement a Socket.IO server to support real-time updates.

**Events to Listen For (Server -> Client)**
*   `gameUpdate`: Sent when game status/details change. Payload: `Game` object.
*   `chatMessage`: Sent when a new message arrives. Payload: `ChatMessage` object.
*   `playerJoined`: Notification when someone joins.
*   `playerLeft`: Notification when someone leaves.

**Events to Emit (Client -> Server)**
*   `joinGame`: `{ gameId: "..." }` - Join the socket room for this game.
*   `leaveGame`: `{ gameId: "..." }` - Leave the socket room.

---

## 📊 6. Other Features

### History (`/history`)
*   `GET /`: List past games.
*   `GET /stats`: Win/Loss stats.

### Leaderboard (`/leaderboard`)
*   `GET /`: Global rankings.

### Notifications (`/notifications`)
*   `GET /`: List user notifications.
*   `GET /unread-count`: Number of unread items.
*   `PUT /:id/read`: Mark specific as read.
*   `PUT /read-all`: Mark all as read.

### Scorecard (`/scorecard`)
*   `GET /`: User performance metrics.
*   `GET /trend`: Performance over time graph data.
