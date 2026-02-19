# Quick Start: Using Chat & Real-Time Features

This guide shows you how to quickly integrate chat and real-time updates into your game screens.

## 🚀 Quick Integration

### Step 1: Add Chat to Your Game Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/game/presentation/providers/chat_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/chat_panel.dart';

class YourGameScreen extends ConsumerStatefulWidget {
  final String gameId;
  
  const YourGameScreen({required this.gameId});

  @override
  ConsumerState<YourGameScreen> createState() => _YourGameScreenState();
}

class _YourGameScreenState extends ConsumerState<YourGameScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch chat state
    final chatState = ref.watch(chatProvider(widget.gameId));

    return Scaffold(
      body: Column(
        children: [
          // Your game content here
          Expanded(
            child: YourGameContent(),
          ),
          
          // Chat panel
          SizedBox(
            height: 300,
            child: ChatPanel(
              messages: chatState.messages,
              controller: _messageController,
              onSendMessage: () {
                final message = _messageController.text.trim();
                if (message.isNotEmpty) {
                  ref.read(chatProvider(widget.gameId).notifier)
                     .sendMessage(message);
                  _messageController.clear();
                }
              },
              isSending: chatState.isSending,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 2: Add Real-Time Game Updates

```dart
import 'package:play_sync_new/features/game/presentation/providers/game_realtime_provider.dart';

class YourGameScreen extends ConsumerWidget {
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real-time game state
    final gameState = ref.watch(gameRealtimeProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: Text(gameState.game?.name ?? 'Game'),
        subtitle: Text('${gameState.game?.currentPlayers ?? 0} players'),
      ),
      body: Column(
        children: [
          // Show notifications
          if (gameState.recentNotifications.isNotEmpty)
            NotificationBanner(
              message: gameState.recentNotifications.first,
              onDismiss: () {
                ref.read(gameRealtimeProvider(gameId).notifier)
                   .clearNotifications();
              },
            ),
          
          // Your game content
          Expanded(child: YourGameContent()),
        ],
      ),
    );
  }
}
```

## 📱 Complete Example: Game Room Screen

Here's a complete example combining everything:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/game/presentation/providers/chat_provider.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_realtime_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/chat_panel.dart';

class GameRoomScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameRoomScreen({required this.gameId});

  @override
  ConsumerState<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends ConsumerState<GameRoomScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.gameId));
    final gameState = ref.watch(gameRealtimeProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gameState.game?.name ?? 'Loading...'),
            if (gameState.game != null)
              Text(
                '${gameState.game!.currentPlayers}/${gameState.game!.maxPlayers} players',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left side: Game content
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Notifications
                if (gameState.recentNotifications.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.blue.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(gameState.recentNotifications.first),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            ref.read(gameRealtimeProvider(widget.gameId).notifier)
                               .clearNotifications();
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Game content
                Expanded(
                  child: Center(
                    child: Text('Your game content here'),
                  ),
                ),
              ],
            ),
          ),
          
          // Right side: Chat
          SizedBox(
            width: 350,
            child: ChatPanel(
              messages: chatState.messages,
              controller: _messageController,
              onSendMessage: _sendMessage,
              isSending: chatState.isSending,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref.read(chatProvider(widget.gameId).notifier).sendMessage(message);
    _messageController.clear();
  }
}
```

## 🎨 Customizing the Chat Panel

### Custom Message Bubble

```dart
// Create your own chat widget
class CustomChatView extends ConsumerWidget {
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(gameId));

    return ListView.builder(
      reverse: true,
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return CustomMessageBubble(message: message);
      },
    );
  }
}
```

### Custom Send Button

```dart
ElevatedButton(
  onPressed: chatState.isSending ? null : () {
    ref.read(chatProvider(gameId).notifier)
       .sendMessage(_controller.text);
    _controller.clear();
  },
  child: chatState.isSending 
      ? CircularProgressIndicator()
      : Text('Send'),
)
```

## 🔔 Handling Notifications

### Show Snackbar on Player Join/Leave

```dart
class GameScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameRealtimeProvider(widget.gameId));

    // Listen to notifications
    ref.listen(gameRealtimeProvider(widget.gameId), (previous, next) {
      if (next.recentNotifications.isNotEmpty && 
          (previous?.recentNotifications.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.recentNotifications.first)),
        );
      }
    });

    return Scaffold(
      // Your UI
    );
  }
}
```

## 🎯 Common Patterns

### 1. Chat in Bottom Sheet

```dart
void showChatBottomSheet(BuildContext context, String gameId) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider(gameId));
        return SizedBox(
          height: 500,
          child: ChatPanel(
            messages: chatState.messages,
            controller: TextEditingController(),
            onSendMessage: () {
              // Send logic
            },
            isSending: chatState.isSending,
          ),
        );
      },
    ),
  );
}
```

### 2. Chat in Tab View

```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      bottom: TabBar(
        tabs: [
          Tab(text: 'Game'),
          Tab(text: 'Chat'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        GameView(),
        Consumer(
          builder: (context, ref, child) {
            final chatState = ref.watch(chatProvider(gameId));
            return ChatPanel(
              messages: chatState.messages,
              controller: _controller,
              onSendMessage: _sendMessage,
              isSending: chatState.isSending,
            );
          },
        ),
      ],
    ),
  ),
)
```

### 3. Floating Chat Button

```dart
Scaffold(
  floatingActionButton: FloatingActionButton(
    onPressed: () => showChatBottomSheet(context, gameId),
    child: Badge(
      label: Text('${chatState.messages.length}'),
      child: Icon(Icons.chat),
    ),
  ),
  body: YourGameContent(),
)
```

## 🔍 Debugging

### Check Socket Connection

```dart
Consumer(
  builder: (context, ref, child) {
    final socketService = ref.watch(socketServiceProvider);
    return Text(
      socketService.isConnected ? 'Connected' : 'Disconnected',
      style: TextStyle(
        color: socketService.isConnected ? Colors.green : Colors.red,
      ),
    );
  },
)
```

### Monitor Chat State

```dart
ref.listen(chatProvider(gameId), (previous, next) {
  print('Messages: ${next.messages.length}');
  print('Loading: ${next.isLoading}');
  print('Sending: ${next.isSending}');
  print('Error: ${next.error}');
});
```

## ⚡ Performance Tips

1. **Use `autoDispose`**: Providers automatically clean up when not in use
2. **Limit message history**: Only load recent messages initially
3. **Debounce typing**: Don't send on every keystroke
4. **Optimize rebuilds**: Use `select` to watch specific fields

```dart
// Only rebuild when messages change
final messages = ref.watch(
  chatProvider(gameId).select((state) => state.messages)
);
```

## 🎉 That's It!

You're now ready to add real-time chat to any game screen. The providers handle all the complexity:
- ✅ Socket connection management
- ✅ Auto-join/leave rooms
- ✅ Message synchronization
- ✅ Error handling
- ✅ Loading states

Just watch the providers and build your UI! 🚀
