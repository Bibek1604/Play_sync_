# 📍 GPS Location Feature - Production-Ready Implementation

## Overview

This is a **production-level GPS location system** built with **Clean Architecture** for Flutter applications. It handles location permissions, GPS services, reverse geocoding, and server synchronization.

---

## 🏗️ Architecture

```
features/profile/location/
├── data/
│   ├── datasources/
│   │   └── location_datasource.dart          # GPS & API operations
│   ├── models/
│   │   └── location_model.dart                # Data model with JSON serialization
│   └── repositories/
│       └── location_repository_impl.dart      # Repository implementation
├── domain/
│   ├── entities/
│   │   └── location_entity.dart               # Pure domain entity
│   ├── repositories/
│   │   └── location_repository.dart           # Repository interface
│   └── usecases/
│       ├── get_current_location.dart          # Get GPS location use case
│       └── send_location_to_server.dart       # Send location to backend
├── presentation/
│   ├── controllers/
│   │   └── location_controller.dart           # State management controller
│   ├── pages/
│   │   └── location_page.dart                 # Main location UI page
│   └── widgets/
│       └── location_card.dart                 # Reusable location card widget
├── providers/
│   └── location_provider.dart                 # Riverpod providers
└── location.dart                              # Barrel file (exports)
```

---

## 📦 Dependencies

```yaml
dependencies:
  geolocator: ^13.0.2              # GPS location access
  geocoding: ^3.0.0                # Reverse geocoding
  permission_handler: ^11.3.1      # Runtime permissions
  flutter_riverpod: ^2.5.1         # State management
  dio: ^5.3.3                      # HTTP client
  equatable: ^2.0.5                # Value equality
  dartz: ^0.10.1                   # Functional programming
```

---

## ⚙️ Setup

### 1. Android Configuration

**AndroidManifest.xml** (already configured):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Minimum SDK**: 21 (Android 5.0+)

---

### 2. iOS Configuration

**Info.plist** (already configured):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PlaySync needs your location to find offline games near you.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>PlaySync needs your location to find offline games near you.</string>
```

---

### 3. Install Packages

```bash
flutter pub get
```

---

## 🚀 Usage

### Basic Usage (Navigate to Location Page)

```dart
import 'package:flutter/material.dart';
import 'package:play_sync_new/app/routes/app_routes.dart';

// Navigate to location page
Navigator.pushNamed(context, AppRoutes.location);
```

---

### Advanced Usage (Programmatic Access)

#### 1. Get Current Location

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/profile/location/location.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationControllerProvider);

    return ElevatedButton(
      onPressed: () {
        // Get current location
        ref.read(locationControllerProvider.notifier).fetchCurrentLocation();
      },
      child: Text('Get Location'),
    );
  }
}
```

---

#### 2. Access Location Data

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/profile/location/location.dart';

class LocationDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);

    if (location == null) {
      return Text('No location detected');
    }

    return Column(
      children: [
        Text('Latitude: ${location.latitude}'),
        Text('Longitude: ${location.longitude}'),
        Text('Address: ${location.address}'),
        Text('City: ${location.city ?? 'Unknown'}'),
      ],
    );
  }
}
```

---

#### 3. Send Location to Server

```dart
final controller = ref.read(locationControllerProvider.notifier);

// First get location
await controller.fetchCurrentLocation();

// Then send to server
await controller.sendCurrentLocationToServer();
```

---

#### 4. Check Location Availability

```dart
final controller = ref.read(locationControllerProvider.notifier);

if (controller.hasLocation()) {
  final location = controller.getLocation();
  print('Location: ${location?.address}');
} else {
  print('Location not available');
}
```

---

## 🔥 Features

### ✅ Complete Permission Handling

- **Granted**: Fetches location
- **Denied**: Shows UI message
- **Permanently Denied**: Opens app settings

### ✅ GPS Service Detection

- Checks if GPS is enabled
- Shows dialog to enable GPS
- Handles GPS disabled state

### ✅ High Accuracy GPS

- Uses `LocationAccuracy.high`
- 15-second timeout protection
- Error handling for timeouts

### ✅ Reverse Geocoding

- Converts coordinates to address
- Format: "City, State, Country"
- Example: "Butwal, Lumbini Province, Nepal"
- Handles offline/no internet gracefully

### ✅ Server Synchronization

- PATCH request to `/profile` endpoint
- Payload:
  ```json
  {
    "location": {
      "latitude": 27.700769,
      "longitude": 83.448278,
      "address": "Butwal, Lumbini Province, Nepal",
      "city": "Butwal",
      "state": "Lumbini Province",
      "country": "Nepal"
    }
  }
  ```

### ✅ Edge Case Handling

- ✅ Permission denied
- ✅ Permission permanently denied
- ✅ GPS disabled
- ✅ Location timeout
- ✅ No internet for geocoding
- ✅ API failure
- ✅ Network errors
- ✅ setState after dispose protection

---

## 🎨 UI States

| State | Description | UI Display |
|-------|-------------|------------|
| **Initial** | No location fetched yet | Shows "Use Current Location" button |
| **Loading** | Fetching GPS location | Shows circular progress indicator |
| **Success** | Location detected | Shows address, coordinates, city/state chips |
| **Error** | Generic error | Shows error message in red card |
| **Permission Denied** | User denied permission | Shows dialog with settings button |
| **GPS Disabled** | GPS is off | Shows dialog to enable GPS |

---

## 📱 UI Components

### LocationPage

Main page with:
- Info card explaining why location is needed
- Location card showing current location
- Success/error status indicators
- Dialogs for permission/GPS issues

### LocationCard

Reusable widget with:
- Current location display
- GPS coordinates (latitude/longitude)
- City, state, country chips
- "Use Current Location" button
- "Refresh" and "Save" buttons

---

## 🧪 Distance Calculation

The `LocationEntity` includes a `distanceTo()` method using the **Haversine formula**:

```dart
final location1 = LocationEntity(
  latitude: 27.700769,
  longitude: 83.448278,
  address: 'Butwal',
);

final location2 = LocationEntity(
  latitude: 27.717245,
  longitude: 85.323959,
  address: 'Kathmandu',
);

// Calculate distance in kilometers
final distanceKm = location1.distanceTo(location2);
print('Distance: $distanceKm km');

// Check if within radius
final isNearby = location1.isWithinRadius(location2, 10.0); // 10km radius
print('Is nearby: $isNearby');
```

---

## 🎯 Use Cases for Offline Games

### 1. Creating Offline Game with Location

```dart
import 'package:play_sync_new/features/profile/location/location.dart';

class CreateOfflineGame extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);

    return ElevatedButton(
      onPressed: location != null ? () {
        // Create game with location
        final gameData = {
          'title': 'Street Football',
          'type': 'offline',
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': location.address,
          },
        };
        // Send to API
      } : null,
      child: Text('Create Game'),
    );
  }
}
```

---

### 2. Finding Nearby Games

```dart
// Backend should filter games by location
// Frontend can calculate distances client-side

final userLocation = ref.watch(currentLocationProvider);
final allGames = ref.watch(gamesProvider);

if (userLocation != null) {
  final nearbyGames = allGames.where((game) {
    if (game.location == null) return false;
    
    final gameLocation = LocationEntity(
      latitude: game.location['latitude'],
      longitude: game.location['longitude'],
      address: game.location['address'],
    );
    
    // Find games within 5km
    return userLocation.isWithinRadius(gameLocation, 5.0);
  }).toList();
  
  print('Found ${nearbyGames.length} nearby games');
}
```

---

## 🔧 Error Handling

All errors are properly typed and handled:

```dart
final locationState = ref.watch(locationControllerProvider);

switch (locationState.type) {
  case LocationStateType.success:
    // Show location data
    showLocationData(locationState.location!);
    break;
    
  case LocationStateType.permissionDenied:
    // Show permission dialog
    showPermissionDialog();
    break;
    
  case LocationStateType.gpsDisabled:
    // Show GPS dialog
    showGpsDialog();
    break;
    
  case LocationStateType.error:
    // Show error message
    showError(locationState.errorMessage!);
    break;
    
  case LocationStateType.loading:
    // Show loading indicator
    showLoading();
    break;
    
  default:
    // Initial state
    showGetLocationButton();
}
```

---

## 🚨 Common Issues & Solutions

### Issue 1: Permission Denied

**Solution**: The app automatically shows a dialog to open app settings.

```dart
// This is handled automatically in LocationPage
// Or manually:
await openAppSettings();
```

---

### Issue 2: GPS Disabled

**Solution**: The app shows a dialog asking user to enable GPS.

```dart
// Check GPS status
final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
if (!isGpsEnabled) {
  // Show dialog
}
```

---

### Issue 3: Timeout

**Solution**: The system uses a 15-second timeout with error handling.

```dart
// Configured in location_datasource.dart
final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  ),
);
```

---

### Issue 4: No Internet for Geocoding

**Solution**: Returns "Unknown Location" if reverse geocoding fails.

```dart
try {
  final address = await getAddressFromCoordinates(...);
} catch (e) {
  return 'Unknown Location';
}
```

---

## 🌐 Backend Integration

### Required Endpoint

**PATCH** `/api/v1/profile`

**Request Body**:
```json
{
  "location": {
    "latitude": 27.700769,
    "longitude": 83.448278,
    "address": "Butwal, Lumbini Province, Nepal",
    "city": "Butwal",
    "state": "Lumbini Province",
    "country": "Nepal",
    "timestamp": "2026-03-05T12:00:00.000Z"
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "userId": "123",
    "location": { /* updated location */ }
  }
}
```

---

## 📊 State Management

Uses **Riverpod StateNotifier**:

```dart
// Providers available:
locationControllerProvider        // Full state
currentLocationProvider           // Just the location entity
isLocationLoadingProvider         // Loading state
locationErrorProvider             // Error message
```

---

## ✅ Production Checklist

- ✅ Null safety compliant
- ✅ No setState after dispose
- ✅ No memory leaks
- ✅ Clean Architecture
- ✅ Separation of concerns
- ✅ All edge cases handled
- ✅ Android & iOS configured
- ✅ Permission handling
- ✅ GPS service detection
- ✅ Timeout protection
- ✅ Error handling
- ✅ API integration
- ✅ Retry logic available
- ✅ Scalable structure

---

## 🧪 Testing on Physical Devices

### Android

1. Enable Developer Options
2. Enable USB Debugging
3. Connect device via USB
4. Run: `flutter run -d <device-id>`
5. Grant location permission when prompted

### iOS

1. Connect iPhone via USB
2. Trust computer on device
3. Run: `flutter run -d <device-id>`
4. Grant location permission when prompted

---

## 📝 Notes

- **Web**: Works on web but uses browser geolocation API (less accurate)
- **Emulator**: May not provide real GPS data (use device-specific test locations)
- **Background**: Not configured for background location (add `ACCESS_BACKGROUND_LOCATION` if needed)
- **Battery**: High accuracy GPS can drain battery (consider reducing accuracy for production)

---

## 🔗 Related Documentation

- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Geocoding Package](https://pub.dev/packages/geocoding)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Riverpod](https://riverpod.dev/)

---

## 🎉 Success!

You now have a **production-ready GPS location system** that:
- ✅ Works on Android & iOS
- ✅ Handles all edge cases
- ✅ Follows clean architecture
- ✅ Is fully documented
- ✅ Is ready for offline game features

Navigate to `/location` route to test it!

```dart
Navigator.pushNamed(context, AppRoutes.location);
```
