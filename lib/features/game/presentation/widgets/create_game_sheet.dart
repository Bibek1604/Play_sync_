import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/game_notifier.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/nepal_districts.dart';

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
  // ── Wizard step ───────────────────────────────────────────────────────────
  int _currentStep = 0;
  int get _totalSteps => widget.isOnlineMode ? 2 : 3;

  // ── Form keys per step ────────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _titleCtrl      = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _tagsCtrl       = TextEditingController();
  final _maxPlayersCtrl = TextEditingController(text: '10');

  // ── State ─────────────────────────────────────────────────────────────────
  Uint8List? _imageBytes;
  String?    _imageName;
  DateTime   _startTime = DateTime.now();
  DateTime   _endTime   = DateTime.now().add(const Duration(hours: 1));
  String?    _district;
  double?    _latitude;
  double?    _longitude;
  bool       _fetchingGps = false;
  bool       _submitting  = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  // ── Step Navigation ───────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
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

  // ── Date/time pickers ─────────────────────────────────────────────────────
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

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> _fetchGps() async {
    setState(() => _fetchingGps = true);
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) throw 'Location services are disabled';
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) throw 'Location permission denied';
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() { _latitude = pos.latitude; _longitude = pos.longitude; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
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
      if (_district != null && _district!.isNotEmpty) {
        formData.fields.add(MapEntry('locationName', _district!));
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

    final ok = await ref.read(gameProvider.notifier).createGame(formData);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Game created successfully!'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: EdgeInsets.all(AppSpacing.lg),
      ));
    } else {
      final err = ref.read(gameProvider).error ?? 'Failed to create game';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
              // ── Drag handle ──────────────────────────────────────
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // ── Header with step indicator ───────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(
                      widget.isOnlineMode ? Icons.wifi_rounded : Icons.sports_rounded,
                      color: AppColors.primary, size: 22),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create $mode Session',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                      Text('Step ${_currentStep + 1} of $_totalSteps',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  )),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textTertiary),
                    onPressed: () => Navigator.pop(context)),
                ]),
              ),

              SizedBox(height: AppSpacing.md),

              // ── Step progress bar ────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: _StepProgressBar(
                  totalSteps: _totalSteps,
                  currentStep: _currentStep,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // ── Step content ─────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildStepContent(),
                  ),
                ),
              ),

              // ── Bottom navigation ────────────────────────────────
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
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
          district: _district,
          latitude: _latitude,
          longitude: _longitude,
          fetchingGps: _fetchingGps,
          onDistrictChanged: (d) => setState(() => _district = d),
          onFetchGps: _fetchGps,
          onResetGps: () => setState(() { _latitude = null; _longitude = null; }),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1: BASIC INFO
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2: GAME SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3: LOCATION (Offline only)
// ═══════════════════════════════════════════════════════════════════════════════

class _Step3Location extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? district;
  final double? latitude;
  final double? longitude;
  final bool fetchingGps;
  final ValueChanged<String?> onDistrictChanged;
  final VoidCallback onFetchGps;
  final VoidCallback onResetGps;

  const _Step3Location({
    super.key,
    required this.formKey,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.fetchingGps,
    required this.onDistrictChanged,
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
            title: 'Location',
            subtitle: 'Set where your offline session will take place',
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Region / District *'),
          SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: district,
            hint: const Text('Select a district'),
            isExpanded: true,
            decoration: _inputDec(icon: Icons.location_on_outlined),
            items: nepalDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: onDistrictChanged,
            validator: (v) => (v == null || v.isEmpty) ? 'Select a district' : null,
          ),
          SizedBox(height: AppSpacing.lg),

          _SectionLabel('Precise Location (Optional)'),
          SizedBox(height: AppSpacing.sm),
          latitude != null
              ? _GpsActiveCard(lat: latitude!, lng: longitude!, onReset: onResetGps)
              : _GpsSyncButton(loading: fetchingGps, onTap: onFetchGps),

          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE PICKER
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// DATE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// GPS WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _GpsActiveCard extends StatelessWidget {
  final double lat, lng;
  final VoidCallback onReset;

  const _GpsActiveCard({required this.lat, required this.lng, required this.onReset});

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
              const Text('Precise Location Active',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successDark, letterSpacing: 0.5)),
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
