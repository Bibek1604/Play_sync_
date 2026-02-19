# Testing & Verification Checklist

Use this checklist to verify that all features are working correctly.

## ✅ Pre-Flight Checks

### Environment Setup
- [ ] Backend server is running
- [ ] Backend URL is configured in `api_endpoints.dart`
- [ ] Socket.IO server is accessible
- [ ] Database is connected

### Dependencies
- [ ] All packages installed (`flutter pub get`)
- [ ] No compilation errors
- [ ] Hive boxes initialized
- [ ] Socket.IO client package added

## 🎮 Game Feature Tests

### Basic Game Operations
- [ ] **View Games List**
  - [ ] Navigate to dashboard
  - [ ] See online games count
  - [ ] See offline games count
  - [ ] Games load without errors

- [ ] **Create Game**
  - [ ] Open create game dialog
  - [ ] Fill in game details
  - [ ] Select online/offline category
  - [ ] Submit successfully
  - [ ] New game appears in list

- [ ] **Join Game**
  - [ ] Click join on a game
  - [ ] Player count increases
  - [ ] Game appears in "My Games"
  - [ ] Can navigate to game chat

- [ ] **Leave Game**
  - [ ] Click leave game
  - [ ] Player count decreases
  - [ ] Game removed from "My Games"
  - [ ] Confirmation works

- [ ] **Update Game**
  - [ ] Edit game details (as creator)
  - [ ] Changes save successfully
  - [ ] Updated info displays

- [ ] **Delete Game**
  - [ ] Delete game (as creator)
  - [ ] Game removed from list
  - [ ] Confirmation dialog works

### Game Filtering
- [ ] **Online Games**
  - [ ] Only online games shown
  - [ ] Count is accurate
  - [ ] Can create online game

- [ ] **Offline Games**
  - [ ] Only offline games shown
  - [ ] Count is accurate
  - [ ] Can create offline game

### Game Details
- [ ] **View Game**
  - [ ] Game name displays
  - [ ] Player count shows
  - [ ] Status is correct
  - [ ] Tags display
  - [ ] Location shows (if offline)

## 💬 Chat Feature Tests

### Basic Chat Operations
- [ ] **View Chat**
  - [ ] Navigate to game chat
  - [ ] Previous messages load
  - [ ] Messages display correctly
  - [ ] Timestamps show

- [ ] **Send Message**
  - [ ] Type message
  - [ ] Click send
  - [ ] Message appears immediately
  - [ ] Input clears after send

- [ ] **Receive Message**
  - [ ] Open chat in two devices/browsers
  - [ ] Send from device A
  - [ ] Receive on device B
  - [ ] No delay (< 1 second)

### Chat UI
- [ ] **Message Display**
  - [ ] User messages show avatar
  - [ ] Sender name displays
  - [ ] Timestamp is correct
  - [ ] System messages styled differently

- [ ] **Input Field**
  - [ ] Can type message
  - [ ] Send button enabled/disabled correctly
  - [ ] Loading indicator shows when sending
  - [ ] Enter key sends message

- [ ] **Empty States**
  - [ ] "No messages" shows when empty
  - [ ] Helpful message displays

## 🔌 WebSocket Tests

### Connection
- [ ] **Socket Connection**
  - [ ] Socket connects on app start
  - [ ] Connection indicator shows green
  - [ ] Socket ID is assigned
  - [ ] Auth token is sent

- [ ] **Reconnection**
  - [ ] Disconnect network
  - [ ] Socket tries to reconnect
  - [ ] Reconnects when network returns
  - [ ] No data loss

### Game Events
- [ ] **Join Game Room**
  - [ ] Socket emits `joinGame`
  - [ ] Server acknowledges
  - [ ] Can receive game events

- [ ] **Player Joined**
  - [ ] User A joins game
  - [ ] User B sees notification
  - [ ] Player count updates
  - [ ] Notification dismisses

- [ ] **Player Left**
  - [ ] User A leaves game
  - [ ] User B sees notification
  - [ ] Player count updates

- [ ] **Game Update**
  - [ ] Creator updates game
  - [ ] All players see update
  - [ ] Changes reflect immediately

### Chat Events
- [ ] **Chat Message**
  - [ ] Send message
  - [ ] Socket broadcasts
  - [ ] All users receive
  - [ ] No duplicates

- [ ] **System Messages**
  - [ ] Join/leave messages
  - [ ] Styled correctly
  - [ ] Show appropriate icon

## 🔄 Real-Time Updates

### Game Real-Time Provider
- [ ] **Notifications**
  - [ ] Player join shows notification
  - [ ] Player leave shows notification
  - [ ] Can dismiss notifications
  - [ ] Max 5 notifications shown

- [ ] **Game State**
  - [ ] Game updates automatically
  - [ ] Player list refreshes
  - [ ] Status changes reflect

### Chat Real-Time Provider
- [ ] **Message Sync**
  - [ ] New messages appear instantly
  - [ ] Scroll to bottom on new message
  - [ ] Unread count updates

## 📱 UI/UX Tests

### Dashboard
- [ ] **Layout**
  - [ ] Welcome card shows user info
  - [ ] Game mode buttons work
  - [ ] Stats display correctly
  - [ ] Joined games section shows

- [ ] **Navigation**
  - [ ] Online games button works
  - [ ] Offline games button works
  - [ ] Rankings button works
  - [ ] Drawer opens

### Game Chat Page
- [ ] **Layout**
  - [ ] App bar shows game info
  - [ ] Chat takes appropriate space
  - [ ] Input field is accessible
  - [ ] Send button is visible

- [ ] **Responsiveness**
  - [ ] Works on mobile
  - [ ] Works on tablet
  - [ ] Works on desktop
  - [ ] Keyboard doesn't cover input

## 🐛 Error Handling

### Network Errors
- [ ] **No Internet**
  - [ ] Shows error message
  - [ ] Can retry
  - [ ] Cached data shows
  - [ ] Graceful degradation

- [ ] **API Errors**
  - [ ] 404 handled
  - [ ] 500 handled
  - [ ] Timeout handled
  - [ ] Error message clear

### Socket Errors
- [ ] **Connection Failed**
  - [ ] Shows disconnected state
  - [ ] Retries automatically
  - [ ] User can manually retry

- [ ] **Event Errors**
  - [ ] Invalid data handled
  - [ ] Doesn't crash app
  - [ ] Logs error

### Validation Errors
- [ ] **Empty Message**
  - [ ] Can't send empty message
  - [ ] Button disabled
  - [ ] No API call made

- [ ] **Invalid Game Data**
  - [ ] Form validation works
  - [ ] Error messages show
  - [ ] Can correct and retry

## 🎯 Edge Cases

### Concurrent Users
- [ ] **Multiple Users**
  - [ ] 5+ users in same game
  - [ ] All receive messages
  - [ ] No message loss
  - [ ] Performance OK

### Long Sessions
- [ ] **Extended Use**
  - [ ] App runs for 30+ minutes
  - [ ] No memory leaks
  - [ ] Socket stays connected
  - [ ] No performance degradation

### Data Limits
- [ ] **Many Messages**
  - [ ] 100+ messages load
  - [ ] Scrolling is smooth
  - [ ] Pagination works (if implemented)

- [ ] **Many Games**
  - [ ] 50+ games in list
  - [ ] List scrolls smoothly
  - [ ] Filtering works

## 🔒 Security Tests

### Authentication
- [ ] **Token Handling**
  - [ ] Token sent in requests
  - [ ] Token sent in socket auth
  - [ ] Expired token handled
  - [ ] Refresh token works

### Authorization
- [ ] **Game Actions**
  - [ ] Only creator can update game
  - [ ] Only creator can delete game
  - [ ] Anyone can join open game
  - [ ] Can't join full game

## 📊 Performance Tests

### Load Times
- [ ] **Initial Load**
  - [ ] Dashboard loads < 2s
  - [ ] Games list loads < 3s
  - [ ] Chat loads < 2s

### Responsiveness
- [ ] **UI Interactions**
  - [ ] Button clicks instant
  - [ ] Navigation smooth
  - [ ] No lag when typing

### Memory
- [ ] **Resource Usage**
  - [ ] Memory usage reasonable
  - [ ] No memory leaks
  - [ ] CPU usage normal

## 🎨 Visual Tests

### Dark Mode
- [ ] **Theme Support**
  - [ ] Dark mode works
  - [ ] Light mode works
  - [ ] Colors readable
  - [ ] Contrast sufficient

### Animations
- [ ] **Transitions**
  - [ ] Page transitions smooth
  - [ ] Loading indicators work
  - [ ] No janky animations

## 📝 Documentation Tests

### Code Documentation
- [ ] **Comments**
  - [ ] Classes documented
  - [ ] Methods documented
  - [ ] Complex logic explained

### User Documentation
- [ ] **Guides Available**
  - [ ] Quick start guide
  - [ ] Implementation guide
  - [ ] Architecture docs
  - [ ] API reference

## 🚀 Deployment Readiness

### Build
- [ ] **Release Build**
  - [ ] App builds successfully
  - [ ] No warnings
  - [ ] Optimized for production

### Configuration
- [ ] **Environment**
  - [ ] Production URLs set
  - [ ] Debug logs disabled
  - [ ] Analytics configured

---

## 📋 Test Results Template

Copy this template to track your testing:

```
Date: _______________
Tester: _______________
Environment: _______________

✅ Passed Tests: ___ / ___
❌ Failed Tests: ___ / ___
⚠️  Warnings: ___ / ___

Critical Issues:
1. _______________
2. _______________

Minor Issues:
1. _______________
2. _______________

Notes:
_______________
_______________
```

---

## 🎯 Priority Testing Order

1. **Critical Path** (Must work)
   - [ ] Create game
   - [ ] Join game
   - [ ] Send chat message
   - [ ] Receive chat message

2. **Core Features** (Should work)
   - [ ] View games
   - [ ] Filter games
   - [ ] Leave game
   - [ ] Real-time updates

3. **Nice to Have** (Good to work)
   - [ ] Notifications
   - [ ] Dark mode
   - [ ] Animations
   - [ ] Error recovery

---

Good luck with testing! 🚀
