import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/location_controller.dart';
import '../../providers/location_provider.dart';
import '../widgets/location_card.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location page for getting and managing user's GPS location
/// 
/// Features:
/// - Request location permission
/// - Get current GPS coordinates
/// - Convert to human-readable address
/// - Send location to server
/// - Handle all edge cases (permission, GPS disabled, timeout, etc.)
class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({super.key});

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  @override
  void dispose() {
    // Reset state when leaving page to avoid memory leaks
    super.dispose();
  }

  Future<void> _handleGetLocation() async {
    final controller = ref.read(locationControllerProvider.notifier);
    await controller.fetchCurrentLocation();
  }

  Future<void> _handleRefreshLocation() async {
    final controller = ref.read(locationControllerProvider.notifier);
    await controller.refreshLocation();
  }

  Future<void> _handleSendToServer() async {
    final controller = ref.read(locationControllerProvider.notifier);
    await controller.sendCurrentLocationToServer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sent to server successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleOpenSettings() async {
    await openAppSettings();
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('GPS Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off. Please enable GPS in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleOpenSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission is required to access your current location. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleOpenSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationControllerProvider);

    // Show dialogs based on state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (locationState.type == LocationStateType.gpsDisabled) {
        _showGpsDisabledDialog();
      } else if (locationState.type == LocationStateType.permissionDenied) {
        _showPermissionDeniedDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Why do we need your location?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Create offline games with location\n'
                      '• Find nearby games within a radius\n'
                      '• Show your location on your profile\n'
                      '• Connect with players near you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Location Card (Main UI)
            LocationCard(
              location: locationState.location,
              isLoading: locationState.isLoading,
              errorMessage: locationState.errorMessage,
              onGetLocation: _handleGetLocation,
              onRefreshLocation: _handleRefreshLocation,
              onSendToServer: _handleSendToServer,
            ),

            const SizedBox(height: 16),

            // Status Info
            if (locationState.type == LocationStateType.success)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Location detected successfully!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (locationState.type == LocationStateType.error)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationState.errorMessage ?? 'An error occurred',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
