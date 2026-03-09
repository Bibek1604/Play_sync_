import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/game_notifier.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/back_button_widget.dart';

/// A production-ready page for creating offline games with automated GPS detection.
/// Focuses on Android-specific requirements and modern Flutter best practices.
class CreateOfflineGamePage extends ConsumerStatefulWidget {
  const CreateOfflineGamePage({super.key});

  @override
  ConsumerState<CreateOfflineGamePage> createState() => _CreateOfflineGamePageState();
}

class _CreateOfflineGamePageState extends ConsumerState<CreateOfflineGamePage> {
final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _playersController = TextEditingController(text: '10');
  final _descController = TextEditingController();
double? _latitude;
  double? _longitude;
  String? _areaName;
  bool _isDetectingLocation = false;
  String? _locationErrorMessage;
bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start detecting location immediately when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playersController.dispose();
    _descController.dispose();
    super.dispose();
  }
/// Handles the complete flow of detecting location:
  /// Service check -> Permission request -> Position acquisition -> Reverse Geocoding
  Future<void> _detectLocation() async {
    if (!mounted) return;

    setState(() {
      _isDetectingLocation = true;
      _locationErrorMessage = null;
      _latitude = null;
      _longitude = null;
      _areaName = null;
    });

    try {
      // 1. Check if location services are enabled at the OS level
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isDetectingLocation = false);
          await _showLocationServiceDialog();
        }
        return;
      }

      // 2. Check and request runtime permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[Location] Initial permission: $permission');

      if (permission == LocationPermission.denied) {
        // First time asking - show explanation dialog
        if (mounted) {
          final shouldRequest = await _showPermissionExplanationDialog();
          if (!shouldRequest) {
            setState(() {
              _isDetectingLocation = false;
              _locationErrorMessage = 'Location permission is required for offline games';
            });
            return;
          }
        }

        // Request permission
        permission = await Geolocator.requestPermission();
        debugPrint('[Location] After request permission: $permission');

        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isDetectingLocation = false;
              _locationErrorMessage = 'Location permission denied. Tap Retry and allow access.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isDetectingLocation = false);
          await _showPermissionDeniedForeverDialog();
        }
        return;
      }

      // 3. Get the actual GPS position with timeout
      debugPrint('[Location] Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw 'Location timeout. Please make sure you are outdoors or near a window.';
        },
      );

      debugPrint('[Location] Position acquired: ${position.latitude}, ${position.longitude}');

      // 4. Try to get a user-friendly area name (Reverse Geocoding)
      String? detectedArea;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Combine suburb/locality for a friendly "Area Name"
          detectedArea = [p.subLocality, p.locality, p.subAdministrativeArea]
              .where((s) => s != null && s!.isNotEmpty)
              .take(2)
              .join(', ');
        }
      } catch (e) {
        // Fallback to coordinates if geocoding fails (e.g. no internet)
        debugPrint('Geocoding error: $e');
      }

      // Always show coordinates if area name is empty
      if (detectedArea == null || detectedArea.isEmpty) {
        detectedArea = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _areaName = detectedArea;
          _isDetectingLocation = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: $detectedArea'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Location] Error: $e');
      if (mounted) {
        setState(() {
          _locationErrorMessage = e.toString();
          _isDetectingLocation = false;
        });
      }
    }
  }

  /// Shows dialog explaining why location permission is needed
  Future<bool> _showPermissionExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Location Access Needed'),
          ],
        ),
        content: const Text(
          'PlaySync needs your location to help nearby players find and join your offline game. Your exact location is only used for this game session.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Allow Access'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Shows dialog when GPS/Location Services are disabled
  Future<void> _showLocationServiceDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gps_off, color: AppColors.error),
            SizedBox(width: 12),
            Text('GPS is Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off on your device. Please enable GPS in your device settings to create offline games.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Open location settings
      await Geolocator.openLocationSettings();
      // Wait a bit for user to enable, then retry
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _detectLocation();
      }
    } else {
      if (mounted) {
        setState(() {
          _locationErrorMessage = 'GPS must be enabled to create offline games';
        });
      }
    }
  }

  /// Shows dialog when location permission is permanently denied
  Future<void> _showPermissionDeniedForeverDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: AppColors.error),
            SizedBox(width: 12),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission has been permanently denied. Please enable it manually in App Settings > Permissions > Location.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Open app settings
      await Geolocator.openAppSettings();
      // Wait for user to grant permission and return
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _detectLocation();
      }
    } else {
      if (mounted) {
        setState(() {
          _locationErrorMessage = 'Location permission is required for offline games';
        });
      }
    }
  }
Future<void> _submit() async {
    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) return;

    // 2. Ensure Location is Available
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for location to be detected before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 3. Prepare Data for Backend
      // Using FormData as per PlaySync backend requirements (allows for expansion like images later)
      final formData = FormData.fromMap({
        'title': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'maxPlayers': int.tryParse(_playersController.text.trim()) ?? 10,
        'category': 'OFFLINE',
        'latitude': _latitude,
        'longitude': _longitude,
        'locationName': _areaName ?? 'Manual Location',
        // Optional default tags
        'tags': ['Offline', 'Local'],
      });

      // 4. Send to Provider/Notifier
      final success = await ref.read(gameProvider.notifier).createGame(formData);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline game created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(); // Return to previous screen
        } else {
          final errorMsg = ref.read(gameProvider).error ?? 'Failed to create game';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackButtonWidget(label: 'Back'),
        ),
        leadingWidth: 100,
        title: const Text('New Offline Session', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
const Text(
                'Host a Local Game',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invite nearby players to join your session.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
_buildLocationStatus(),
              const SizedBox(height: AppSpacing.xl),
_buildFormField(
                label: 'Game Name *',
                hint: 'e.g. Backyard Cricket, Chess at Park',
                controller: _nameController,
                icon: Icons.sports_esports_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a game name' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
_buildFormField(
                label: 'Max Players *',
                hint: 'Total player limit',
                controller: _playersController,
                icon: Icons.group_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 2) return 'Min 2 players required';
                  return null;
                },
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.lg),
_buildFormField(
                label: 'Description (Optional)',
                hint: 'Details about meeting point, rules, etc.',
                controller: _descController,
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xxl),
SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isDetectingLocation || _isSubmitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Create Offline Game',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a modern text field with consistent styling
  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
            ),
          ),
        ),
      ],
    );
  }

  /// Displays the current GPS status and allows retrying if it fails.
  Widget _buildLocationStatus() {
    // Determine status color and message
    final bool hasError = _locationErrorMessage != null && !_isDetectingLocation;
    final bool isSuccess = _latitude != null;
    final Color statusColor = isSuccess 
        ? AppColors.success 
        : hasError 
            ? AppColors.error 
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSuccess 
            ? AppColors.success.withValues(alpha: 0.05)
            : hasError
                ? AppColors.error.withValues(alpha: 0.05)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess 
              ? AppColors.success.withValues(alpha: 0.2)
              : hasError
                  ? AppColors.error.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
          width: hasError ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSuccess 
                      ? AppColors.success 
                      : hasError
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSuccess 
                      ? Icons.my_location_rounded 
                      : hasError
                          ? Icons.location_off_rounded
                          : Icons.location_searching_rounded,
                  color: isSuccess 
                      ? Colors.white 
                      : hasError
                          ? AppColors.error
                          : AppColors.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess 
                          ? '✓ Location Detected' 
                          : hasError
                              ? '⚠ Location Error'
                              : 'Detecting Location...',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_isDetectingLocation)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Accessing GPS satellites...',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      )
                    else if (hasError)
                      Text(
                        _locationErrorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (_areaName != null)
                      Text(
                        _areaName!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        'GPS coordinates required.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (!_isDetectingLocation && _latitude == null)
                IconButton(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Retry Location',
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          // Show coordinates when location is detected
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Lat: ${_latitude!.toStringAsFixed(6)}  •  Lng: ${_longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
