# Game Card Enhancements

## Overview
Enhanced `GameCard` widget with comprehensive role-based UI, loading states, camera dark mode integration, and chat access indicators.

## Key Features Implemented

### 1. **Camera Dark Mode Integration**
- **Provider**: `cameraDarkModeProvider` from `camera_dark_mode_provider.dart`
- **Usage**: Card automatically adapts to dark mode based on front camera light sensor
- **Benefits**: 
  - More immersive experience in low-light environments
  - Reduces eye strain during night play sessions
  - Premium visual polish with adjusted shadows and borders

### 2. **Role-Based Button Logic**
Implements mutually exclusive button states based on user relationship to the game:

#### Creator State
- **Primary Action**: "Go to Chat" button (direct chat access)
- **Secondary Action**: "Cancel Game" button (outlined warning style)
- **Delete Action**: Top-right delete icon overlay
- **Chat Access**: ✅ Unlocked (badge displayed)
- **View Details**: Available via card tap

#### Participant State  
- **Primary Action**: "View Details" button
- **Secondary Action**: "Leave Game" button (outlined warning style)
- **Chat Access**: ✅ Unlocked (badge displayed)
- **View Details**: Available via card tap

#### Non-Participant State
- **Primary Action**: "Join Game · X spots left" button
- **Chat Access**: ❌ Locked (no badge, shows error snackbar)
- **View Details**: Blocked with helpful error message
- **Full Game**: "Game Full" disabled state (border outline only)

### 3. **Loading States & Double-Click Prevention**
- **`_isProcessing` State**: Prevents duplicate action calls
- **Loading Indicators**: Circular progress spinners replace button icons during actions
- **Disabled Buttons**: All action buttons disabled while processing
- **Text Updates**: "Join Game" → "Joining..." during processing
- **Action Wrapper**: `_handleAction()` method ensures serialized execution

### 4. **Chat Access Indicators**
- **Unlocked Badge**: Green badge with chat icon displayed for creators and participants
  - Position: Top-right of game image
  - Style: Green background (#10B981) with shadow
  - Text: "Chat Unlocked"
- **Locked Behavior**: 
  - No badge shown for non-participants
  - Card tap shows error snackbar with lock icon
  - Message: "Join game first to view details & access chat"

### 5. **Enhanced Visual Design**
- **Dark Mode Card Style**:
  - Background: `#1E293B` (slate-800)
  - Border: `#334155` (slate-700) with 1.5px width
  - Elevation: 4 (vs 2 in light mode)
  - Shadow: `Colors.black45`
- **Light Mode Card Style**:
  - Background: White
  - Border: Theme divider color with 1px width
  - Elevation: 2
  - Shadow: `Colors.black12`
- **Image Placeholder**: 
  - Dark mode: Slate gradients (#334155 → #1E293B)
  - Light mode: Primary/secondary theme gradients

### 6. **Improved Error Messages**
- **Snackbar Style**: Floating snackbar with rounded corners
- **Icon Support**: Lock icon for access denied messages
- **Color Coding**: Error color from theme
- **Message Clarity**: "Join game first to view details & access chat"

## Technical Implementation

### State Management
```dart
class _GameCardState extends ConsumerState<GameCard> {
  bool _isProcessing = false;
  
  Future<void> _handleAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
```

### Role Detection
```dart
bool get _isCreator => widget.isAlreadyCreator || 
    (widget.currentUserId != null && widget.game.isCreator(widget.currentUserId!));

bool get _isParticipant => widget.currentUserId != null && 
    widget.game.isParticipant(widget.currentUserId!);

bool get _isJoined => widget.isAlreadyJoined || _isCreator || _isParticipant;

bool get _canAccessChat => _isCreator || _isParticipant || widget.isAlreadyJoined;
```

### Dark Mode Detection
```dart
final cameraDarkMode = ref.watch(cameraDarkModeProvider);
final isDark = cameraDarkMode; // Uses camera sensor for theme
```

## Button State Matrix

| User Role       | Game Status | Primary Button       | Secondary Button  | Delete Icon | Chat Access |
|-----------------|-------------|----------------------|-------------------|-------------|-------------|
| Creator         | OPEN        | Go to Chat          | Cancel Game       | ✅          | ✅          |
| Creator         | FULL        | Go to Chat          | Cancel Game       | ✅          | ✅          |
| Participant     | OPEN        | View Details        | Leave Game        | ❌          | ✅          |
| Participant     | FULL        | View Details        | Leave Game        | ❌          | ✅          |
| Non-participant | OPEN        | Join Game · X spots | -                 | ❌          | ❌          |
| Non-participant | FULL        | Game Full (disabled)| -                 | ❌          | ❌          |
| Any             | CANCELLED   | (none)              | -                 | ❌          | -           |
| Any             | ENDED       | (none)              | -                 | ❌          | -           |

## UX Improvements

1. **Visual Feedback**: Loading spinners provide immediate action feedback
2. **Error Prevention**: Disabled buttons prevent invalid state transitions
3. **Clear Affordances**: Chat badge clearly indicates access level
4. **Consistent Styling**: Warning color (orange) for destructive/leave actions
5. **Accessibility**: Tooltips on delete icon, clear button labels
6. **Responsive**: Buttons auto-disable during processing across all states
7. **Safe Actions**: `mounted` check prevents setState on disposed widgets

## Dependencies Added
- `flutter_riverpod` (Consumer widget for cameraDarkModeProvider)
- `camera_dark_mode_provider.dart` (custom provider for sensor-based theming)

## Breaking Changes
- Changed from `StatelessWidget` to `ConsumerStatefulWidget`
- All internal references changed from direct properties to `widget.propertyName`
- Added required `isProcessing` parameter to `_ActionButtons`

## Future Enhancements
- [ ] Real-time participant count updates via WebSocket
- [ ] Smooth animations for state transitions (join/leave)
- [ ] Optimistic UI updates before server confirmation
- [ ] Undo functionality for accidental leave actions
- [ ] Game full notification when last spot is taken

## Testing Checklist
- [x] Creator can access chat immediately
- [x] Participant can access chat after joining
- [x] Non-participant sees locked state
- [x] Join button shows loading spinner
- [x] Double-click prevention works
- [x] Dark mode adapts card styling
- [x] Chat badge only shows for authorized users
- [x] Delete icon only appears for creator
- [x] Full games show disabled state
- [x] Cancelled/Ended games hide actions
