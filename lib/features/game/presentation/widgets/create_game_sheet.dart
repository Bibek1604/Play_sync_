import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';

/// Redesigned Create Game Sheet with Professional Green Theme
class CreateGameSheet extends ConsumerStatefulWidget {
  final bool isOnlineMode;

  const CreateGameSheet({super.key, this.isOnlineMode = false});

  @override
  ConsumerState<CreateGameSheet> createState() => _CreateGameSheetState();
}

class _CreateGameSheetState extends ConsumerState<CreateGameSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '10');
  final _prizePoolController = TextEditingController(text: '0');

  GameCategory _selectedCategory = GameCategory.football;
  bool _isOnline = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnlineMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxPlayersController.dispose();
    _prizePoolController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreateGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate with actual game creation provider
      // await ref.read(gameProvider.notifier).createGame(...);

      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text('Game created successfully!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            margin: EdgeInsets.all(AppSpacing.lg),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _isOnline ? Icons.wifi : Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create ${_isOnline ? 'Online' : 'Offline'} Game',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Fill in the details to host a game',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xxl),

                // Game Title
                _buildSectionLabel('Game Title'),
                SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Weekend Football Match',
                    prefixIcon: const Icon(Icons.sports_esports, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a game title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.xl),

                // Description
                _buildSectionLabel('Description'),
                SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add game details, rules, requirements...',
                    prefixIcon: const Icon(Icons.description_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please add a description';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.xl),

                // Category
                _buildSectionLabel('Game Category'),
                SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<GameCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                  items: GameCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryLabel(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),

                SizedBox(height: AppSpacing.xl),

                // Max Players and Prize Pool Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Max Players'),
                          SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _maxPlayersController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '10',
                              prefixIcon: const Icon(Icons.group_outlined, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final num = int.tryParse(value);
                              if (num == null || num < 2) {
                                return 'Min 2';
                              }
                              if (num > 100) {
                                return 'Max 100';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Prize Pool (₹)'),
                          SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _prizePoolController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixIcon: const Icon(Icons.emoji_events_outlined, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xl),

                // Scheduled Date/Time
                _buildSectionLabel('Scheduled Date & Time'),
                SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _selectDateTime,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 20, color: AppColors.textSecondary),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _formatDateTime(_selectedDate),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.xl),

                // Location (for offline games)
                if (!_isOnline) ...[
                  _buildSectionLabel('Location'),
                  SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter venue address or name',
                      prefixIcon: const Icon(Icons.place_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                    ),
                    validator: (value) {
                      if (!_isOnline && (value == null || value.trim().isEmpty)) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.xl),
                ],

                // Online/Offline Toggle
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.location_on,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline ? 'Online Game' : 'Offline Game',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              _isOnline
                                  ? 'Players join remotely'
                                  : 'Players meet at location',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOnline,
                        onChanged: (value) => setState(() => _isOnline = value),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xxxl),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 2,
                      shadowColor: AppColors.primaryWithOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              const Text(
                                'Create Game',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _getCategoryLabel(GameCategory category) {
    switch (category) {
      case GameCategory.football:
        return '⚽ Football';
      case GameCategory.basketball:
        return '🏀 Basketball';
      case GameCategory.cricket:
        return '🏏 Cricket';
      case GameCategory.chess:
        return '♟️ Chess';
      case GameCategory.tennis:
        return '🎾 Tennis';
      case GameCategory.badminton:
        return '🏸 Badminton';
      case GameCategory.other:
        return '🎯 Other';
    }
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, ${date.year} at $hour:$minute';
  }
}
