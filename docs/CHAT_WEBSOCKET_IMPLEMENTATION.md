# Chat & WebSocket Implementation Guide

This document explains how the Chat feature and WebSocket integration work in the PlaySync application.

## 🏗️ Architecture Overview

The Chat feature follows Clean Architecture with real-time updates via Socket.IO:

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌──────────────┐    ┌──────────────┐   ┌────────────┐ │
│  │ ChatProvider │───▶│ ChatNotifier │◀──│ ChatPanel  │ │
│  └──────────────┘    └──────────────┘   └────────────┘ │
│         │                    │                           │
└─────────┼────────────────────┼───────────────────────────┘
          │                    │
          ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│                    Domain Layer                          │
│  ┌──────────────────┐    ┌──────────────────────────┐  │
│  │ GetChatMessages  │    │  SendChatMessage         │  │
│  │    UseCase       │    │     UseCase              │  │
│  └──────────────────┘    └──────────────────────────┘  │
│         │                           │                    │
│         └───────────┬───────────────┘                    │
│                     ▼                                    │
│         ┌──────────────────────┐                        │
│         │  GameRepository      │                        │
│         └──────────────────────┘                        │
└─────────────────────┼───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────────────────┐    ┌──────────────────────┐  │
│  │ GameRemoteDataSource │    │ ChatLocalDataSource  │  │
│  └──────────────────────┘    └──────────────────────┘  │
│         │                                                │
│         ├──────────────┬──────────────┐                 │
│         ▼              ▼              ▼                 │
│    ┌────────┐    ┌──────────┐   ┌────────┐            │
│    │  HTTP  │    │  Socket  │   │  Hive  │            │
│    │  (Dio) │    │  (IO)    │   │ Cache  │            │
│    └────────┘    └──────────┘   └────────┘            │
└─────────────────────────────────────────────────────────┘
```

## 📡 WebSocket Service

### Socket Service (`core/services/socket_service.dart`)

The `SocketService` is a singleton that manages the Socket.IO connection:

**Key Features:**
- **Singleton Pattern**: One connection per app instance
- **Auto-Reconnect**: Handles disconnections gracefully
- **Token Management**: Updates auth token on refresh
- **Event Handling**: Subscribe/emit events easily

**Usage Example:**
```dart
// Get socket instance with auth token
final socket = socketService.getSocket(token: authToken);

// Emit an event
socketService.emit('joinGame', {'gameId': '123'});

// Listen to events
socketService.on('chatMessage', (data) {
  print('New message: $data');
});

// Remove listener
socketService.off('chatMessage');
```

### Socket Events

#### Client → Server (Emit)
| Event | Payload | Description |
|-------|---------|-------------|
| `joinGame` | `{ gameId: "..." }` | Join a game room |
| `leaveGame` | `{ gameId: "..." }` | Leave a game room |

#### Server → Client (Listen)
| Event | Payload | Description |
|-------|---------|-------------|
| `gameUpdate` | `Game` object | Game state changed |
| `chatMessage` | `ChatMessage` object | New chat message |
| `playerJoined` | `{ userId, name }` | Player joined game |
| `playerLeft` | `{ userId, name }` | Player left game |

## 💬 Chat Feature Implementation

### 1. Domain Layer

**Entity: `ChatMessage`**
```dart
class ChatMessage {
  final String id;
  final String gameId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type; // user or system
  final String? senderAvatar;
}
```

**UseCases:**
- `GetChatMessages`: Fetch message history
- `SendChatMessage`: Send a new message

### 2. Data Layer

**Remote DataSource:**
```dart
// GET /games/:gameId/chat
Future<List<ChatMessageDto>> getChatMessages(String gameId);

// POST /games/:gameId/chat
Future<ChatMessageDto> sendChatMessage(String gameId, String message);
```

**Local DataSource:**
- Caches messages in Hive for offline access
- Stores messages per game ID

### 3. Presentation Layer

**ChatProvider (`chat_provider.dart`)**

The `ChatProvider` is a family provider that manages chat state per game:

```dart
// Watch chat for a specific game
final chatState = ref.watch(chatProvider(gameId));

// Send a message
ref.read(chatProvider(gameId).notifier).sendMessage('Hello!');
```

**State Management:**
```dart
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
}
```

**ChatNotifier Lifecycle:**
1. **Initialization**: 
   - Loads message history from API
   - Joins game room via Socket.IO
   - Subscribes to `chatMessage` events

2. **Real-time Updates**:
   - Listens for incoming messages via socket
   - Automatically adds new messages to state
   - No manual refresh needed

3. **Disposal**:
   - Leaves game room
   - Unsubscribes from socket events
   - Cleans up resources

### 4. UI Component

**ChatPanel Widget:**
```dart
ChatPanel(
  messages: chatState.messages,
  controller: _messageController,
  onSendMessage: () {
    ref.read(chatProvider(gameId).notifier)
       .sendMessage(_messageController.text);
    _messageController.clear();
  },
  isSending: chatState.isSending,
)
```

## 🔄 Real-Time Flow Example

### Scenario: User sends a message

1. **User types message** → UI calls `sendMessage()`
2. **ChatNotifier** → Calls `SendChatMessage` UseCase
3. **UseCase** → Calls Repository
4. **Repository** → Calls Remote DataSource
5. **Remote DataSource** → POST to `/games/:gameId/chat`
6. **Backend** → Saves message & broadcasts via Socket.IO
7. **Socket.IO** → Emits `chatMessage` event to all clients in room
8. **ChatNotifier** → Receives event via `_onNewMessage()`
9. **State Update** → New message added to `messages` list
10. **UI** → Automatically rebuilds with new message

### Message Deduplication

The sender receives their message twice:
1. From the HTTP response (immediate feedback)
2. From the socket broadcast (real-time)

**Solution**: Check message ID before adding to prevent duplicates (optional enhancement).

## 🎯 Usage in Your App

### Step 1: Initialize Socket Connection

In your app initialization (e.g., after login):

```dart
// Get auth token
final token = await secureStorage.read(key: 'access_token');

// Initialize socket
socketService.getSocket(token: token);
```

### Step 2: Use Chat in a Game Screen

```dart
class GameChatScreen extends ConsumerWidget {
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(gameId));
    final messageController = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          ChatInput(
            controller: messageController,
            onSend: () {
              ref.read(chatProvider(gameId).notifier)
                 .sendMessage(messageController.text);
              messageController.clear();
            },
            isSending: chatState.isSending,
          ),
        ],
      ),
    );
  }
}
```

### Step 3: Clean Up on Logout

```dart
void logout() {
  socketService.disconnectSocket();
  // ... other logout logic
}
```

## 🐛 Debugging Tips

**Check Socket Connection:**
```dart
print('Socket connected: ${socketService.isConnected}');
print('Socket ID: ${socketService.socketId}');
```

**Monitor Socket Events:**
The `SocketService` logs all events to console:
- `[SOCKET] 🔌 Creating new socket connection`
- `[SOCKET] ✅ Connected: abc123`
- `[SOCKET] 📤 Emitting: joinGame`
- `[SOCKET] ❌ Connection error: ...`

**Common Issues:**
1. **Messages not appearing**: Check if socket is connected
2. **Duplicate messages**: Implement message ID deduplication
3. **Connection drops**: Check network and backend availability

## 🚀 Future Enhancements

- [ ] Message read receipts
- [ ] Typing indicators
- [ ] Message reactions/emojis
- [ ] File/image sharing
- [ ] Message search
- [ ] Offline message queue
