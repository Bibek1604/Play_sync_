# Game Creation Feature - Implementation Guide

## Overview
Professional game creation UI with green theme (#16A34A) following strict design system standards for corporate SaaS aesthetic.

## ✅ Completed Components

### 1. Create Game Sheet (`lib/features/game/presentation/widgets/create_game_sheet.dart`)
Professional bottom sheet for creating online/offline games with:
- **Header**: Icon-based title with game type indicator (wifi/location)
- **Form Fields**:
  - Game Title (validated, min 3 chars)
  - Description (multiline, required)
  - Category dropdown (Football, Basketball, Cricket, Chess, Tennis, Badminton, Other)
  - Max Players (2-100, number input with validation)
  - Prize Pool (optional, rupees)
  - Scheduled Date & Time (date + time picker with green theme)
  - Location (for offline games only, conditional)
  - Online/Offline Toggle (switch with icon and description)
- **Design**:
  - White background with rounded top corners (16px radius)
  - Green primary color throughout (#16A34A)
  - Light gray input fills (#F8F9FA)
  - Green focus borders
  - 8px spacing system
  - Professional section labels
  - Green submit button with icon
  - Loading state with green spinner

### 2. Online Games Page (`lib/features/game/presentation/pages/online_games_page.dart`)
- **AppBar**: White background, green refresh icon
- **Empty State**: Professional circular icon background, helpful messaging, green CTA button
- **Game List**: Card-based layout with proper spacing
- **FAB**: Extended green button "Create Online Game" with icon
- **Pull-to-Refresh**: Green progress indicator

### 3. Offline Games Page (`lib/features/game/presentation/pages/offline_games_page.dart`)
- **Same Professional Design** as online page
- **Location-specific Empty State**: "No Offline Games Nearby"
- **FAB**: "Create Offline Game" button
- **Pre-configured**: Opens create sheet with `isOnlineMode: false`

### 4. Game Card Widget (`lib/features/game/presentation/widgets/game_card.dart`)
Professional card design with:
- **Layout**: 
  - Header: Category icon (44x44, green background) + Title + Status chip
  - Description (2 lines max, gray text)
  - Info row: Location/Online + Players + Date (with icons)
  - Join button (conditional, green, 40px height)
- **Styling**:
  - White background with 1px border (#E5E7EB)
  - 12px border radius
  - Subtle shadow (1px elevation)
  - 16px padding all around
  - 8px spacing between elements
- **Status Chips**:
  - Upcoming: Blue background
  - Live: Red background
  - Completed: Gray background
  - Cancelled: Orange background
- **Join Button**:
  - Green background (#16A34A)
  - White text
  - Icon + text layout
  - Shows remaining spots
  - Only visible for upcoming non-full games

## 🎨 Design System Usage

All components use:
- `AppColors.primary` (#16A34A) for buttons, icons, accents
- `AppColors.background` (#FFFFFF) for page backgrounds
- `AppColors.surfaceLight` (#F8F9FA) for input fills and surfaces
- `AppColors.textPrimary` (#1F2937) for headings
- `AppColors.textSecondary` (#6B7280) for body text
- `AppColors.border` (#E5E7EB) for borders
- `AppSpacing` constants (xs/sm/md/lg/xl/xxl/xxxl)
- `AppRadius` constants (sm/md/lg/xl)

## 📋 Integration Steps

### Step 1: Import the Create Game Sheet
```dart
import '../widgets/create_game_sheet.dart';
```

### Step 2: Show the Sheet (from any page)
```dart
void _showCreateGameSheet(BuildContext context, {bool isOnline = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CreateGameSheet(isOnlineMode: isOnline),
  );
}
```

### Step 3: Connect to Game Provider
Update `create_game_sheet.dart` line 92-95:
```dart
// TODO: Replace this with actual provider call
await ref.read(gameProvider.notifier).createGame(
  title: _titleController.text.trim(),
  description: _descriptionController.text.trim(),
  category: _selectedCategory,
  maxPlayers: int.parse(_maxPlayersController.text),
  prizePool: int.tryParse(_prizePoolController.text) ?? 0,
  scheduledAt: _selectedDate,
  isOnline: _isOnline,
  location: _isOnline ? null : _locationController.text.trim(),
);
```

### Step 4: Add Create Method to Game Provider
Add to `lib/features/game/presentation/providers/game_notifier.dart`:
```dart
Future<void> createGame({
  required String title,
  required String description,
  required GameCategory category,
  required int maxPlayers,
  required int prizePool,
  required DateTime scheduledAt,
  required bool isOnline,
  String? location,
}) async {
  try {
    // Call your backend API
    final response = await _apiService.createGame(
      title: title,
      description: description,
      category: category,
      maxPlayers: maxPlayers,
      prizePool: prizePool,
      scheduledAt: scheduledAt,
      isOnline: isOnline,
      location: location,
    );
    
    // Refresh games list
    await fetchGames(refresh: true);
  } catch (e) {
    // Handle error
    state = state.copyWith(error: e.toString());
  }
}
```

## 🔗 Backend API Integration

Expected API endpoint: `POST /api/v1/games`

Request body:
```json
{
  "title": "Weekend Football Match",
  "description": "Friendly match for all skill levels",
  "category": "football",
  "maxPlayers": 22,
  "prizePool": 5000,
  "scheduledAt": "2025-01-20T15:00:00Z",
  "isOnline": false,
  "location": "Central Park Soccer Field"
}
```

Response:
```json
{
  "success": true,
  "message": "Game created successfully",
  "data": {
    "id": "game_12345",
    "title": "Weekend Football Match",
    "status": "upcoming",
    "currentPlayers": 1,
    "createdAt": "2025-01-15T10:30:00Z"
  }
}
```

## 🎯 Features Implemented

✅ **Form Validation**
- Title: Required, min 3 characters
- Description: Required
- Max Players: 2-100 range
- Location: Required for offline games only

✅ **User Experience**
- Loading states with green spinner
- Success snackbar with check icon
- Automatic sheet dismissal on success
- Date/time picker with green theme
- Conditional location field (slides in/out based on online toggle)
- Professional empty states for both online/offline pages

✅ **Visual Design**
- Professional green theme (#16A34A)
- White backgrounds
- Proper spacing (8px system)
- Rounded corners (8-12px)
- Subtle shadows
- Icon-based messaging
- Clear visual hierarchy

✅ **Responsive Behavior**
- Bottom sheet scrolls for small screens
- Safe area handling
- Keyboard-aware layout
- Pull-to-refresh on both pages

## 🚀 Next Steps

1. **Connect Backend API**:
   - Implement `createGame` method in game provider
   - Add API service calls
   - Handle response and errors

2. **Add Advanced Features**:
   - Image upload for game banner
   - Invite players directly
   - Set entry fees
   - Add game rules section
   - Location picker with maps

3. **Enhance Game Cards**:
   - Add participant avatars
   - Show game creator badge
   - Display distance for offline games
   - Add favorite/bookmark option

4. **Notifications**:
   - Notify when someone joins
   - Reminders before scheduled time
   - Status update notifications

## 📱 Screenshots Location
- Create Game Sheet: Professional form with green accents
- Online Games Page: Empty state + list view with FAB
- Offline Games Page: Location-specific empty state
- Game Card: Clean card design with status chips

## ⚙️ Testing Checklist

- [ ] Form validation (all fields)
- [ ] Online/offline toggle functionality
- [ ] Location field shows/hides correctly
- [ ] Date & time picker works
- [ ] Submit button loading state
- [ ] Success snackbar appears
- [ ] Sheet closes after creation
- [ ] Games list refreshes
- [ ] Empty states display correctly
- [ ] FAB buttons work on both pages
- [ ] Pull-to-refresh functions
- [ ] Game cards render properly
- [ ] Join button appears for valid games
- [ ] Status chips show correct colors

## 🎨 Design Consistency

All UI elements follow the **PlaySync Design System**:
- Primary Color: #16A34A (Professional Green)
- Background: #FFFFFF (Pure White)
- Surface: #F8F9FA (Light Gray)
- Text Primary: #1F2937 (Dark Charcoal)
- Text Secondary: #6B7280 (Medium Gray)
- Border: #E5E7EB (Light Gray Border)
- Spacing: 4/8/12/16/24/32/48px progression
- Radius: 4/6/8/12/16px progression
- Elevation: Subtle shadows (1-2px for cards, 4px for FAB)

This matches the professional SaaS aesthetic established in the forgot password feature.
