import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/game_notifier.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';

/// Multi-step game creation wizard.
/// Steps:
///   1. Basic Info   (cover, title, description)
///   2. Game Settings (tags, max players, start/end time)
///   3. Location     (offline only — district + GPS)
class CreateGameSheet extends ConsumerStatefulWidget {
  final bool isOnlineMode;
  const CreateGameSheet({super.key, this.isOnlineMode = false});

  @override
  ConsumerState<CreateGameSheet> createState() => _CreateGameSheetState();
}

class _CreateGameSheetState extends ConsumerState<CreateGameSheet> {
int _currentStep = 0;
  int get _totalSteps => widget.isOnlineMode ? 2 : 3;
final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
final _titleCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _tagsCtrl       = TextEditingController();
  final _maxPlayersCtrl = TextEditingController(text: '10');
Uint8List? _imageBytes;
  String?    _imageName;
  DateTime   _startTime = DateTime.now();
  DateTime   _endTime   = DateTime.now().add(const Duration(hours: 1));
  double?    _latitude;
  double?    _longitude;
  bool       _fetchingGps = false;
  bool       _submitting  = false;
  String?    _address;
  String?    _locationError;
  int        _gpsRetryCount = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isOnlineMode) {
      _fetchGps();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }
bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        if (_latitude == null || _longitude == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location data is required for offline games'),
            backgroundColor: AppColors.error,
          ));
          return false;
        }
        return _step3Key.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previous() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
Future<DateTime?> _pickDateTime(BuildContext ctx, DateTime initial) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(minutes: 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
Future<void> _fetchGps() async {
    if (!mounted) return;
    setState(() {
      _fetchingGps = true;
      _locationError = null;
    });

    try {
      if (!kIsWeb) {
        bool svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (!svcEnabled) throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) throw 'Location access is required to create an offline game.';
      if (perm == LocationPermission.deniedForever) {
        if (kIsWeb) {
          throw 'Location permission permanently denied by your browser. Please allow location in site settings.';
        } else {
          throw 'Location permission permanently denied. Please enable it in system settings.';
        }
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // Accuracy check (< 100 meters)
      // Note: On web, accuracy can be lower (if IP-based), but we still aim for better precision.
      if (pos.accuracy > 100) {
        if (_gpsRetryCount < 2) {
          _gpsRetryCount++;
          debugPrint('Accuracy too low (${pos.accuracy}m), retrying... ($_gpsRetryCount)');
          await Future.delayed(const Duration(seconds: 2));
          return _fetchGps();
        }
        // Be more lenient on web if multiple retries fail
        if (!kIsWeb) {
          throw 'GPS accuracy too low (${pos.accuracy.toStringAsFixed(1)}m). Please move to an open area.';
        }
      }

      _gpsRetryCount = 0;

      // Reverse geocode
      String? addr;
      try {
        if (kIsWeb) {
          // Use OpenStreetMap Nominatim for Web (geocoding package is mobile-only)
          final dio = Dio();
          final resp = await dio.get(
            'https://nominatim.openstreetmap.org/reverse',
            queryParameters: {
              'lat': pos.latitude,
              'lon': pos.longitude,
              'format': 'jsonv2',
            },
          );
          if (resp.data != null && resp.data is Map) {
             final address = resp.data['address'] as Map?;
             if (address != null) {
               addr = address['suburb'] ?? address['city'] ?? address['village'] ?? address['town'] ?? address['state'];
             }
          }
        } else {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [p.name, p.subLocality, p.locality, p.administrativeArea]
                .where((s) => s != null && s!.isNotEmpty)
                .take(2);
            addr = parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding fail: $e');
        addr = 'Detected Location';
      }

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _address = addr;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }
Future<void> _submit() async {
    // End time must be > now + 2 min (backend rule)
    if (_endTime.isBefore(DateTime.now().add(const Duration(minutes: 2)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('End time must be at least 2 minutes in the future'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _submitting = true);

    final tagList = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tagList.isEmpty) tagList.add('Gaming');

    final formData = FormData();
    formData.fields
      ..add(MapEntry('title',       _titleCtrl.text.trim()))
      ..add(MapEntry('description', _descCtrl.text.trim()))
      ..add(MapEntry('maxPlayers',  _maxPlayersCtrl.text.trim()))
      ..add(MapEntry('startTime',   _startTime.toIso8601String()))
      ..add(MapEntry('endTime',     _endTime.toIso8601String()))
      ..add(MapEntry('category',    widget.isOnlineMode ? 'ONLINE' : 'OFFLINE'));

    for (final tag in tagList) {
      formData.fields.add(MapEntry('tags', tag));
    }

    if (!widget.isOnlineMode) {
      if (_address != null && _address!.isNotEmpty) {
        formData.fields.add(MapEntry('locationName', _address!));
      }
      if (_latitude != null && _longitude != null) {
        formData.fields
          ..add(MapEntry('latitude',  _latitude.toString()))
          ..add(MapEntry('longitude', _longitude.toString()));
      }
    }

    if (_imageBytes != null) {
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(_imageBytes!, filename: _imageName ?? 'cover.jpg'),
      ));
    }

    final createdGame = await ref.read(gameProvider.notifier).createGame(formData);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (createdGame != null) {
      // Close the sheet first
      Navigator.pop(context);

      // Then immediately navigate to the game chat
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameChatRoomPage(
              gameId: createdGame.id,
              gameTitle: createdGame.title,
              gameImageUrl: createdGame.imageUrl,
            ),
          ),
        );
      }
    } else {
      final err = ref.read(gameProvider).error ?? 'Failed to create game';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
@override
  Widget build(BuildContext context) {
    final mode = widget.isOnlineMode ? 'Online' : 'Offline';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
Center(
                child: Container(
                  width: 36, height: 4,
                  margin: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(
                      widget.isOnlineMode ? Icons.wifi_rounded : Icons.sports_rounded,
                      color: AppColors.primary, size: 20),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create $mode Session',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                      Text('Step ${_currentStep + 1} of $_totalSteps',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  )),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                    onPressed: () => Navigator.pop(context)),
                ]),
              ),

              SizedBox(height: AppSpacing.md),
Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StepProgressBar(
                  totalSteps: _totalSteps,
                  currentStep: _currentStep,
                ),
              ),

              SizedBox(height: AppSpacing.md),
Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildStepContent(),
                  ),
                ),
              ),
Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                ),
                child: Row(children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previous,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_currentStep > 0) SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              _currentStep == _totalSteps - 1 ? 'Create Session' : 'Continue',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _Step1BasicInfo(
          key: const ValueKey('step1'),
          formKey: _step1Key,
          titleCtrl: _titleCtrl,
          descCtrl: _descCtrl,
          imageBytes: _imageBytes,
          imageName: _imageName,
          onImagePicked: (bytes, name) => setState(() {
            _imageBytes = bytes;
            _imageName = name;
          }),
          onImageRemoved: () => setState(() {
            _imageBytes = null;
            _imageName = null;
          }),
        );
      case 1:
        return _Step2GameSettings(
          key: const ValueKey('step2'),
          formKey: _step2Key,
          tagsCtrl: _tagsCtrl,
          maxPlayersCtrl: _maxPlayersCtrl,
          startTime: _startTime,
          endTime: _endTime,
          onStartTimeChanged: (dt) => setState(() => _startTime = dt),
          onEndTimeChanged: (dt) => setState(() => _endTime = dt),
          pickDateTime: _pickDateTime,
        );
      case 2:
        return _Step3Location(
          key: const ValueKey('step3'),
          formKey: _step3Key,
          address: _address,
          latitude: _latitude,
          longitude: _longitude,
          fetchingGps: _fetchingGps,
          error: _locationError,
          onFetchGps: _fetchGps,
          onResetGps: () => setState(() { _latitude = null; _longitude = null; _address = null; _locationError = null; }),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
// STEP PROGRESS BAR
class _StepProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const _StepProgressBar({required this.totalSteps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepBefore = i ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: stepBefore < currentStep ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        // Step circle
        final stepIdx = i ~/ 2;
        final isActive = stepIdx == currentStep;
        final isCompleted = stepIdx < currentStep;
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : (isActive ? AppColors.primary : AppColors.background),
            border: Border.all(
              color: isActive || isCompleted ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '${stepIdx + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
// STEP 1: BASIC INFO
class _Step1BasicInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final void Function(Uint8List, String) onImagePicked;
  final VoidCallback onImageRemoved;

  const _Step1BasicInfo({
    super.key,
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.imageBytes,
    required this.imageName,
    required this.onImagePicked,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.edit_note_rounded,
            title: 'Basic Information',
            subtitle: 'Add a cover image and describe your session',
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Cover Image'),
          SizedBox(height: AppSpacing.sm),
          _ImagePicker(
            imageBytes: imageBytes,
            imageName: imageName,
            onTap: () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (f != null) {
                final bytes = await f.readAsBytes();
                onImagePicked(bytes, f.name);
              }
            },
            onRemove: onImageRemoved,
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Title *'),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: titleCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDec(hint: 'e.g. Counter Strike Tournament', icon: Icons.title_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              if (v.trim().length < 3) return 'Minimum 3 characters';
              if (v.trim().length > 255) return 'Maximum 255 characters';
              return null;
            },
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Description'),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: descCtrl,
            maxLines: 3,
            maxLength: 2000,
            decoration: _inputDec(hint: 'Describe the rules, requirements, etc…', icon: Icons.description_outlined),
            validator: (v) {
              if (v != null && v.length > 2000) return 'Max 2000 characters';
              return null;
            },
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
// STEP 2: GAME SETTINGS
class _Step2GameSettings extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tagsCtrl;
  final TextEditingController maxPlayersCtrl;
  final DateTime startTime;
  final DateTime endTime;
  final ValueChanged<DateTime> onStartTimeChanged;
  final ValueChanged<DateTime> onEndTimeChanged;
  final Future<DateTime?> Function(BuildContext, DateTime) pickDateTime;

  const _Step2GameSettings({
    super.key,
    required this.formKey,
    required this.tagsCtrl,
    required this.maxPlayersCtrl,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.pickDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.settings_rounded,
            title: 'Game Settings',
            subtitle: 'Configure tags, player limits, and timing',
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Tags (comma-separated)'),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: tagsCtrl,
            decoration: _inputDec(hint: 'fps, strategy, ranked', icon: Icons.tag_rounded),
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Max Players *'),
          SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: maxPlayersCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDec(hint: '10', icon: Icons.group_outlined),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null) return 'Enter a valid number';
              if (n < 1) return 'Minimum 1 player';
              if (n > 1000) return 'Maximum 1000 players';
              return null;
            },
          ),
          SizedBox(height: AppSpacing.lg),

          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Start Time'),
                SizedBox(height: AppSpacing.sm),
                _DateButton(
                  label: dateFmt.format(startTime),
                  onTap: () async {
                    final dt = await pickDateTime(context, startTime);
                    if (dt != null) onStartTimeChanged(dt);
                  },
                ),
              ],
            )),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('End Time *'),
                SizedBox(height: AppSpacing.sm),
                _DateButton(
                  label: dateFmt.format(endTime),
                  isRequired: true,
                  onTap: () async {
                    final dt = await pickDateTime(context, endTime);
                    if (dt != null) onEndTimeChanged(dt);
                  },
                ),
              ],
            )),
          ]),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
// STEP 3: LOCATION (Offline only)
class _Step3Location extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool fetchingGps;
  final String? error;
  final VoidCallback onFetchGps;
  final VoidCallback onResetGps;

  const _Step3Location({
    super.key,
    required this.formKey,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.fetchingGps,
    this.error,
    required this.onFetchGps,
    required this.onResetGps,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.location_on_rounded,
            title: 'Auto-Location',
            subtitle: 'Offline games use your device GPS for precise match finding',
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Current Location'),
          SizedBox(height: AppSpacing.sm),
          
          if (fetchingGps)
            const _LoadingLocationCard()
          else if (error != null)
            _LocationErrorCard(error: error!, onRetry: onFetchGps)
          else if (latitude != null)
            _GpsActiveCard(lat: latitude!, lng: longitude!, address: address, onReset: onResetGps)
          else
             _GpsSyncButton(loading: false, onTap: onFetchGps),

          const SizedBox(height: 12),
          const Text(
            'Note: Your location is only fetched once and stored with this game to help nearby players find you.',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
          ),

          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
// SHARED WIDGETS
class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDec({String? hint, IconData? icon}) => InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    );

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5),
      );
}
// IMAGE PICKER
class _ImagePicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImagePicker({
    required this.imageBytes,
    required this.imageName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.border,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(imageBytes!, fit: BoxFit.cover),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.black38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text('Tap to change',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                        if (imageName != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              imageName!,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textTertiary),
                SizedBox(height: 8),
                Text('Tap to upload cover image',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('PNG, JPG, WEBP (max 5 MB)',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ]),
      ),
    );
  }
}
// DATE BUTTON
class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isRequired;

  const _DateButton({required this.label, required this.onTap, this.isRequired = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: isRequired ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      );
}
// GPS WIDGETS
class _GpsActiveCard extends StatelessWidget {
  final double lat, lng;
  final String? address;
  final VoidCallback onReset;

  const _GpsActiveCard({required this.lat, required this.lng, this.address, required this.onReset});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(address ?? 'Precise Location Active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successDark, letterSpacing: 0.5)),
              Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          ),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(foregroundColor: AppColors.success, padding: EdgeInsets.zero),
            child: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

class _LoadingLocationCard extends StatelessWidget {
  const _LoadingLocationCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          SizedBox(width: AppSpacing.md),
          const Text('Fetching your GPS coordinates…',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
      );
}

class _LocationErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _LocationErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(error,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Location Detection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
}

class _GpsSyncButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GpsSyncButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.my_location_rounded, size: 16),
        label: Text(loading ? 'Fetching location…' : 'Synchronize Precise Location',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 46),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
}
