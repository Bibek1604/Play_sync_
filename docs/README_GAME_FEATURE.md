# 🎮 PlaySync - Game Feature Implementation

Complete implementation of the Game feature with real-time chat and WebSocket support following Clean Architecture principles.

## 📚 Documentation Index

### Getting Started
1. **[Implementation Summary](IMPLEMENTATION_SUMMARY.md)** - Overview of all implemented features
2. **[Chat Quick Start](CHAT_QUICK_START.md)** - Quick guide to using chat features
3. **[Testing Checklist](TESTING_CHECKLIST.md)** - Comprehensive testing guide

### Technical Documentation
4. **[Backend Integration Guide](BACKEND_INTEGRATION_GUIDE.md)** - API specifications and endpoints
5. **[Chat & WebSocket Implementation](CHAT_WEBSOCKET_IMPLEMENTATION.md)** - Real-time features guide
6. **[Architecture Diagrams](ARCHITECTURE_DIAGRAMS.md)** - Visual system architecture
7. **[Authentication & Profile Flow](AUTHENTICATION_PROFILE_FLOW.md)** - Auth implementation

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Backend URL
Edit `lib/core/api/api_endpoints.dart`:
```dart
static const String baseUrl = 'http://your-backend-url/api/v1';
```

### 3. Initialize Socket on Login
```dart
// After successful login
final token = await secureStorage.read(key: 'access_token');
socketService.getSocket(token: token);
```

### 4. Use Chat in Your Screen
```dart
class GameScreen extends ConsumerWidget {
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(gameId));
    
    return ChatPanel(
      messages: chatState.messages,
      controller: _controller,
      onSendMessage: () {
        ref.read(chatProvider(gameId).notifier)
           .sendMessage(_controller.text);
      },
      isSending: chatState.isSending,
    );
  }
}
```

---

## ✨ Features Implemented

### Game Management
- ✅ Create, Read, Update, Delete games
- ✅ Join and leave games
- ✅ Filter by Online/Offline
- ✅ View game history
- ✅ Popular tags
- ✅ Nearby games (location-based)

### Real-Time Chat
- ✅ Send and receive messages
- ✅ Message history
- ✅ System messages
- ✅ Real-time updates via Socket.IO
- ✅ Auto-join/leave game rooms

### WebSocket Events
- ✅ `joinGame` / `leaveGame`
- ✅ `chatMessage` - New messages
- ✅ `gameUpdate` - Game state changes
- ✅ `playerJoined` / `playerLeft` - Player notifications

### Dashboard Integration
- ✅ Display online game count
- ✅ Display offline game count
- ✅ Show user's joined games
- ✅ Real-time updates

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  • Providers (Riverpod)                 │
│  • UI Widgets                           │
│  • State Management                     │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│          Domain Layer                   │
│  • Entities (Game, ChatMessage)         │
│  • Use Cases                            │
│  • Repository Interfaces                │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│           Data Layer                    │
│  • Repository Implementations           │
│  • Remote Data Source (API)             │
│  • Local Data Source (Hive)             │
│  • DTOs                                 │
└─────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   └── api_endpoints.dart         # API & Socket event constants
│   └── services/
│       └── socket_service.dart        # Socket.IO singleton service
│
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       └── pages/
│   │           └── dashboard_page.dart
│   │
│   └── game/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── game.dart
│       │   │   ├── chat_message.dart
│       │   │   └── game_history.dart
│       │   ├── repositories/
│       │   │   └── game_repository.dart
│       │   └── usecases/
│       │       ├── get_available_games.dart
│       │       ├── get_my_created_games.dart
│       │       ├── get_chat_messages.dart
│       │       ├── send_chat_message.dart
│       │       └── ... (12 total use cases)
│       │
│       ├── data/
│       │   ├── repositories/
│       │   │   └── game_repository_impl.dart
│       │   ├── datasources/
│       │   │   ├── game_remote_datasource.dart
│       │   │   └── game_local_datasource.dart
│       │   └── models/
│       │       └── game_dto.dart
│       │
│       └── presentation/
│           ├── providers/
│           │   ├── game_providers.dart          # Use case providers
│           │   ├── game_list_provider.dart      # Game list state
│           │   ├── chat_provider.dart           # Chat with sockets ✨
│           │   └── game_realtime_provider.dart  # Real-time updates ✨
│           ├── pages/
│           │   └── game_chat_page.dart          # Example chat page
│           └── widgets/
│               ├── chat_panel.dart
│               ├── game_card.dart
│               └── ...
│
└── docs/
    ├── IMPLEMENTATION_SUMMARY.md
    ├── CHAT_QUICK_START.md
    ├── CHAT_WEBSOCKET_IMPLEMENTATION.md
    ├── ARCHITECTURE_DIAGRAMS.md
    ├── TESTING_CHECKLIST.md
    ├── BACKEND_INTEGRATION_GUIDE.md
    └── README_GAME_FEATURE.md (this file)
```

---

## 🎯 API Endpoints

### Games
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/games` | Get all games |
| GET | `/games/my-games` | Get joined games |
| GET | `/games/my-created-games` | Get created games |
| GET | `/games/nearby` | Get nearby games |
| GET | `/games/popular-tags` | Get popular tags |
| GET | `/games/:id` | Get game by ID |
| POST | `/games` | Create game |
| PUT | `/games/:id` | Update game |
| DELETE | `/games/:id` | Delete game |
| POST | `/games/:id/join` | Join game |
| POST | `/games/:id/leave` | Leave game |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/games/:gameId/chat` | Get messages |
| POST | `/games/:gameId/chat` | Send message |

### WebSocket Events
| Event | Direction | Description |
|-------|-----------|-------------|
| `joinGame` | Client → Server | Join game room |
| `leaveGame` | Client → Server | Leave game room |
| `chatMessage` | Server → Client | New chat message |
| `gameUpdate` | Server → Client | Game state changed |
| `playerJoined` | Server → Client | Player joined |
| `playerLeft` | Server → Client | Player left |

---

## 🔧 Configuration

### 1. Backend URL
```dart
// lib/core/api/api_endpoints.dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```

### 2. Socket Connection
```dart
// Initialize after login
final token = await secureStorage.read(key: 'access_token');
socketService.getSocket(token: token);

// Disconnect on logout
socketService.disconnectSocket();
```

### 3. Hive Initialization
```dart
// Already handled in app initialization
await Hive.initFlutter();
await Hive.openBox<GameDto>('games');
await Hive.openBox('game_metadata');
await Hive.openBox('chat_metadata');
```

---

## 🧪 Testing

See **[TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)** for comprehensive testing guide.

### Quick Test
1. Start backend server
2. Run app: `flutter run`
3. Login
4. Create a game
5. Open chat
6. Send message
7. Open app in another device/browser
8. Join same game
9. Verify real-time message delivery

---

## 🐛 Debugging

### Check Socket Connection
```dart
print('Socket connected: ${socketService.isConnected}');
print('Socket ID: ${socketService.socketId}');
```

### Monitor Events
All socket events are logged to console:
- `[SOCKET] 🔌 Creating new socket connection`
- `[SOCKET] ✅ Connected: abc123`
- `[SOCKET] 📤 Emitting: joinGame`
- `[SOCKET] ❌ Connection error: ...`

### Common Issues

**Messages not appearing?**
- Check socket connection status
- Verify backend is broadcasting events
- Check console for errors

**Duplicate messages?**
- Implement message ID deduplication
- Check if multiple providers are listening

**Connection drops?**
- Check network stability
- Verify backend is running
- Check token expiration

---

## 📊 Performance

### Optimizations Implemented
- ✅ Hive caching for offline support
- ✅ Auto-dispose providers when not in use
- ✅ Efficient state updates (copyWith)
- ✅ Socket connection reuse
- ✅ Background cache refresh

### Best Practices
- Use `select` to watch specific state fields
- Limit message history (pagination)
- Debounce typing indicators
- Optimize list rendering

---

## 🚀 Deployment

### Production Checklist
- [ ] Update backend URL to production
- [ ] Disable debug logs
- [ ] Test on real devices
- [ ] Verify socket connection
- [ ] Test with multiple users
- [ ] Check error handling
- [ ] Verify offline mode
- [ ] Test reconnection

### Build Commands
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📝 Next Steps

### Recommended Enhancements
1. **Message Pagination** - Load older messages on scroll
2. **Typing Indicators** - Show when someone is typing
3. **Read Receipts** - Track message read status
4. **Push Notifications** - Notify users of new messages
5. **File Sharing** - Upload images/files in chat
6. **Message Search** - Search chat history
7. **Offline Queue** - Queue messages when offline

### Optional Features
- Game invitations
- Friend system
- Game recommendations
- Advanced filters
- Game statistics
- Leaderboards

---

## 🤝 Contributing

### Code Style
- Follow Clean Architecture principles
- Use meaningful variable names
- Document complex logic
- Write unit tests for use cases

### Pull Request Process
1. Create feature branch
2. Implement feature
3. Add tests
4. Update documentation
5. Submit PR

---

## 📄 License

[Your License Here]

---

## 👥 Team

[Your Team Information]

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for state management
- Socket.IO for real-time features
- Hive for local storage

---

## 📞 Support

For issues or questions:
- Check documentation first
- Review testing checklist
- Check console logs
- Create GitHub issue

---

**Happy Coding! 🎮🚀**
