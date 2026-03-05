import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../location.dart';
import '../../../../app/routes/app_routes.dart';

/// Example 1: Simple Location Button
/// 
/// Shows how to add a "Get Location" button anywhere in your app
class SimpleLocationButton extends ConsumerWidget {
  const SimpleLocationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationControllerProvider);
    final isLoading = locationState.isLoading;

    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              ref
                  .read(locationControllerProvider.notifier)
                  .fetchCurrentLocation();
            },
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(isLoading ? 'Getting Location...' : 'Get My Location'),
    );
  }
}

/// Example 2: Display Current Location
/// 
/// Shows how to display location data in your UI
class LocationDisplay extends ConsumerWidget {
  const LocationDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);

    if (location == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No location detected'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('📍 ${location.address}'),
            const SizedBox(height: 4),
            Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            if (location.city != null) ...[
              const SizedBox(height: 4),
              Text('🏙️ ${location.city}'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Example 3: Create Offline Game with Location
/// 
/// Shows how to use location when creating an offline game
class CreateOfflineGameExample extends ConsumerWidget {
  const CreateOfflineGameExample({super.key});

  Future<void> _createGame(WidgetRef ref, BuildContext context) async {
    final controller = ref.read(locationControllerProvider.notifier);

    // Step 1: Get current location
    await controller.fetchCurrentLocation();

    final location = controller.getLocation();

    if (location == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location to create offline game'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 2: Create game with location data
    final gameData = {
      'title': 'Street Football Match',
      'type': 'offline',
      'maxPlayers': 10,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
        'city': location.city,
        'state': location.state,
        'country': location.country,
      },
    };

    // Step 3: Send to API
    // await createGameApi(gameData);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game created at ${location.address}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(currentLocationProvider) != null;

    return Column(
      children: [
        if (!hasLocation) const SimpleLocationButton(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: hasLocation ? () => _createGame(ref, context) : null,
          child: const Text('Create Offline Game'),
        ),
      ],
    );
  }
}

/// Example 4: Find Nearby Games
/// 
/// Shows how to filter games by location radius
class NearbyGamesExample extends ConsumerWidget {
  final double radiusKm;

  const NearbyGamesExample({
    super.key,
    this.radiusKm = 5.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = ref.watch(currentLocationProvider);

    // Mock games data (replace with actual games from API)
    final allGames = <Map<String, dynamic>>[];

    if (userLocation == null) {
      return Column(
        children: [
          const Text('Enable location to find nearby games'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.location);
            },
            child: const Text('Enable Location'),
          ),
        ],
      );
    }

    // Filter games within radius
    final nearbyGames = allGames.where((game) {
      final gameLoc = game['location'] as Map<String, dynamic>?;
      if (gameLoc == null) return false;

      final gameLocation = LocationEntity(
        latitude: gameLoc['latitude'] as double,
        longitude: gameLoc['longitude'] as double,
        address: gameLoc['address'] as String,
      );

      return userLocation.isWithinRadius(gameLocation, radiusKm);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Games within ${radiusKm}km of you',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Your location: ${userLocation.address}'),
        const SizedBox(height: 16),
        Text(
          'Found ${nearbyGames.length} nearby games',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // List games here...
      ],
    );
  }
}

/// Example 5: Location with Error Handling
/// 
/// Shows how to handle different location states
class LocationWithErrorHandling extends ConsumerWidget {
  const LocationWithErrorHandling({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            _buildStatusIndicator(locationState),
            const SizedBox(height: 16),

            // Action button
            if (locationState.type == LocationStateType.initial ||
                locationState.type == LocationStateType.error)
              ElevatedButton(
                onPressed: locationState.isLoading
                    ? null
                    : () {
                        ref
                            .read(locationControllerProvider.notifier)
                            .fetchCurrentLocation();
                      },
                child: const Text('Get Location'),
              ),

            if (locationState.type == LocationStateType.success)
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(locationControllerProvider.notifier)
                      .sendCurrentLocationToServer();
                },
                child: const Text('Save to Server'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(LocationState state) {
    switch (state.type) {
      case LocationStateType.loading:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Getting your location...'),
          ],
        );

      case LocationStateType.success:
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Location: ${state.location?.address ?? "Unknown"}'),
            ),
          ],
        );

      case LocationStateType.error:
        return Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.errorMessage ?? 'Error getting location',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );

      case LocationStateType.permissionDenied:
        return const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permission denied. Please enable in settings.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );

      case LocationStateType.gpsDisabled:
        return const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'GPS is disabled. Please enable it.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );

      default:
        return const Text('Tap the button to get your location');
    }
  }
}

/// Example 6: Navigate to Location Page
/// 
/// Shows how to navigate to the full location page
class NavigateToLocationPage extends StatelessWidget {
  const NavigateToLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: const Text('Location Settings'),
      subtitle: const Text('View and update your location'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.location);
      },
    );
  }
}

/// Example 7: Distance Calculator
/// 
/// Shows how to calculate distance between two locations
class DistanceCalculatorExample extends StatelessWidget {
  const DistanceCalculatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Example locations
    final location1 = const LocationEntity(
      latitude: 27.700769,
      longitude: 83.448278,
      address: 'Butwal, Lumbini Province, Nepal',
    );

    final location2 = const LocationEntity(
      latitude: 27.717245,
      longitude: 85.323959,
      address: 'Kathmandu, Bagmati Province, Nepal',
    );

    final distanceKm = location1.distanceTo(location2);
    final isWithin10Km = location1.isWithinRadius(location2, 10.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distance Calculator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('From: ${location1.address}'),
            Text('To: ${location2.address}'),
            const SizedBox(height: 8),
            Text(
              'Distance: ${distanceKm.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Within 10km: ${isWithin10Km ? "Yes ✅" : "No ❌"}',
              style: TextStyle(
                color: isWithin10Km ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
